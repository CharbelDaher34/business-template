# app-builder

A Claude Code plugin for building real web apps on a shared Linux server,
without writing code yourself. Claude interviews you about your idea, writes
a spec with you, shows you the screens first, then builds the app in small
milestones you can try in the browser. Every app uses the same proven stack
(FastAPI + Postgres + React), so Charbel can support and review it.

---

## For the builder

### 1. Before you start

Charbel has prepared the server for you with Docker, Claude Code and `jq`.
You only need to be able to log in to the server and run `claude`.

(Charbel: also set `"permissions": {"defaultMode": "auto"}` in her
`~/.claude/settings.json`, so she isn't asked to approve each command and file
edit. It must be the user file: Claude Code ignores `"auto"` in an app's own
`.claude/settings.json`, so the template can't ship it.)

### 2. Install the plugin

Inside Claude Code, type these two commands:

```
/plugin marketplace add CharbelDaher34/business-template
```

```
/plugin install app-builder@charbel-apps
```

### 3. Turn on automatic updates

Updates are **off by default** for marketplaces like this one. To turn them on:
type `/plugin`, go to **Marketplaces**, select **charbel-apps**, and enable
**auto-update**. Then you always get Charbel's latest improvements.

### 4. Start a new app

In the server's terminal:

```bash
mkdir my-app && cd my-app && claude
```

Then type `/app-builder:new-app` followed by a short name for your app, for
example `/app-builder:new-app visit log`. Claude sets everything up, starts
the app, and then asks you about your idea, several questions at a time.

### 5. Continue later

Open Claude Code in the app's folder (`cd my-app && claude`) and just talk:
"let's continue", "can we add...", "this page shows the wrong total". Claude
reads where you left off (the files in `docs/`) and tells you what's next.

### 6. Open your app in the browser

Each app has its own port number, which Claude tells you (for example 40000).
Charbel explains how to set up port forwarding once; after that you open
`http://localhost:<port>` in your browser.

### 7. When Claude needs a key or password

Claude never asks you to type a key or password into the chat. It gives you
one line to paste into a second terminal window on the server, for example
`cd ~/my-app && ./scripts/set-secret.sh ANTHROPIC_API_KEY`. Paste the key when
asked (it isn't shown on screen), then tell Claude it's done.

### 8. When Claude says "ask Charbel"

Some technical decisions need Charbel. Claude writes them in
`docs/QUESTIONS_FOR_CHARBEL.md` in your app's folder. Send Charbel that entry
(copy and paste it into a message). Claude keeps working on everything else
in the meantime.

---

## For Charbel (maintaining)

### Where things live

```
.claude-plugin/marketplace.json     marketplace "charbel-apps" (one plugin)
plugins/app-builder/
  .claude-plugin/plugin.json        name, version (the only place with the version)
  hooks/hooks.json                  SessionStart + PreToolUse(Bash)
  hooks/session-start.sh            injects rules/app-rules.md inside app projects
  hooks/guard-bash.sh               blocks / asks about dangerous shell commands
  rules/app-rules.md                always-on rules: how Claude works with her (keep it short)
  references/*.md                   detailed guides the rules and new-app point to
  skills/new-app/SKILL.md           /app-builder:new-app, the one skill (setup + discovery)
  template/                         the app skeleton copied into each new app
```

How it's organised: the always-on rules carry the behaviour for everything she
asks (any request, something broken, outside services), so it doesn't depend on
Claude picking the right skill. The details live in `references/`, which Claude
reads when relevant. `new-app` is the only skill, because starting an app is a
one-time procedure she runs on purpose.

Everything the plugin needs at runtime must live under `plugins/app-builder/`:
only that folder is copied into the install cache. A `CLAUDE.md` at the plugin
root would not be loaded, which is why the rules come from the SessionStart hook.
Plugins can't ship permission rules, so the allow/ask/deny rules live in
`template/.claude/settings.json` (copied into each app), and the hard blocks
live in `guard-bash.sh` (which updates with the plugin).

The hooks need `jq` (or `python3` as a fallback) and GNU `realpath`.

### The template

`template/` is a FastAPI + React app skeleton for local development only:
no deployment, CI, email or end-to-end tests. Backend in routers / services /
models, login by email or username, idempotent `app/seed.py`, a single
`compose.yml` where only the frontend publishes a port (`APP_PORT`, bound to
127.0.0.1; Vite proxies `/api` and `/api/docs` to the backend), and
`scripts/check.sh`, `scripts/generate-client.sh`, `scripts/reset-db.sh` and
`scripts/set-secret.sh` (the builder saves a secret in `.env` without it
reaching the chat).

`CONTAINER_UID`/`CONTAINER_GID` in `.env` decide which user the containers run
as, so files they write into the app folder belong to the builder: her own ids
on normal Docker, `0:0` on rootless Docker (new-app detects which).

To try the template by hand: copy it to a temp folder, `cp .env.example .env`,
fill in the empty values and the `changethis` ones, then
`docker compose up -d --build` and `./scripts/check.sh`.

### How to update

1. Edit the files.
2. Bump `version` in `plugins/app-builder/.claude-plugin/plugin.json`
   (e.g. `0.1.0` → `0.1.1`). Users only receive an update when this string
   changes. Don't add a version to the marketplace entry.
3. Validate:
   ```bash
   claude plugin validate .
   ```
   ```bash
   claude plugin validate plugins/app-builder
   ```
4. Commit and push. Pushing is publishing: this GitHub repo *is* the
   marketplace, so there's no separate store to upload to. Builders get the new
   version from here (automatically if they turned on auto-update).

What updates where:
- **Skills, rules, references and hooks** update everywhere, in every app, on
  the next plugin update.
- **Template changes only affect new apps.** Existing apps keep the copy they
  started from (`template_version` in their `.app-builder.json`). Port a template
  fix to an existing app by hand, in that app's folder. If you change the
  template, bump `template_version` in `template/.app-builder.json` too.

### Extending guard-bash.sh

`guard-bash.sh` splits each command line into simple commands (respecting
quotes and heredocs, and also checking `$(...)`, backticks, `bash -c` and
`eval`), then checks each one:

- A whole program: add it to the `case "$cmd"` in `check_simple_command`, calling
  `deny "reason"` or `ask "reason"`. Reasons are plain English; deny reasons
  get "If this is really needed, ask Charbel." appended.
- A subcommand: edit `check_docker`, `check_compose` or `check_git`.
- "Only inside this project" rules: `check_rm` and `check_chmod_chown` use
  `resolve` and `inside_project`.

Deny wins over ask; anything else exits silently so the normal permission
flow applies. Test changes by piping sample hook JSON into the script:

```bash
echo '{"tool_input":{"command":"sudo ls"},"cwd":"/tmp/x"}' | plugins/app-builder/hooks/guard-bash.sh
```
