# {{APP_NAME}}

{{ONE_LINE_DESCRIPTION}}

The shared working rules (how to work with the builder, the fixed stack, shared-server
safety) come from the `app-builder` plugin and load at the start of every session.
This file only holds what is specific to this app.

## This app

- Port: `{{APP_PORT}}`. The only published port. Opened as http://localhost:{{APP_PORT}} through port forwarding.
- Compose project: `{{COMPOSE_PROJECT_NAME}}`
- Optional services enabled: {{SERVICES}}
- Is the data real? See `data_is_real` in `.app-builder.json` (and `DATA_IS_REAL` in `.env`).

## Run, stop, check

- Start: `docker compose up -d` (add `--build` after changing backend dependencies)
- Stop: `docker compose stop`
- Status: `docker compose ps`
- Logs: `docker compose logs -f backend` (or `frontend`, `prestart`, `db`)
- Before saying anything is done: `./scripts/check.sh`
- After changing API routes or schemas: `./scripts/generate-client.sh`
- Save a secret in `.env` (she runs it herself, in her own terminal): `./scripts/set-secret.sh NAME`
- API docs: http://localhost:{{APP_PORT}}/api/docs

## Where things are

- `backend/app/`: `models/` → `services/` → `api/routes/`. The "items" feature is the reference pattern.
  Seed data in `seed.py`, migrations in `alembic/versions/`, smoke tests in `tests/`.
- `frontend/src/`: `routes/` (pages), `components/`, `client/` (generated, never edit by hand).
- `docs/SPEC.md`: what the app does. `docs/PROGRESS.md`: done, in progress, next, milestones.
- `docs/DECISIONS.md`: dated decision log. `docs/QUESTIONS_FOR_CHARBEL.md`: open technical questions.
- `docs/HOW_IT_WORKS.md`: map of how the app works, for the builder (features, glossary, how she likes to learn).
