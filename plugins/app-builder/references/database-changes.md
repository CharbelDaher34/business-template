# Database changes

When a model in `backend/app/models/` changes, update the database right away:
the backend reloads at once and errors until the database matches the models.

## Test data (`data_is_real` is `false` in `.app-builder.json`)

This is the normal case while she's trying an idea out. If DECISIONS.md
doesn't record yet that the app holds test data, ask her once ("Is the data in
the app right now real data you'd be upset to lose?") and log the answer.

1. Change the model(s) and update `backend/app/seed.py` to match.
2. Generate a migration:
   `docker compose exec backend alembic revision --autogenerate -m "<what changed>"`
3. Apply it, keeping her test data: `docker compose exec backend alembic upgrade head`.
   If it fails, nothing changed (migrations are all-or-nothing).
4. If it failed because existing rows don't fit (typically a new required
   column: "contains null values"), get her OK in one line ("This change needs
   a fresh database: the test data is replaced with the demo data. OK?"), then
   `./scripts/reset-db.sh --yes`. It only touches this app's database.

## Real data (`data_is_real` is `true`)

**Becoming real** (she says the app is now used for real): set
`"data_is_real": true` in `.app-builder.json` and `DATA_IS_REAL=true` in `.env`,
remove demo seed rows from `seed.py` (e.g. `seed_demo_items` and its call, or
they come back on every start), and log it in DECISIONS.md. This is permanent:
`reset-db.sh` refuses to run from then on.

**Every change** must keep all rows:
1. Change the model(s), then autogenerate the migration as above.
2. Review the file before applying it:
   - A new required column needs a value for existing rows: add
     `server_default=...` to its `sa.Column(...)`; autogenerate never does.
   - Autogenerate can't see renames (it drops and re-adds the column, losing
     data): write `op.alter_column(..., new_column_name=...)` instead.
3. Apply with `alembic upgrade head`; if it fails, fix the file and apply again.
4. Count rows before and after to confirm nothing was lost.

Never reset, run `docker compose down -v`, or delete applied migrations once
the data is real.

## Always

Seed functions only insert missing rows. Commit the model, migration and seed
changes together.
