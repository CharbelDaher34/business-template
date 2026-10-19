# Picking APP_PORT

Each app publishes exactly one port on the shared server: the frontend's
`APP_PORT`, 40000 or higher. Pick it like this.

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

4. **Pick the lowest free port ≥ 40000** that is in none of the three lists.

5. **Record it**:
   - in the registry, under the port, with the app name and folder,
   - in `.env` (`APP_PORT=<port>`),
   - in `.app-builder.json` (`"app_port": <port>`),
   - in `CLAUDE.md` and `docs/DECISIONS.md`.

   Then tell her: "This app uses port X. Please let Charbel know."

6. **Never change the port of an existing app** without asking her first (her
   port forwarding and bookmarks depend on it).

If anything looks odd (the registry says a port is free but something listens
on it, or the list is very long), ask her to check with Charbel.
