# Natural Language to SQL API

A FastAPI service that uses Claude (Anthropic) to convert plain English questions into PostgreSQL SELECT queries and execute them against a connected database.

## Architecture

- **Runtime**: Python 3.12
- **Framework**: FastAPI with Uvicorn
- **AI**: Anthropic Claude (`claude-sonnet-4-6`) for natural language → SQL
- **Database**: PostgreSQL via `psycopg2`

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Redirects to interactive API docs |
| GET | `/health` | Health check, returns model name |
| POST | `/ask` | Ask a question; returns SQL query + results |

### POST /ask

Request body:
```json
{
  "question": "How many users signed up last month?",
  "history": []
}
```

Response:
```json
{
  "query": "SELECT COUNT(*) FROM users WHERE ...",
  "result": [[42]],
  "history": [...]
}
```

Multi-turn conversation is supported via the `history` field.

## Safety

- Only `SELECT` and `WITH ... SELECT` (CTE) queries are allowed
- Disallowed keywords (INSERT, UPDATE, DELETE, DROP, etc.) are blocked by regex
- Claude is instructed to return `CANNOT_ANSWER` or `CLARIFY:` sentinels when appropriate

## Environment Variables / Secrets

| Key | Description |
|-----|-------------|
| `ANTHROPIC_API_KEY` | Anthropic API key for Claude |
| `DATABASE_URL` | PostgreSQL connection string |

## Running

The app is managed by the "Start application" workflow:
```
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```
