# as-built.md skeleton

> Records what the interface **actually is** right now — not what it should be.
> Nothing in this file is normative. `layout.md` is authoritative for what is correct.

Kept at the repo root, beside the specs, so the reconciliation is visible.

---

## §1 How this was derived

State the source and its reliability, per item: read from code / read from a mockup / inferred. An inferred fact is a hypothesis and must be marked as one.

If any of it came from mockups rather than code, say so here — mockups describe an exploration, code describes reality, and the two disagree more often than people expect.

## §2 The as-built region tree

The tree as it actually renders. Use whatever names the code actually uses, **even when they are bad names** — renaming here destroys the mapping that makes the reconciliation possible.

One row per container: current name | where it is declared | what it actually holds today | how many places construct it.

## §3 Structural parameters as found

Column widths, minimum widths, breakpoints, caps — the values actually in the code. Note where each is declared and **how many copies of it exist**. Three copies of one width is itself a finding.

## §4 Non-happy-path states as found

Which of empty / loading / partial failure / whole-region failure are actually implemented, and where each one presents. Absence is a finding, not an omission from this document.

## §5 The gap

The point of the whole file. One row per discrepancy:

| What was found | What the spec will require | Cost to close | Blocking? |
|---|---|---|---|

"Cost to close" is what makes the legacy-strategy question answerable. Without it, the user is guessing.

## §6 Naming collisions

Names in the code that will collide with the allowlist — same word, different meaning, or two different words for one thing. These are what make an allowlist rollout painful, and they are cheap to find now and expensive to find later.

## Appendix — mockup reality

If mockups were part of the source, record what they showed, separately from what the code does. Do not merge the two.
