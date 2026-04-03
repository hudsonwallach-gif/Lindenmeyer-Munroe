import os
import re

import psycopg2
from anthropic import Anthropic
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

load_dotenv()

app = FastAPI(title="Lindenmeyr AI Assistant")
client = Anthropic()


@app.get("/")
def root():
    return FileResponse("static/index.html")


app.mount("/static", StaticFiles(directory="static"), name="static")
DATABASE_URL = os.environ["DATABASE_URL"]
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
    answer: str
    sql: str
    history: list[MessageEntry]


# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------


def get_connection():
    return psycopg2.connect(DATABASE_URL)


def get_schema() -> str:
    query = """
        SELECT table_name, column_name, data_type, is_nullable, column_default
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


def get_column_names(sql: str) -> list[str]:
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(sql)
        return [desc[0] for desc in cur.description]
    finally:
        conn.close()


def run_select_query(sql: str) -> list:
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(sql)
        return [list(row) for row in cur.fetchall()]
    finally:
        conn.close()


# ---------------------------------------------------------------------------
# Safety guard
# ---------------------------------------------------------------------------


def validate_select_only(sql: str) -> None:
    stripped = sql.strip().lstrip(";").upper()
    if not (stripped.startswith("SELECT") or stripped.startswith("WITH")):
        raise ValueError(f"Only SELECT queries are allowed. Got: {sql[:80]!r}")
    if _DISALLOWED_PATTERN.search(sql):
        raise ValueError("Query contains disallowed SQL keywords.")


# ---------------------------------------------------------------------------
# Prompts
# ---------------------------------------------------------------------------


def build_sql_prompt(schema: str) -> str:
    return f"""You are a PostgreSQL query assistant. Convert natural language questions into SQL SELECT queries.

Database schema:
{schema}

Rules:
1. Return ONLY valid PostgreSQL SQL — no explanation, no markdown, no code fences.
2. Only write SELECT queries (or WITH ... SELECT for CTEs).
3. Use the exact table and column names from the schema above.
4. If the question cannot be answered from the schema, respond with exactly: CANNOT_ANSWER
5. If you need clarification, respond with: CLARIFY: <your question>
"""


def build_answer_prompt(question: str, columns: list[str], rows: list) -> str:
    if not rows:
        data_text = "The query returned no results."
    else:
        header = " | ".join(columns)
        lines = [header, "-" * len(header)]
        for row in rows[:50]:
            lines.append(" | ".join(str(v) if v is not None else "—" for v in row))
        data_text = "\n".join(lines)
        if len(rows) > 50:
            data_text += f"\n... and {len(rows) - 50} more rows."

    return f"""You are a helpful internal assistant for a paper and packaging distribution company.

A user asked: "{question}"

You ran a database query and got these results:
{data_text}

Now answer the user's question in clear, friendly, conversational English.
- Be concise and specific — mention actual names, numbers, and figures from the data
- If there are no results, say so naturally
- Do not mention SQL, databases, or technical details
- Sound like a knowledgeable colleague, not a robot
- Use bullet points or short lists when showing multiple items
"""


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------


@app.get("/health")
def health():
    return {"status": "ok", "model": MODEL}


@app.post("/ask", response_model=AskResponse)
def ask(body: AskRequest):
    # 1. Get schema
    try:
        schema = get_schema()
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Cannot connect to database: {e}")

    # 2. Build messages for SQL generation
    messages = [{"role": entry.role, "content": entry.content} for entry in body.history]
    messages.append({"role": "user", "content": body.question})

    # 3. Ask Claude for SQL
    try:
        sql_response = client.messages.create(
            model=MODEL,
            max_tokens=1024,
            system=build_sql_prompt(schema),
            messages=messages,
        )
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Claude API error: {e}")

    sql_query = sql_response.content[0].text.strip()
    # Strip accidental markdown code fences
    sql_query = re.sub(r"^```(?:sql)?\s*", "", sql_query, flags=re.IGNORECASE)
    sql_query = re.sub(r"\s*```$", "", sql_query).strip()

    # 4. Handle sentinels
    if sql_query == "CANNOT_ANSWER":
        raise HTTPException(status_code=422, detail={"error": "I don't have the data needed to answer that question."})
    if sql_query.startswith("CLARIFY:"):
        raise HTTPException(status_code=422, detail={"error": sql_query[8:].strip()})

    # 5. Validate SELECT-only
    try:
        validate_select_only(sql_query)
    except ValueError as e:
        raise HTTPException(status_code=400, detail={"error": str(e)})

    # 6. Run query
    try:
        columns = get_column_names(sql_query)
        rows = run_select_query(sql_query)
    except Exception as e:
        raise HTTPException(status_code=400, detail={"error": str(e)})

    # 7. Ask Claude to answer in plain English
    try:
        answer_response = client.messages.create(
            model=MODEL,
            max_tokens=1024,
            messages=[{"role": "user", "content": build_answer_prompt(body.question, columns, rows)}],
        )
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Claude API error: {e}")

    answer = answer_response.content[0].text.strip()

    # 8. Update history with natural language answer (not raw SQL)
    updated_history = list(body.history) + [
        MessageEntry(role="user", content=body.question),
        MessageEntry(role="assistant", content=answer),
    ]

    return AskResponse(answer=answer, sql=sql_query, history=updated_history)
