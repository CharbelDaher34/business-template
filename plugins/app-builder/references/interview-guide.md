# Discovery interview guide

Goal: understand the app well enough to write `docs/SPEC.md`, and help the
builder understand her own idea better. You're a thoughtful business analyst,
not a form to fill in.

## 1. Let her describe it freely

Start open: "Tell me about the app you have in mind. What problem does it solve,
and for whom?" Don't interrupt with questions while she explains.

Then reflect it back in two or three sentences and confirm:
"So: a tool where your field team logs site visits, and you see a weekly summary
per client. Did I get that right?"

## 2. Business questions, one at a time

Cover these, in roughly this order. Skip what she already answered.

1. **Users and roles.** Who uses it? Are there different kinds of users who can
   do different things? ("Can a team member see other members' visits?")
2. **The main flow, step by step.** Walk through one real example from start to
   finish. ("A visit happens. What's the first thing someone does in the app?")
3. **Information kept.** What does the app need to remember about each thing?
   ("For a visit: date, client, who went, notes, photos?")
4. **Rules.** Statuses, approvals, calculations, permissions, limits.
   ("Does anyone approve a visit report, or is it final once submitted?")
5. **Exceptions and what-ifs.** ("What happens if a visit is cancelled? If
   someone made a mistake in a submitted report?")
6. **First version vs later.** ("If we could only ship three things first, which
   three?")
7. **First users and admin.** Who will use it first, and who manages users?

Use AskUserQuestion with clickable options when the answer has a few likely
choices. Use open questions when it doesn't.

## 3. Aim for alignment, surface gaps

- Ask questions that help her think, not just questions you need answered.
- Gently point out gaps and contradictions: "What happens if a customer cancels
  after paying?" "You said managers approve requests. What if the manager is away?"
- Offer a sensible default when she's unsure: "Many teams do X. Shall we start
  with that and change it later if needed?"

## 4. Don't interrogate

- Stop when there's enough to build a first version. Details can come later,
  milestone by milestone.
- If she's unsure, make a reasonable guess and record it under "Open
  assumptions" in the spec, marked clearly as an assumption.
- Keep the pace friendly: summarize every few answers so she sees progress.

## 5. Good vs bad questions

**Example 1**
- Bad (too technical): "Should visits have a foreign key to clients, or should
  the client be a free-text field?"
- Good: "When someone logs a visit, do they pick the client from a list, or type
  the name? Would you ever want to see all visits for one client?"

**Example 2**
- Bad (too technical): "Do you need role-based access control?"
- Good: "Should everyone see everything, or are there things only a manager
  should see or change?"

**Example 3**
- Bad (vague, overwhelming): "What are all your requirements?"
- Good: "Picture Monday morning. Who opens the app first, and what do they want
  to see?"

## 6. After the interview

Write `docs/SPEC.md` using its sections, in her words. Show it to her (or the
key parts), and ask for her explicit approval before building.
