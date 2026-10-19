---
name: build-feature
description: Use whenever she wants to add, change or remove something in her app, or continue with the next milestone. Triggers include "can we add...", "I'd like a page for...", "change the form so...", "remove the ... button", "users should also be able to...", "let's do the next part", "what's next?", "continue". Covers updating the spec, building backend and frontend, database changes, checks, and telling her what to click.
---

# Build a feature

Follow the app-builder rules: plain English, one question at a time,
AskUserQuestion for choices.

1. **Restate the request** in one or two sentences, in business terms, and
   confirm it. If she said "next" or "continue", take the next unchecked
   milestone from `docs/PROGRESS.md` and restate that.

2. **Align.** Ask only the business questions this feature still needs (who can
   do it, what information, rules, what-ifs), per
   `${CLAUDE_PLUGIN_ROOT}/references/interview-guide.md`, but shorter. Mark guesses
   as assumptions.

3. **Update `docs/SPEC.md` first** (flows, information, rules, scope), so the
   spec always describes the app. Mention what changed.

4. **Implement** following `${CLAUDE_PLUGIN_ROOT}/references/conventions.md`:
   model → service → route → client → queries → page/components, copying the
   "items" example's shape. Keep the change as small as the feature allows.

5. **Database.** If any model changed, follow
   `${CLAUDE_PLUGIN_ROOT}/references/database-changes.md` (check `data_is_real`,
   ask her before any reset, migrate properly when data is real). Update `seed.py`.

6. **Regenerate the client**: `./scripts/generate-client.sh` (the app must be running).

7. **Verify.** Run `./scripts/check.sh` and fix everything it reports. Then
   actually exercise the feature: call the new API endpoints with curl through
   `http://localhost:<APP_PORT>/api/v1/...` (log in first for a token), check
   `docker compose logs backend` for errors, and load the page. Add a smoke
   test only if this is a critical flow.

8. **Tell her what to click**: the exact address, where to click, what she
   should see, and one thing to try that shows the rule works ("Try to approve
   your own request; it should refuse").

9. **Save the work.** Commit with a plain-English message ("Managers can approve
   or reject requests"). Update `docs/PROGRESS.md` (Done / In progress / Next,
   tick the milestone) and log notable decisions in `docs/DECISIONS.md`.

If a technical decision can't be settled from the app's needs or her answers,
write a `docs/QUESTIONS_FOR_CHARBEL.md` entry, tell her to send it to Charbel,
and continue with whatever isn't blocked.
