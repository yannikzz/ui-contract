---
name: decision-record
description: Record why a decision was made, what was excluded, and under what conditions to revisit it — as an ADR that points at the rules rather than restating them. Covers which decisions qualify, why decision categories with different lifecycles get separate numbering spaces, and superseding instead of rewriting. Use when a heavyweight decision has just been settled and the reasoning would otherwise be lost.
---

# Decision record

The authoritative document owns **what is currently correct**. A decision record owns **why it was chosen, what was excluded, and under what conditions to revisit** — nothing else.

| | Records | Lives in |
|---|---|---|
| **Rule** | What is currently correct | The authoritative document's clauses — the single authority |
| **Decision** | Why it was chosen then, what was ruled out, when to revisit | The decision record |

## An ADR must not restate rules

It never states "what is currently correct", so it is **structurally incapable** of contradicting the authoritative document. That is precisely what separates it from the separately-maintained decision log that `decision-interview` forbids: a log restates conclusions and drifts; a record points at them and can't.

Point at a clause. Never copy it.

## Which decisions qualify

Not every choice earns a file. Three tests — a decision that passes all three qualifies:

1. **Hard to reverse.** Undoing it means reworking things that were built on top of it
2. **Real alternatives were excluded.** If there was only ever one option, there is no reasoning to preserve
3. **It has a revisit condition you can name.** "If X turns out to be false, this should be reopened"

If the domain skill that invoked this one grades its own decisions by weight, use that grading: the heavyweight tier gets a record, the rest live as clauses only.

## Separate numbering spaces for categories with different lifecycles

Decisions of genuinely different kinds do not belong in one incrementing sequence. The test is **lifecycle**: who makes them, how often they are revisited, and what it costs to overturn one.

Two concrete consequences of mixing them:

- A burst of five decisions from one fast-moving category buries two from a slow-moving one
- When revisiting the fast category, you would have to re-read every decision — including the slow ones you must specifically **not** touch

The harder evidence: **supersede only ever happens within a category.** A decision of one kind never supersedes a decision of another kind. If the supersede relation doesn't cross the boundary, the numbering space shouldn't either.

So: one directory per category, each incrementing independently. Cross-category references are allowed, but **reference the number only, never restate the content**.

Which categories exist is the domain skill's call, not this one's — but the boundary must come from a distinction the project already has, not a new one invented for filing purposes.

## Supersede, never rewrite

An accepted record is not edited. When a single decision inside it is overturned, **write a new record that supersedes that decision** and says so in its header. The old file stays exactly as it was.

Rewriting destroys the one thing the record was for: knowing what was believed, and when.

If a superseding record must correct a count or a name in several places of the old one, list those places explicitly in the new record. Leave the old text alone.

## Shape

A record carries: status and date; what it relates to and what it supersedes; the background that made the decision necessary; the decision itself; **the alternatives excluded and why**; the costs knowingly accepted; and the revisit conditions.

The excluded-alternatives section is the one people drop, and the one that pays. Six months on, the question is almost never "what did we decide" — it is "did we already think about X".
