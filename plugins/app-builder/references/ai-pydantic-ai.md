# AI features with PydanticAI

Add PydanticAI only when the app needs an AI feature (summarize, classify,
extract information from text, draft a reply, answer questions about data).
Explain the feature, its cost per use and what she must set up first, per
`integrations.md`.

## Start from the use case

An AI feature is only as good as what it's given, so work out with her what
it's for before designing it. Walk through real scenarios together: what
people will ask it or use it for, what a good answer or action looks like,
what it must never do, and what should happen when it can't help. From that,
derive:

- **Context**: what information it needs to do the job (which records, how
  much history, which business rules), and nothing more.
- **Tools**: what it needs to look up or do in the app.
- **Constraints**: who can use it, what it may change, limits on cost and
  length, tone and language.
- **Output**: the shape of the result (a typed model, not free text, whenever
  the app uses the result).

Record the use case and these decisions in SPEC.md and DECISIONS.md.

## Which model and provider

Which model and provider to use (and who pays for the API key) is a
**Charbel question** unless DECISIONS.md already records it. Write the
question with options (e.g. a fast, cheap model vs a stronger, pricier one),
your recommendation, and keep building everything else meanwhile.

## Setup

- `docker compose exec backend uv add --no-sync pydantic-ai-slim[<provider>]`
  (e.g. `[anthropic]`), then `docker compose up -d --build`. Log the version
  in DECISIONS.md.
- Settings in `backend/app/core/config.py`, values in `.env` (you set
  `AI_MODEL`; she saves the key with `set-secret.sh`):
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

## Agents with tools

When the AI looks things up or takes actions in the app (a chatbot, an
assistant), not just transforms text:

- **Tools call the existing services**, so the business rules apply exactly
  as they do for the pages. No tool talks to the database directly.
- **The agent acts as the logged-in user**: pass the user in the run's
  dependencies, and let the services' permission checks decide. Never rely on
  the prompt to keep it from doing something; enforce it in code.
- **Typed tool parameters with clear descriptions** (the docstring). Fields
  with a fixed set of values are an enum (`Literal[...]` or an `Enum`), so the
  model can't invent a value. Return only what the model needs.
- **Confirm consequential actions**: anything that sends, pays, deletes or is
  hard to undo is proposed by the agent and confirmed by the person using the
  app before it happens (PydanticAI's tools that require approval). Lookups
  and easily undone changes don't need it.
- **Cap each run** with usage limits (requests, tool calls, tokens), so a loop
  can't run up the bill.
- **Log each run**: who ran it, the model, the tools called and their
  outcome, tokens used, and errors. Not the full conversation if it holds
  personal details.
- **Treat what it reads as untrusted.** A message, email or document can
  contain instructions; it must not be able to make the agent do more than
  the user is allowed to (another reason permissions live in the services).

## Wrap up

- Add `"pydantic-ai"` to `services` in `.app-builder.json` and the services line in `CLAUDE.md`.
- Check the current PydanticAI docs (https://ai.pydantic.dev) for API changes
  before writing the code.
