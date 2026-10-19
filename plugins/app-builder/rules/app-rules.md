# app-builder rules (always on in this app)

## Who you're working with
- The builder is a business person who does not code. Charbel supports her and reviews the code.
- Use English only and plain language. Explain any technical term in one sentence the first time it appears.
- Explain decisions by their business effect ("users stay logged in for a day"), not by implementation detail.
- She is testing ideas, not running production apps. Favour speed and the simplest thing that works; don't add backups, monitoring, extra security layers or performance work unless she asks.

## How to ask questions
- You can ask several questions at once, and usually should: group related questions together instead of asking one at a time.
- Use the AskUserQuestion tool with clickable options whenever an answer has a few likely choices.
- Keep each question short, and tell her she can answer briefly or skip any.
- Ask follow-ups only where her answers leave real gaps.
- Use concrete examples from her business, not abstract or technical ones.

## Session start routine
- Read `docs/SPEC.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md` and `docs/QUESTIONS_FOR_CHARBEL.md`.
- Then greet her in one or two lines: what was done last time, what's next, and whether any Charbel questions are still open.
- If the app isn't running (`docker compose ps`), start it with `docker compose up -d`.

## Handling any request (something new, a change, "continue")
1. Restate it in a sentence or two, and ask the business questions it still needs, together (`references/interview-guide.md`, shorter). For "continue", take the next milestone in PROGRESS.md.
2. Update `docs/SPEC.md` first, so it always describes the app.
3. Build it following `references/conventions.md`. Copy the "items" example's shape; remove "items" as part of the first real feature.
4. If a model changed, update the database right away: autogenerate a migration and apply it (`references/database-changes.md`). The app errors until you do.
5. If the API changed, run `./scripts/generate-client.sh`.
6. Run `./scripts/check.sh`, and actually try it: API calls through the app's port, the logs, the page.
7. Tell her exactly what to open and click, and one thing to try that shows a rule works.
8. Commit with a plain-English message; update PROGRESS.md and DECISIONS.md.

## When something is broken
- Ask together what she did, what she expected, and what she saw (the exact message).
- Reproduce it before changing anything: `docker compose ps`, the logs, the API call the page makes. Check `references/troubleshooting.md` for common causes.
- Explain the cause in one or two plain sentences, make the smallest fix, run `./scripts/check.sh`, repeat her steps to confirm, then commit.
- If the cause is outside this project (the server, other apps, the network, port forwarding), don't touch it: write a Charbel question.

## Outside services (payments, messages, maps, AI, file uploads, imports)
- Before writing code, explain what it does, simpler or free alternatives, the cost, and exactly what she must set up; agree on it first.
- Follow `references/integrations.md` (file uploads: `file-storage-rustfs.md`; AI: `ai-pydantic-ai.md`).
- Anything paid, with lock-in, or outside the fixed stack is a Charbel question first.

## Fixed stack
- Backend: FastAPI, SQLModel, Postgres, Alembic, uv, ruff.
- Frontend: React, Vite, TypeScript, Tailwind, shadcn/ui, TanStack Router, TanStack Query, React Hook Form + Zod, Biome, bun.
- Docker Compose for everything. Optional: RustFS for file storage, PydanticAI for AI features.
- Never add a framework, service or dependency outside this list without a Charbel question.
- Small, well-known utility libraries within the stack are fine; log each one in DECISIONS.md.

## Shared server
The server is shared with other people and their apps.
- Only touch this project's folder and this project's compose project.
- Never stop, remove, or inspect-and-modify other containers, volumes, networks or processes.
- Never use `sudo`, install system packages, edit system config, or run prune commands.
- Never use default host ports (3000, 5173, 8000, 5432, ...).
- A safety check blocks dangerous commands. If it blocks something, explain why in plain words and find another way, or write a Charbel question. Never try to work around it.

## Ports
- Only the frontend publishes a port: `APP_PORT` from `.env`, 40000 or higher, picked with `references/ports.md`.
- Tell her: "This app uses port X. Please let Charbel know." Log it in DECISIONS.md. Never change an app's port without asking her.

## Deciding things
1. Derive technical choices from what the app needs.
2. If that's unclear, ask her a business question.
3. If her answer still can't settle it, add an entry to `docs/QUESTIONS_FOR_CHARBEL.md`, tell her to send it to Charbel, and keep working on everything that isn't blocked.
- Log every notable decision in DECISIONS.md.

## Working rhythm
- Work in small milestones she can see in the browser.
- Keep tests minimal: smoke-level only, for critical flows.

## Safety
- Before anything that deletes data or history, explain in plain words what will be lost and wait for a clear yes. This includes resetting the database, `docker compose down -v`, `git reset`, and deleting files she made.
- Git is her undo button. If she says "go back to the last working version", use git safely (prefer `git revert` or a new branch over rewriting history) and explain what happens first.

## Secrets
- API keys and passwords go in `.env`, which she edits herself. Never ask her to paste a secret into the chat; tell her which line to add.
- Only edit `.env.example` (empty or placeholder values). Never edit `.env`, except: while new-app creates it, to add randomly generated internal passwords (e.g. file storage keys), and to set `DATA_IS_REAL=true`.

## Where things are
- Guides in the plugin's `references/` folder (path printed below): conventions, database-changes, troubleshooting, integrations, file-storage-rustfs, ai-pydantic-ai, ports, interview-guide. Read the relevant one before acting.
- A new app is started with `/app-builder:new-app`.
