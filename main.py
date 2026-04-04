import os
import re
import time
from contextlib import asynccontextmanager
from pathlib import Path

import psycopg2
import psycopg2.pool
from anthropic import Anthropic
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

load_dotenv()

BASE_DIR = Path(__file__).parent.resolve()
STATIC_DIR = BASE_DIR / "static"

DATABASE_URL = os.environ.get("DATABASE_URL", "")
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL environment variable is not set. Add it to your .env file.")
MODEL = "claude-opus-4-6"

_DISALLOWED_PATTERN = re.compile(
    r"\b(INSERT|UPDATE|DELETE|DROP|TRUNCATE|ALTER|CREATE|REPLACE|UPSERT|MERGE|GRANT|REVOKE|EXECUTE|CALL|COPY|VACUUM|ANALYZE)\b",
    re.IGNORECASE,
)

# ---------------------------------------------------------------------------
# Connection pool + schema cache
# ---------------------------------------------------------------------------

_pool: psycopg2.pool.ThreadedConnectionPool | None = None
_schema_cache: dict = {"schema": None, "ts": 0.0}
_SCHEMA_TTL = 60.0  # seconds


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _pool
    _pool = psycopg2.pool.ThreadedConnectionPool(minconn=1, maxconn=10, dsn=DATABASE_URL)
    yield
    _pool.closeall()


app = FastAPI(title="Lindenmeyer Munroe AI Agent", lifespan=lifespan)
client = Anthropic()


# ---------------------------------------------------------------------------
# Pydantic models
# ---------------------------------------------------------------------------


class MessageEntry(BaseModel):
    role: str
    content: str


class AskRequest(BaseModel):
    question: str
    history: list[MessageEntry] = []


class AskResponse(BaseModel):
    query: str
    columns: list[str]
    result: list
    summary: str
    history: list[MessageEntry]


# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------


def get_connection():
    if _pool:
        return _pool.getconn()
    return psycopg2.connect(DATABASE_URL)


def release_connection(conn):
    if _pool:
        _pool.putconn(conn)
    else:
        conn.close()


def get_schema() -> str:
    """Introspect all user tables and their columns; cached for 60 s."""
    now = time.monotonic()
    if _schema_cache["schema"] and now - _schema_cache["ts"] < _SCHEMA_TTL:
        return _schema_cache["schema"]

    query = """
        SELECT
            table_name,
            column_name,
            data_type,
            is_nullable,
            column_default
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name NOT LIKE 'pg_%'
        ORDER BY table_name, ordinal_position
    """
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(query)
        rows = cur.fetchall()
        cur.close()
    finally:
        release_connection(conn)

    if not rows:
        return "No tables found in the public schema."

    schema_lines = []
    current_table = None
    for table_name, col_name, data_type, is_nullable, col_default in rows:
        if table_name != current_table:
            if current_table is not None:
                schema_lines.append("")
            schema_lines.append(f"Table: {table_name}")
            current_table = table_name
        nullable = "" if is_nullable == "YES" else " NOT NULL"
        default = f" DEFAULT {col_default}" if col_default else ""
        schema_lines.append(f"  - {col_name}: {data_type}{nullable}{default}")

    result = "\n".join(schema_lines)
    _schema_cache["schema"] = result
    _schema_cache["ts"] = now
    return result


def run_select_query(sql: str) -> tuple[list[str], list]:
    """Execute a validated SELECT query; returns (column_names, rows)."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(sql)
        columns = [desc[0] for desc in cur.description]
        rows = [list(row) for row in cur.fetchall()]
        cur.close()
        return columns, rows
    finally:
        release_connection(conn)


# ---------------------------------------------------------------------------
# Safety guard
# ---------------------------------------------------------------------------


def validate_select_only(sql: str) -> None:
    """Raise ValueError if the SQL is not a SELECT/WITH statement."""
    stripped = sql.strip().lstrip(";").strip().upper()
    if not (stripped.startswith("SELECT") or stripped.startswith("WITH")):
        raise ValueError(f"Only SELECT queries are allowed. Got: {sql[:80]!r}")
    if _DISALLOWED_PATTERN.search(sql):
        raise ValueError("Query contains disallowed SQL keywords (INSERT/UPDATE/DELETE/etc.)")


# ---------------------------------------------------------------------------
# Prompts
# ---------------------------------------------------------------------------


def build_system_prompt(schema: str) -> str:
    return f"""You are a data assistant for Lindenmeyer Munroe, a paper distribution company \
(a division of Central National-Gottesman). You convert natural language questions into \
PostgreSQL SELECT queries against their distribution management database.

Database schema:
{schema}

