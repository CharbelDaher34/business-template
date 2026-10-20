---
name: new-app
description: Start a new web app in this empty folder: set it up and run it, then interview you, write the spec and plan milestones.
disable-model-invocation: true
argument-hint: "short app name"
---

# New app

Set up a new app in the current folder, then run discovery with the builder.

**First, read `${CLAUDE_PLUGIN_ROOT}/rules/app-rules.md` and follow it for the
rest of this conversation.** Those rules load on their own in later sessions,
but not in this one: the folder wasn't an app yet when the session started.
The guides they mention under `references/` are in `${CLAUDE_PLUGIN_ROOT}/references/`.
Tell her briefly what you're doing at each step, without technical detail.

App name given: `$ARGUMENTS` (empty means: ask for it in step 3).

## Part 1: set up the project

1. **Check the folder is empty.** Run `ls -A`. Only these may be present:
   `.git`, `.gitignore`, `.gitattributes`, `.claude`. If anything else is
   there, stop and explain: "This folder already has files in it. Please open
   Claude Code in a new, empty folder (for example `mkdir my-app && cd my-app && claude`)
   and run /app-builder:new-app again."

2. **Copy the template**, keeping any Claude Code settings already in the
   folder (for example the app-builder plugin installed for this project only),
   which the template's `.claude/settings.json` would otherwise overwrite:
   ```bash
   if [ -f .claude/settings.json ]; then mv .claude/settings.json .claude/settings.before-template.json; fi
   cp -a "${CLAUDE_PLUGIN_ROOT}/template/." .
   if [ -f .claude/settings.before-template.json ]; then
     jq -s '.[0] * .[1]' .claude/settings.json .claude/settings.before-template.json > .claude/settings.merged.json &&
       mv .claude/settings.merged.json .claude/settings.json && rm .claude/settings.before-template.json
   fi
   ```

3. **Setup questions, together.** First check `git config user.name` and
   `git config user.email`. Then ask what setup needs in one go:
   - the app name, if none was given ("A short name is fine, you can change how
     it's displayed later"),
   - the first admin's email,
   - the admin's username (offer one made from the email),
   - if either git value is empty: her name and email, used to sign each saved
     version of the app (offer the admin email).
   Don't ask for the admin password here: she sets it herself in step 7.

4. **Compose project name.** Slug of the app name: lowercase, letters, digits
   and dashes only (e.g. "Visit Log" → `visit-log`). Make it unique on the
   server: check `docker compose ls --all --format json` (project names) and
   `docker volume ls --format '{{.Name}}'` (leftover `<name>_db-data` volumes).
   If taken, add `-2`, `-3`, ...

5. **Port.** Pick `APP_PORT` by following `${CLAUDE_PLUGIN_ROOT}/references/ports.md`
   (registry, `ss`, docker; the first free one of 40000, 40020, 40040, …;
   record it).

6. **Create `.env`** from `.env.example` (`cp .env.example .env`), then set:
   - `APP_NAME="<App name>"`, `COMPOSE_PROJECT_NAME=<slug>`, `APP_PORT=<port>`
   - `SECRET_KEY=` output of `openssl rand -hex 32`
   - `POSTGRES_PASSWORD=` output of `openssl rand -hex 24`
   - `CONTAINER_UID` / `CONTAINER_GID`: if
     `docker info --format '{{.SecurityOptions}}'` mentions `rootless`, use
     `0` and `0`; otherwise the output of `id -u` and `id -g`.
   Do this with shell commands (e.g. `sed -i`), so the secrets never appear in
   the chat. Never print `.env`.

7. **First admin**, from her step 3 answers. Set `FIRST_ADMIN_EMAIL` and
   `FIRST_ADMIN_USERNAME` in `.env`. She chooses the password and saves it
   with the set-secret script in her own terminal window (see "Secrets" in the
   rules). Give her the exact line,
   `cd <app folder> && ./scripts/set-secret.sh FIRST_ADMIN_PASSWORD`, say it
   needs at least 8 characters and that she can change it later in the app
   under Settings → Password, and wait until she says it's done.

8. **Fill in the placeholders.**
   - `CLAUDE.md`: `{{APP_NAME}}`, `{{APP_PORT}}`, `{{COMPOSE_PROJECT_NAME}}`,
     `{{SERVICES}}` → `none yet`, `{{ONE_LINE_DESCRIPTION}}` → her one-line
     description if you have it, else `(written after the discovery interview)`.
   - `docs/SPEC.md`: `{{APP_NAME}}`. `docs/DECISIONS.md`: `{{DATE}}` (today,
     YYYY-MM-DD) and `{{APP_PORT}}`.
   - `.app-builder.json`: `app_name`, `app_port` (a number).

9. **Git.** `git init` (if there's no `.git` yet). If you asked for her name
   and email in step 3, set them for this repository only
   (`git config user.name ...`, `git config user.email ...`). Then
   `git add -A` and `git commit -m "Start <App name> from the app-builder template"`.
   Check `git status` shows `.env` is NOT committed.

10. **Start and verify.** `docker compose up -d --build` (the first build takes a
    few minutes; tell her). Wait until `docker compose ps` shows the backend as
    healthy and the frontend running. Then verify login through the app's port,
    without printing the password:
    ```bash
    curl -s -o /dev/null -w '%{http_code}\n' -X POST "http://localhost:<port>/api/v1/login/access-token" \
      --data-urlencode "username=<admin username>" \
      --data-urlencode "password=$(grep '^FIRST_ADMIN_PASSWORD=' .env | cut -d= -f2-)"
    ```
    Expect `200`. Also check `http://localhost:<port>/` returns 200. If
    something fails, follow "When something is broken" in the rules and
    `${CLAUDE_PLUGIN_ROOT}/references/troubleshooting.md` before going on.

11. **Tell her how to open it**: "Your app is running on port <port>. Charbel
    will set up port forwarding for you; then open http://localhost:<port> and
    log in with <admin email or username> and the password from step 7.
    Please tell Charbel your app uses port <port>."

## Part 2: discovery

12. **Interview** her, following `${CLAUDE_PLUGIN_ROOT}/references/interview-guide.md`.

13. **Write `docs/SPEC.md`** from her answers, in her words. Fill the one-line
    description in `CLAUDE.md`. Show her the key points and get her **explicit
    approval** ("Does this describe your app? Anything to change?"). Mark it
    approved in the spec's status line.
    - **Accounts:** the template lets anyone who can open the app sign
      themselves up. If she said only an admin creates accounts, closing
      sign-up (the "Sign up" link and page, and the `/users/signup` endpoint)
      goes into milestone 1. Log the choice in DECISIONS.md.
    - **Test data:** record in DECISIONS.md that the app holds test data while
      she tries the idea out (`data_is_real` stays `false`), so later database
      changes don't need to ask again.

14. **Screens first?** Ask (AskUserQuestion): "Would you like to see the main
    screens first, with sample data, before I build the real thing?
    (recommended)". If yes: build the main pages in the frontend only, with
    clearly fake sample data in the page files (no backend, no database). Tell
    her what to open and click, walk through the flow together, and update
    SPEC.md from her feedback. Commit.

15. **Milestones.** Break the work into small milestones in business terms
    ("1. Team members can log a visit. 2. Managers see all visits..."), each
    something she can try in the browser. Write them in `docs/PROGRESS.md`
    (Milestones checklist and Next) and get her OK. Commit.

16. **Start milestone 1**, following "Handling any request" in the rules.
