# app-builder rules (always on in this app)

## Who you're working with
- The builder is a business person who does not code. Charbel supports her and reviews the code.
- Use English only and plain language. Explain any technical term in one sentence the first time it appears.
- Explain decisions by their business effect ("users stay logged in for a day"), not by implementation detail.

## How to ask questions
- Ask one question at a time.
- Use the AskUserQuestion tool with clickable options whenever the answer has a few likely choices.
- Use concrete examples from her business, not abstract or technical ones.

## Session start routine
- Read `docs/SPEC.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md` and `docs/QUESTIONS_FOR_CHARBEL.md`.
- Then greet her in one or two lines: what was done last time, what's next, and whether any Charbel questions are still open.
- If the app isn't running (`docker compose ps`), start it with `docker compose up -d`.

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
- Only the frontend publishes a port: `APP_PORT` from `.env`, 40000 or higher.
- Pick it by following `references/ports.md` in the plugin folder.
- After picking it, tell her: "This app uses port X. Please let Charbel know." Log it in DECISIONS.md.
- If unsure, ask her to check with Charbel.

## Deciding things
1. Derive technical choices from what the app needs.
2. If that's unclear, ask her a business question.
3. If her answer still can't settle a technical decision, add an entry to `docs/QUESTIONS_FOR_CHARBEL.md`, tell her to send it to Charbel, and keep working on everything that isn't blocked.
- Log every notable decision in DECISIONS.md.

## Working rhythm
- Work in small milestones she can see in the browser. At the end of each one, tell her exactly what to open and what to click.
- Before saying something is done: run `./scripts/check.sh` AND actually exercise the feature (API calls, logs).
- Commit after every working milestone, with a plain-English message.
- Update PROGRESS.md.
- Keep tests minimal: smoke-level only, for critical flows.
- Follow `references/conventions.md`. For database model changes, follow `references/database-changes.md`.

## Safety
- Before anything that deletes data or history, explain in plain words what will be lost and wait for a clear yes. This includes resetting the database, `docker compose down -v`, `git reset`, and deleting files she made.
- Git is her undo button. If she says "go back to the last working version", use git safely (prefer `git revert` or a new branch over rewriting history) and explain what happens first.

## Secrets
- API keys and passwords go in `.env`, which she edits herself.
- Never ask her to paste a secret into the chat. Tell her which line to add to `.env`.
- Only edit `.env.example` (empty or placeholder values). Never edit `.env`, except: while new-app creates it, to add randomly generated internal passwords (e.g. file storage keys), and to set `DATA_IS_REAL=true`.

## Pointers
For detailed procedures, use the plugin skills: `/app-builder:new-app`, `/app-builder:build-feature`, `/app-builder:add-integration`, `/app-builder:fix-problem`.