Domain knowledge:
- "basis weight" or "weight" refers to the weight_lb column (e.g., "20lb bond", "80lb text")
- "letter size" or "8.5x11" means size_width=8.5 AND size_height=11
- "legal size" means size_width=8.5 AND size_height=14
- "ledger" or "tabloid" or "11x17" means size_width=11 AND size_height=17
- "12x18" means size_width=12 AND size_height=18
- "13x19" means size_width=13 AND size_height=19
- "coated paper" includes finish values: 'gloss', 'matte', 'silk'
- "uncoated" means finish='uncoated'
- "in stock" means quantity_cartons > 0 in the inventory table
- For inventory queries, always JOIN warehouses to show warehouse name
- For pricing queries, use the pricing table joined to products
- price_tier values: 'list', 'distributor', 'preferred'
- order status values: 'pending', 'processing', 'shipped', 'delivered', 'cancelled'

Rules:
1. Return ONLY valid PostgreSQL SQL — no explanation, no markdown, no code fences.
2. Only write SELECT queries (or WITH ... SELECT for CTEs). Never write INSERT, UPDATE, DELETE, DROP, or any data-modifying statement.
3. Use the exact table and column names from the schema above.
4. If the question cannot be answered with a SELECT query against the given schema, respond with exactly: CANNOT_ANSWER
5. If you need clarification before writing a query, respond with: CLARIFY: <your question>
6. Always include human-readable columns (name, not just id) in results.
7. Limit results to 100 rows unless the user asks for more.
"""


def generate_summary(question: str, columns: list[str], rows: list) -> str:
    """Ask Claude to summarize query results in plain English."""
    if not rows:
        preview = "(no results)"
    else:
        header = ", ".join(columns)
        data_lines = "\n".join(str(r) for r in rows[:20])
        preview = f"Columns: {header}\n{data_lines}"
        if len(rows) > 20:
            preview += f"\n... and {len(rows) - 20} more rows"

    response = client.messages.create(
        model=MODEL,
        max_tokens=512,
        messages=[{
            "role": "user",
            "content": (
                f"Question: {question}\n\n"
                f"Query results ({len(rows)} rows):\n{preview}\n\n"
                "Write a concise, helpful plain English answer in 1–3 sentences. "
                "Use specific numbers from the results. "
                "If there are no results, say so clearly."
            ),
        }],
    )
    return response.content[0].text.strip()


# ---------------------------------------------------------------------------
# Routes — defined before static mount so they take priority
# ---------------------------------------------------------------------------


@app.get("/health")
def health():
    return {"status": "ok", "model": MODEL}


@app.post("/ask", response_model=AskResponse)
def ask(body: AskRequest):
    # 1. Introspect schema
    try:
        schema = get_schema()
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Cannot connect to database: {e}")

    system_prompt = build_system_prompt(schema)

    # 2. Build messages: history + new question
    messages = [{"role": entry.role, "content": entry.content} for entry in body.history]
    messages.append({"role": "user", "content": body.question})

    # 3. Call Claude to generate SQL
    try:
        response = client.messages.create(
            model=MODEL,
            max_tokens=1024,
            system=system_prompt,
            messages=messages,
        )
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Claude API error: {e}")

    sql_query = response.content[0].text.strip()

    # 4. Build updated history
    updated_history = list(body.history) + [
        MessageEntry(role="user", content=body.question),
        MessageEntry(role="assistant", content=sql_query),
    ]

    # 5. Handle Claude sentinel responses
    if sql_query == "CANNOT_ANSWER":
        raise HTTPException(
            status_code=422,
            detail={"error": "I can't answer that question with the available data.", "history": [h.model_dump() for h in updated_history]},
        )
    if sql_query.startswith("CLARIFY:"):
        raise HTTPException(
            status_code=422,
            detail={"error": sql_query[len("CLARIFY:"):].strip(), "history": [h.model_dump() for h in updated_history]},
        )

    # 6. Validate SELECT-only
    try:
        validate_select_only(sql_query)
    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail={"error": str(e), "query": sql_query, "history": [h.model_dump() for h in updated_history]},
        )

    # 7. Execute query
    try:
        columns, result = run_select_query(sql_query)
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail={"error": str(e), "query": sql_query, "history": [h.model_dump() for h in updated_history]},
        )

    # 8. Generate plain English summary
    try:
        summary = generate_summary(body.question, columns, result)
    except Exception:
        summary = f"Found {len(result)} result(s)."

    return AskResponse(
        query=sql_query,
        columns=columns,
        result=result,
        summary=summary,
        history=updated_history,
    )


@app.get("/")
def serve_frontend():
    return FileResponse(STATIC_DIR / "index.html")


# Static files mounted last so API routes take priority
if STATIC_DIR.exists():
    app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")
