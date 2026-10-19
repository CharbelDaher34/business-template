---
name: add-integration
description: Use whenever the app needs to connect to something outside it, store files, or use AI. Triggers include payments ("take card payments", Stripe), sending messages (email, SMS, WhatsApp, notifications), maps or addresses, AI ("summarize", "suggest", "chatbot", "read this document"), file uploads (photos, PDFs, attachments), importing or exporting data (Excel, CSV, another system), calendars, and "connect it to ...".
---

# Add an integration

Follow the app-builder rules: plain English, one question at a time,
AskUserQuestion for choices. Never ask her to paste a key into the chat.

1. **Understand the need** in business terms: what should happen, for whom,
   how often. Confirm it.

2. **Explain before building**, following
   `${CLAUDE_PLUGIN_ROOT}/references/integrations.md`: what it does and why,
   simpler or free alternatives (including no integration), cost, exactly
   what she must do, and that she puts keys into `.env` herself. Agree on the
   choice before writing code.

3. **Paid, lock-in, or outside the fixed stack?** Write a
   `docs/QUESTIONS_FOR_CHARBEL.md` entry, tell her to send it to Charbel, and
   keep working on what isn't blocked.

4. **Build it** with the specific guide:
   - File uploads or attachments: `${CLAUDE_PLUGIN_ROOT}/references/file-storage-rustfs.md`
   - AI features: `${CLAUDE_PLUGIN_ROOT}/references/ai-pydantic-ai.md`
   - Anything else: `${CLAUDE_PLUGIN_ROOT}/references/integrations.md`, with the
     integration in its own service module so it can be swapped later.
   Then continue as in the build-feature skill: spec first, conventions,
   client, `./scripts/check.sh`, exercise it, tell her what to click.

5. **Record it.** Add the service to `services` in `.app-builder.json` (e.g.
   `"rustfs"`, `"pydantic-ai"`, `"stripe"`) and to the services line in
   `CLAUDE.md`. Add new settings (names only) to `.env.example`. Log the
   decision, version and cost in `docs/DECISIONS.md`. Commit and update
   `docs/PROGRESS.md`.
