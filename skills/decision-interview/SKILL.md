---
name: decision-interview
description: Interview discipline for turning a vague intent into decisions the user can defend. One question at a time, each carrying a recommendation and its cost; look facts up yourself and put only decisions to the user; land every conclusion in the authoritative document rather than a separate log that will drift. Use whenever another skill needs to ask a user a series of design or scoping questions.
---

# Decision interview

Turn a vague intent into decisions **the user can defend to someone who wasn't there**. This skill is the discipline only — the questions themselves belong to whichever skill invoked this one.

## Discipline

- **One question at a time. Wait for the answer.** Four at once makes thinking impossible, especially for non-technical users.
- **Give a recommendation, and state the cost.** Users need "what do I lose by picking this", not a menu. An option without a stated cost carries no information.
- **Look up facts; put decisions to the user.** How wide is that column, what stack is in use, where does that value live — find out yourself. Whether this *should* be the answer is theirs.
- **When the user overrides your recommendation, accept it and list the knock-on effects.** They move forward one step; you are responsible for saying which already-settled conclusions that step disturbs.
- **When the user pushes back or looks confused, explain before re-asking.** Never re-throw the same question verbatim.

Answering your own questions is not a liberal interpretation of this skill — it is a failure of it.

## How to write the options

| Weak | Strong |
|---|---|
| "Option A / Option B / Option C" | Each option states: what you get, what you lose, when you'll regret it |
| "Which one do you want?" | "When it doesn't fit, which one gives way first? — giving up A costs you…, giving up B costs you…" |
| Recommendation not marked | Put the recommendation first and label it, so the user can act on the first line alone |

Costs must be **specific about what will happen**, not abstract. "Six months in, this becomes an infinitely-scrolling junk drawer" is a hundred times more useful than "poor extensibility".

## Closing

Flatten everything into three tables and wait for confirmation before writing anything:

1. **Settled conclusions**, numbered, one per line
2. **What I'll decide myself** — already answered by the material at hand, or purely mechanical. Don't spend the user's attention on these
3. **Explicitly out of scope**

## Where conclusions ultimately live

That numbered table is a **one-off conversational artifact**. Do not turn it into another document, and **do not start a separately-maintained decision log** — it will drift from the authoritative document, and an agent reading two contradictory sources picks one at random.

| Content | Destination |
|---|---|
| "We decided to do it this way" | A **rule with its reasoning**, in the relevant chapter of the authoritative document |
| "We considered that and rejected it" | The authoritative document's *Overturned* appendix — was / became / why |
| "We're not covering that" | The authoritative document's *not decided here* appendix |
| "This still needs the user's call" | Ask. If you can't, record it as open **and name it in conversation** — don't bury it in a file |
| "Why we chose this, what we excluded, when to revisit" | A decision record. Call the Skill tool with "decision-record" |

Exception: if the user explicitly wants a shareable decision document for team alignment, write one — but put a line at the top naming which file is authoritative and stating that this one only records *why*, so it cannot become a second source of truth.
