# Database changes: reset or migrate?

Whenever a model in `backend/app/models/` changes (new table, new or renamed
column, changed type), decide how the database follows.

## 1. Check whether the data is real

Read `data_is_real` in `.app-builder.json`.

- `true` → go to **Real data** below. Never reset.
- `false` → ask her, in business terms:
  "Is the data in the app right now real data you'd be upset to lose?"
  (Use AskUserQuestion: "No, it's test data" / "Yes, keep it".)

## 2. Test data (her answer: No)

The database can be rebuilt from scratch, so keep the migration history simple.

1. Change the model(s).
2. Update the migration history. While nothing is real, it's fine to keep one
   tidy migration per table group: either edit the latest migration or
   regenerate it:
   `docker compose exec backend alembic revision --autogenerate -m "<what changed>"`.
   Review the generated file in `backend/app/alembic/versions/` before using it.
3. Update `backend/app/seed.py` so the seed data matches the new models.
4. Explain what will happen ("All the test data in the app is deleted and the
   demo data comes back.") and get her yes.
5. Run `./scripts/reset-db.sh --yes`. It stops this app, deletes only this app's
   database volume, and starts again, so migrations and seed run fresh.
6. Check `docker compose logs prestart` for errors.

## 3. Real data (her answer: Yes, or data_is_real is already true)

1. The first time: set `"data_is_real": true` in `.app-builder.json` and
   `DATA_IS_REAL=true` in `.env`. This is permanent: log it in DECISIONS.md.
   `reset-db.sh` refuses to run from now on.
2. From now on, every change gets a proper Alembic migration that keeps all rows:
   1. Change the model(s).
   2. Autogenerate: `docker compose exec backend alembic revision --autogenerate -m "<what changed>"`.
   3. Review the file carefully. Autogenerate can't see renames (it drops and
      re-adds the column, losing data): write `op.alter_column(..., new_column_name=...)`
      instead. New non-null columns on existing rows need a `server_default`
      or a data step.
   4. Apply: `docker compose exec backend alembic upgrade head` (it also runs
      on every start).
   5. Check the data survived (count rows before and after).
3. Never reset, never `docker compose down -v`, never delete migrations that
   have been applied to real data.

## Always

- Keep `backend/app/seed.py` in step with the models. Seed functions only
  insert missing rows, so they're safe on real data too.
- Commit the model, migration and seed changes together.
