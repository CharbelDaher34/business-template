# Adding an outside service (integration)

Examples: payments, sending emails or SMS, maps, AI, file storage, importing
data from another system, calendars.

## Before writing any code, explain it to her

In plain words, cover:

1. **What it does** and **why the app needs it** ("To send the weekly summary by
   email, the app needs an email-sending service.").
2. **Simpler or free alternatives**, including not integrating at all
   ("We could show a 'Download summary' button instead, which needs nothing extra.").
3. **Cost**: free tier limits, monthly price, per-use price. Look up current
   prices; don't guess.
4. **Exactly what she must do**: create an account, verify a domain, get an API
   key, and where to click.
5. **Secrets**: she puts the keys in `.env` herself. Tell her the exact line,
   e.g. `PAYMENT_API_KEY=`. Never ask her to paste a key into the chat.

Agree on the purpose and the choice before writing code.

## Charbel questions

Write a `docs/QUESTIONS_FOR_CHARBEL.md` entry, and don't build it until he
answers, when the integration:
- costs money (any paid plan, or pay-per-use beyond a free tier), or
- has lock-in (hard to move away from, owns the data, proprietary format), or
- adds a new service, framework or SDK outside the fixed stack.

Keep working on everything that isn't blocked meanwhile.

## How to build it

- Wrap each integration in its own service module, e.g.
  `backend/app/services/email_service.py`, with small functions named after what
  the app needs (`send_weekly_summary(...)`), so the provider can be swapped
  without touching the rest of the app.
- Read settings from `.env` through `app/core/config.py` (`Settings`). Add the
  variable names (without values) to `.env.example`, with a comment.
- After she adds keys to `.env`, restart: `docker compose up -d` (the backend
  reads `.env` on start).
- Handle the service being down or the key missing: show a clear message,
  don't crash the page.
- Add a Python package with uv inside the backend container, then rebuild:
  `docker compose exec backend uv add --no-sync <package>` and
  `docker compose up -d --build`. A frontend package:
  `docker compose exec frontend bun add <package>`. Log it in DECISIONS.md.
- Update `services` in `.app-builder.json` and the services line in `CLAUDE.md`,
  and log the choice, version and cost in DECISIONS.md.

Specific guides: file uploads → `file-storage-rustfs.md`; AI features →
`ai-pydantic-ai.md`.
