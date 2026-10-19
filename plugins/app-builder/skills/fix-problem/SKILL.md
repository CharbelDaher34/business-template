---
name: fix-problem
description: Use whenever something in the app isn't working or looks wrong. Triggers include "it's not working", "I get an error", an error message pasted in, "the page is blank", "nothing happens when I click", "it says something went wrong", "this number is wrong", "I can't log in", "the app won't start", "the page won't load", "it was working yesterday".
---

# Fix a problem

Follow the app-builder rules: plain English, one question at a time.

1. **Understand what happened.** Ask, one question at a time: what she did
   (which page, what she clicked or typed), what she expected, and what
   happened instead (exact message, if any). Skip what she already told you.

2. **Reproduce it** before changing anything:
   - `docker compose ps`: is every service running and the backend healthy?
   - `docker compose logs --tail=100 backend` (and `frontend`, `prestart`, `db`).
   - Call the API the page uses with curl through
     `http://localhost:<APP_PORT>/api/v1/...` (log in for a token first).
   - If the app won't start: check `.env` has every value from `.env.example`
     (without printing secrets), and read the prestart logs (migrations, seed).

3. **Explain the cause** in one or two plain sentences ("The page asked for the
   list before you were logged in, so it showed nothing.").

4. **Fix it.** Make the smallest change that fixes the cause. Run
   `./scripts/check.sh`, then verify the original scenario yourself (same steps
   she took), and ask her to try again with exact steps.

5. **Save it.** Commit with a plain-English message ("Fix blank visits page
   after login") and note it in `docs/PROGRESS.md` if it matters for her.

6. **Outside the project?** If the cause is the server, other containers, other
   apps, the network, or port forwarding: don't touch it. Write a
   `docs/QUESTIONS_FOR_CHARBEL.md` entry with what you saw (commands and
   messages, no secrets), tell her to send it to Charbel, and keep working on
   anything not blocked.
