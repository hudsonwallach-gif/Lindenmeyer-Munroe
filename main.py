import os
import re
from pathlib import Path
from typing import Optional

import psycopg2
from anthropic import Anthropic
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

load_dotenv()

app = FastAPI(title="Natural Language to SQL API")
app.mount("/static", StaticFiles(directory="static"), name="static")
client = Anthropic()  # reads ANTHROPIC_API_KEY from env automatically

DATABASE_URL = os.environ["DATABASE_URL"]  # fail fast at startup if missing
MODEL = "claude-sonnet-4-6"

_DISALLOWED_PATTERN = re.compile(
    r"\b(INSERT|UPDATE|DELETE|DROP|TRUNCATE|ALTER|CREATE|REPLACE|UPSERT|MERGE|GRANT|REVOKE|EXECUTE|CALL|COPY|VACUUM|ANALYZE)\b",
    re.IGNORECASE,
)


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
    history: list[MessageEntry]


# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------


def get_connection():
    return psycopg2.connect(DATABASE_URL)


def get_schema() -> str:
    """Introspect all user tables and their columns from the public schema."""
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
        conn.close()

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

    return "\n".join(schema_lines)


def run_select_query(sql: str) -> tuple:
    """Execute a validated SELECT query and return (columns, rows)."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(sql)
        columns = [desc[0] for desc in cur.description] if cur.description else []
        result = cur.fetchall()
        cur.close()
        return columns, [list(row) for row in result]
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Safety guard
# ---------------------------------------------------------------------------


def validate_select_only(sql: str) -> None:
    """Raise ValueError if the SQL is not a SELECT/WITH statement."""
    stripped = sql.strip().lstrip(";").upper()
    if not (stripped.startswith("SELECT") or stripped.startswith("WITH")):
        raise ValueError(f"Only SELECT queries are allowed. Got: {sql[:80]!r}")
    if _DISALLOWED_PATTERN.search(sql):
        raise ValueError("Query contains disallowed SQL keywords (INSERT/UPDATE/DELETE/etc.)")


# ---------------------------------------------------------------------------
# Prompt
# ---------------------------------------------------------------------------


def build_system_prompt(schema: str) -> str:
    return f"""You are the LM Intelligent Agent, an enterprise AI assistant embedded in the Lindenmeyr Munroe ERP system. You help employees across sales, operations, and warehouse teams manage paper distribution, packaging logistics, wide-format supplies, and facility solutions with speed and precision.

You have deep knowledge of the paper and packaging distribution industry. You communicate in a professional, efficient tone — direct answers first, context second. Never be verbose. Never hallucinate data.

Your primary capability is converting natural language questions into PostgreSQL SELECT queries against the live database, then returning the results.

Database schema:
{schema}

Rules:
1. Return ONLY valid PostgreSQL SQL — no explanation, no markdown, no code fences.
2. Only write SELECT queries (or WITH ... SELECT for CTEs). Never write INSERT, UPDATE, DELETE, DROP, or any data-modifying statement.
3. Use the exact table and column names from the schema above.
4. If the question cannot be answered with a SELECT query against the given schema, respond with exactly: CANNOT_ANSWER
5. If you need clarification before writing a query, respond with: CLARIFY: <your question>
6. Never open responses with filler phrases. Lead with the SQL query directly.
"""


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------


@app.get("/")
def root():
    html = Path("static/index.html").read_text()
    return HTMLResponse(content=html)


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

    # 3. Call Claude
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
            detail={"error": "Cannot answer this question with the available schema", "history": [h.model_dump() for h in updated_history]},
        )
    if sql_query.startswith("CLARIFY:"):
        raise HTTPException(
            status_code=422,
            detail={"error": sql_query, "history": [h.model_dump() for h in updated_history]},
        )

    # 6. Validate SELECT-only
    try:
        validate_select_only(sql_query)
    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail={"error": str(e), "query": sql_query, "history": [h.model_dump() for h in updated_history]},
        )

    # 7. Execute
    try:
        columns, result = run_select_query(sql_query)
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail={"error": str(e), "query": sql_query, "history": [h.model_dump() for h in updated_history]},
        )

    return AskResponse(query=sql_query, columns=columns, result=result, history=updated_history)
