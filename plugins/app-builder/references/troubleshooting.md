# Troubleshooting

## Looking at the app

- `docker compose ps`: is every service running, and the backend healthy?
- `docker compose logs --tail=100 backend` (or `frontend`, `prestart`, `db`).
- Call the API the page uses through the app's port (see "Trying the API from
  the shell" in `conventions.md`).
- Never print `.env`. To see whether a value is set without showing it:
  `grep -c '^NAME=..*' .env` (1 means set).

## Common causes

- **Errors everywhere right after a model change:** the database doesn't match
  the models yet. Generate and apply the migration (`database-changes.md`).
- **The app won't start / the page never loads:** `docker compose ps`. If
  `prestart` or `backend` exited, read its logs: they name the problem (a
  failing migration or seed, or a value in `.env` still set to `changethis`).
  A missing required `.env` value makes `docker compose` itself print which one.
- **Everything is down after the server restarted:** apps don't restart on
  their own. `docker compose up -d`.
- **Sent back to the login page unexpectedly:** the login expired (after 8
  days), or the account was deactivated or deleted. Only a 401 does this (see
  "Error handling" in `conventions.md`).
- **Admin can't log in:** they can use the email or the username. Changing
  `FIRST_ADMIN_PASSWORD` in `.env` later does nothing: it's only used when the
  admin is first created. Set a new password from the admin page instead.
- **A change doesn't show in the browser:** reload the page; check
  `docker compose logs frontend`. After adding a backend package, rebuild with
  `docker compose up -d --build`.
- **`./scripts/check.sh` fails on formatting only:**
  `docker compose exec backend ruff format app` and
  `docker compose exec frontend bun run lint`, then run it again.
- **The page can't be reached at all, but `docker compose ps` looks fine:**
  likely port forwarding, which is outside the project. Write a Charbel
  question with what you checked.
