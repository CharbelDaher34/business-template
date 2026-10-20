# Picking APP_PORT

Each app publishes exactly one port on the shared server: the frontend's
`APP_PORT`, one of 40000, 40020, 40040, … (steps of 20). Pick it like this.

1. **Read the builder's port registry** `~/.app-builder/ports.json`. Create it if
   it's missing:
   ```bash
   mkdir -p ~/.app-builder && [ -f ~/.app-builder/ports.json ] || echo '{}' > ~/.app-builder/ports.json
   ```
   It maps ports to app names and folders, e.g.
   `{"40000": {"app": "visit-log", "folder": "/home/maya/visit-log"}}`.

2. **List ports already listening** on the server:
   ```bash
   ss -tlnH | awk '{print $4}' | sed -E 's/.*:([0-9]+)$/\1/' | sort -un
   ```

3. **List ports published by Docker**, including stopped containers (read-only):
   ```bash
   docker ps -a --format '{{.Ports}}' | grep -oE ':[0-9]+->' | tr -d ':->' | sort -un
   ```

4. **Pick the first free port of 40000, 40020, 40040, …** (steps of 20, never
   the ports in between) that is in none of the three lists. Example: 40000 and
   40020 are taken, so use 40040.

5. **Record it**:
   - in the registry, under the port, with the app name and folder,
   - in `.env` (`APP_PORT=<port>`),
   - in `.app-builder.json` (`"app_port": <port>`),
   - in `CLAUDE.md` and `docs/DECISIONS.md`.

6. **Never change the port of an existing app** without asking her first (her
   port forwarding and bookmarks depend on it).

If anything looks odd (the registry says a port is free but something listens
on it, or the list is very long), ask her to check with Charbel.
