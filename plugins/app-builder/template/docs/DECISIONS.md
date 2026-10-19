# Decisions

> One entry per notable decision, newest at the bottom. Each entry: what was
> decided, why, and its impact, in one or two lines.

## {{DATE}}: Starting point (from the app-builder template)

- **Stack:** FastAPI + Postgres backend, React frontend, all in Docker Compose. Why: the fixed app-builder stack. Impact: Charbel can support and review it.
- **Logins:** users sign in with their email or their username, and stay logged in for 8 days. Why: template default. Impact: change it here if people should be logged out sooner.
- **Port:** this app uses port {{APP_PORT}}, the only one it opens on the server. Why: picked as the lowest free port from 40000 up. Impact: Charbel knows which port to forward.
