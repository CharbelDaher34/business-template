# AI features with PydanticAI

Add PydanticAI only when the app needs an AI feature (summarize, classify,
extract information from text, draft a reply, answer questions about data).
Explain the feature, its cost per use and what she must set up first, per
`integrations.md`.

## Which model and provider

Which model and provider to use (and who pays for the API key) is a
**Charbel question** unless DECISIONS.md already records it. Write the
question with options (e.g. a fast, cheap model vs a stronger, pricier one),
your recommendation, and keep building everything else meanwhile.

## Setup

- `docker compose exec backend uv add --no-sync pydantic-ai-slim[<provider>]`
  (e.g. `[anthropic]`), then `docker compose up -d --build`. Log the version
  in DECISIONS.md.
- Settings in `backend/app/core/config.py`, values in `.env` (she adds the key):
  ```
  # AI (model chosen with Charbel, see DECISIONS.md)
  AI_MODEL=
  ANTHROPIC_API_KEY=
  ```
  Add the same names with empty values to `.env.example`.

## Where the code goes

`backend/app/services/ai/`, one module per agent, with the prompt in code next
to the agent and a typed output:

```python
# backend/app/services/ai/visit_summary.py
from pydantic import BaseModel
from pydantic_ai import Agent

from app.core.config import settings


class VisitSummary(BaseModel):
    headline: str
    follow_ups: list[str]


INSTRUCTIONS = """\
You summarize field visit notes for a sales manager.
Write a one-line headline and list concrete follow-up actions.
"""

agent = Agent(settings.AI_MODEL, output_type=VisitSummary, instructions=INSTRUCTIONS)


async def summarize_visit(notes: str) -> VisitSummary:
    result = await agent.run(notes)
    return result.output
```

- Routes call these functions like any other service. Business rules (who can
  run it, what data goes in) stay in the regular services.
- Send the model only the data it needs. Never send passwords, keys or data
  she hasn't agreed to share with the provider.
- Handle failures (no key, provider down, timeout) with a clear message in the
  UI. Don't let them break the page.
- Tests: don't call the real model. Use PydanticAI's `TestModel` /
  `agent.override(...)` in a smoke test if the feature is critical.

## Wrap up

- Add `"pydantic-ai"` to `services` in `.app-builder.json` and the services line in `CLAUDE.md`.
- Check the current PydanticAI docs (https://ai.pydantic.dev) for API changes
  before writing the code.
