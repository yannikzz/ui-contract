# layout.md skeleton

Ten chapters plus three appendices. Chapters can be merged or renamed, but **no chapter's question may be dropped** — each missing chapter is one more category of thing agents will invent for themselves.

Open with three sentences telling agents how to use the document:

```markdown
> **Three sentences for coding agents:**
> 1. Before changing any interface structure, walk §1, the placement decision tree. If it lands, implement directly — no need to edit this document.
> 2. If it doesn't land, **stop**. Do not open a new region, column, or floating layer on your own. Use §9, the change process.
> 3. Every region marker in the code must appear in the §2 allowlist. A name not in the table is a violation.
```

---

## §0 Division of labor with the visual spec

Must answer: who owns what · what the cut is · where the ambiguous items go · who wins in a conflict.

Format: a table of "item → owner → why", weighted toward the **ambiguous items** (spacing, radii, padding; a status label's *shape* versus its *position*). There is one cut: **does it change when the brand skin changes?**

Close with a hard rule: this document contains no color / font-size / radius / spacing values (structural parameters excepted), and the visual spec contains no region tree or column widths. State also that **existing code is not authoritative** — when code and document disagree, the code changes.

Aim for zero overlap, but if one or two genuine coupling points survive, mark them on both sides ("⚠ changing this requires revisiting §X of the other spec"). A named coupling is safer than a false claim of zero overlap.

## §1 Placement decision tree

The entry point for the whole document. Must answer: given a new interface requirement, how do you get all the way to a specific region name?

Structure:

1. **Short-circuits** (3–6) — where the answer is obvious; catch them first. Typically process events, long content needing width, action buttons. Rows get inserted as traces find holes, so **cite a short-circuit by its condition, never its position** — here and in code. A `§1.1 short-circuit 3` in a component comment goes silently wrong the moment a row lands above it.
2. **The trunk** (4–6 questions) — drawn as an ASCII tree, where every leaf is a **specific region name**, not a description.
3. **What to do when nothing matches** — write "stop" explicitly, and point to §9. That sentence matters more than the whole tree: without it, an agent picks the closest-looking region and stuffs the thing in.
4. **A reverse checklist** — "if you're about to do any of the following, you've already gone off course" — 4–6 of the most common overreaches.

Ordering principle for the trunk: **the most discriminating question goes first.** Usually that's "is this a facet of a first-class object", because it immediately separates "goes in the focus slot" from "goes in the nav".

### The tree has to be total

A tree that answers *most* inputs is a spec with a hole, and the hole is where agents improvise. **Every input reaches exactly one region name or the explicit stop — never zero, never two.**

Five ways it breaks, all five shipped in trees whose author had confirmed "there is a tree, and it has a stop":

| Break | What it looked like | What it means |
|---|---|---|
| **Gap** | A one-off library action fell between short-circuits 1 and 3, matching no branch | A question is missing, or a short-circuit's scope is narrower than its wording |
| **Two answers** | A leaf read "overlay.body *or* board.detail" — no criterion, no § pointer | Two plausible destinations calls for one more question, not a coin flip |
| **Fallback into a real region** | "Nothing matched → settings" | The fallback is *stop → §9*, never a region: the catch-all becomes the junk drawer the user came here to fix |
| **Loop** | The fallback routed back into the trunk, which routed back to the fallback | The stop is a leaf — it leaves the document for the change process. A fallback that re-enters can't terminate |
| **Open boundary** | A nav segment capped at 2 said nothing about reaching the cap; the one capped at 4 said it twice | Every cap and closed enumeration states what happens when it's full, or "an 11th item arrives" has nowhere to go |

**When the fallback contradicts the rest of the document, the tree is what's wrong.** One run's fallback routed a global action into settings, contradicting at once the short-circuit that forbade it, §2's "must not hold" cell, an anti-pattern, and the union type. The pull is to relax the prohibition — backwards: four places against one means the trunk lost a branch.

### Verify it by trying to break it

Trace the finished tree with inputs picked to be hostile, and **record where each one lands in Appendix C**.

Tracing in the conversation and not in the document is the same as not tracing. The next editor cannot tell a branch shaped to stop a specific bad input from one written off the cuff — so they "tidy it up", and the input it caught walks straight through. Nothing in the output reveals the verification happened, which is why this is an artifact requirement and not a habit:

1. **A one-off action belonging to no object** — export everything, bulk import, contact support. The most common gap, and the source of the worst observed failure: a confident "put it in settings".
2. **Something that plausibly fits two regions** — checks that leaves are single-valued.
3. **Something arriving at a full enumeration** — one more item for a capped nav segment, one more type beyond the slot enumeration.
4. **Something that genuinely doesn't belong** — has to reach the stop, and the stop has to not be a region.

A friendly input passes on any tree, hole included. That is precisely how this defect survives review: "can it place a new metric card" gets asked, "can it place the export button" doesn't.

**Then trace three or four ordinary requirements too, each landing on a region name — also in Appendix C.** Totality is trivially satisfiable by stopping on everything, and the hostile traces would all pass such a tree. One that sends everyday work to §9 is a permission queue, not a contract: the user arrived because "where does this go" had no answer, and "file an application" is not an answer. An ordinary input that stops usually means a whole class is missing rather than a genuinely new region — most often controls (search, filter, sort), which are neither a facet of an object nor a destination, so they fall through every branch.

## §2 Region-name allowlist

Must answer: which region names are legal · what each region holds · **what it must not hold**.

Four columns: region name | responsibility (one line) | must hold | must not hold. Add a fifth for size constraints where they exist. **Copy the header row, do not translate it:**

```
| Region | Responsibility | Must hold | Must not hold |
| 区域名 | 职责 | 允许放 | 禁止放 |
```

In any other language, keep the English beside your rendering in that column's header — `<yours> (must not hold)`. `ui-contract-audit` finds this column **by its header**, and only by these two spellings: a header that says 禁止 or 不该放 instead reads as no column at all.

Requirements:

- **The "must not hold" column cannot be empty.** Listing only what goes in is documentation; stating what must not is a spec. Forbidden entries come from every "don't make it X" conclusion in the interview.
- Spell out the naming convention (case, separator for nesting, maximum depth), and guarantee the **same name appears identically in the document, the type definition, and the code**.
- At the end of the table, point at its code forms (the union type plus the human-readable metadata) and state that **changing this table requires changing those too**.

## §3 Shell skeleton

Must answer: what the region tree looks like · what's fixed and what's elastic · how it degrades as space shrinks · how many context/session forms exist.

Draw the region tree as ASCII, annotating fixed sizes and elasticity. After the tree, write 2–4 **key structural facts** — the things that **can't be seen from the picture but change the extension rules** (a bar that spans several columns; two elements that look aligned but belong to different layers).

The degradation subsection covers: the trigger (minimum usable size, not viewport breakpoints), the collapse order, **what remains after collapse**, and **who wins between a manual toggle and automatic degradation** (recommend the user, in both directions).

If the product's context has multiple forms (shared space versus private space, containers at different levels), give it its own section: the hierarchy of each, its boundary, its unit of division — and **explicitly distinguish any two similar concepts**, or agents will conflate them.

### Numbers this document cannot settle alone — mark them ⏳

Some structural parameters are only correct relative to a type scale and a spacing scale, and both of those belong to the visual spec:

| The structural number | What only the visual spec can answer |
|---|---|
| A fixed panel width | do the fields and actions fit at the chosen type size |
| A minimum usable width (the degradation trigger) | is that width readable at the chosen scale |
| A page size / row count | do that many rows fit a screen at the chosen row height |

Writing them plainly claims a certainty nobody has. **Mark each one ⏳ and name what would settle it.** `ui-contract-design` carries a completion criterion that clears every ⏳; `ui-contract-audit` reports unresolved ones as a warning, not as drift — an unsettled number is honest, an unmarked guess is not.

```
| Panel width | 360 | ⏳ pending the type scale — do 9 fields and 5 actions fit? |
```

**Put ⏳ in the number's own table cell, on one line, with the question on it.** Both the handover note and `ui-contract-audit`'s check 10 lift these lines verbatim, and they find them by looking for **table rows** carrying the marker — a ⏳ whose reason lives in a paragraph three lines below arrives at the visual owner without its reason, and a ⏳ used in prose *about* the marker gets counted as a pending number.

That second one is measured, not hypothetical: a document explaining its own ⏳ convention in three sentences reported six pending numbers where there were three. Explain the convention in words ("the pending marker") rather than by using the character, or accept that the prose lines will be filtered out by the table-row rule and keep the marker itself in the cells.

⏳ is **not** the same as `design.md`'s 🌡. 🌡 says a clause is a hypothesis about the world. ⏳ says a number is waiting on a decision that is definitely coming, from a named place. A ⏳ that is still there when the interface ships is a process failure; a 🌡 that is still there is normal.

**Do not write the visual value here to resolve it.** The resolution is: the visual spec settles its scale, someone checks the number against it, and the ⏳ becomes a plain number — or a different number. A `layout.md` that starts carrying font sizes to justify its widths has become the thing the split exists to prevent, and `no-visual-values-in-structure` will say so.

### A third outcome: the number is refuted — mark it ⛔

Settling a ⏳ has **two** endings, not one. The visual scale can hand back a number, or it can show that the marked direction does not hold at any scale: nine fields and five actions do not fit in 360px however small the type gets. That is not "still waiting" — the question itself is dead — so it **must not stay ⏳**.

**Mark it ⛔ in the same table cell, on one line, and say what refuted it.** Same placement rule as ⏳, for the same reason: the handover note and check 10 read table rows.

| Panel width | ~~360~~ | ⛔ refuted by the projection — 9 fields + 5 actions do not fit at any type scale; the region needs splitting |

⛔ is the **third** member of this set, and the three say different things:

| | Says | Still there when the interface ships |
|---|---|---|
| ⏳ | a number is waiting on a decision that is definitely coming, from a named place | a process failure |
| ⛔ | the direction that number belonged to is dead; something structural has to change | a process failure — it is unfinished work, not an open question |
| 🌡 (`design.md`) | a clause is a hypothesis about the world | normal |

**`ui-contract-audit`'s check 10 reports all three states.** It counts and lifts ⏳ rows, and lifts ⛔ rows verbatim with what refuted them — reported as refuted, never counted as pending. A green check 10 means no table row is waiting and none was refuted. What it still cannot do is see past the placement rule: a marker written outside a table row is invisible, and a coupling nobody marked was never a candidate for reporting — that second ⚠ stands.

⚠ **This only catches couplings somebody noticed.** One nobody spotted sails straight through, and the wireframe stays the backstop that finds it. Do not read "no ⏳ left" as "no coupling left".

## §4 Page archetypes

Must answer: how many archetypes exist · which shell parts are present or absent in each · what the distinguishing feature is.

Table: archetype | column structure | used for | distinguishing feature.

Add an "archetype × shell part" matrix — which parts appear only in some archetypes. That matrix heads off endless re-litigation of "why does this page have/not have that thing".

For two archetypes with **identical structure but different semantics**, give them a section spelling out four differences (nature of the content, does it empty, is there an action area, what happens on completion).

The orthogonal overlay gets its own section: what it covers, how it's triggered, how it closes and restores state, **whether it can stack**, and what qualifies to be promoted into it.

## §5 Focus slot

Must answer: how many types · each type's internal structure · who decides which is showing · the bar for adding a type.

- **Enumeration table**: type | object it carries | initial facet groups.
- **Admission rule**: only a facet of a first-class object from the enumeration gets in. List the typical **non-qualifiers** and where they go instead.
- **Internal structure**: one set of segments shared by all types (each segment optional), plus 2–3 typical combinations. **Name the combinations** — every later discussion will use those names.
- **The bar for a new type**: the three first-class-object tests. And state plainly: **a process state is not an object**, or the enumeration inflates with every process step.
- **Switching rules**: who decides, when it resets, whether it steals focus, switching cost (one step), and the requirement that each type be self-sufficient (carries its own context; signals exist elsewhere).
- **Keyboard and focus**: the layered semantics of the escape key, the combination reserved for global search, and where focus lands on open.

## §6 Content routing in the main area

Must answer: how many classes of content · which region each lands in · in what form · why.

Four columns: content | destination | form | why. End with a **catch-all**: anything not in these classes means stop and use §9 — no inventing form N+1.

If the interview settled on "actions only in one place", give it a section covering: what the other place holds (a reference plus a summary), what clicking does, what gets no exception, and the difference between "one component, several entry points" and "two implementations".

### Status labels: the classes are structural, the colours are not

If the product shows status, the **set of semantic classes** belongs here, not in the visual
spec. The cut is the usual one: "needs somebody to act on it" does not change when the brand
changes; which colour says so does.

Write two tables: the classes (closed set, each with the test that puts a status in it), and
every status this product has mapped to one. The code form is an exhaustive `Record`, so
**adding a status forces classifying it** — forget and the type check fails.

Four or five classes is usually right. Two failure modes, both common:

| | |
|---|---|
| Collapsing "needs action" and "blocked" | The user's next move is different — go do it, versus go resolve something else first. Merged, the column only says "something / nothing" |
| Giving a terminal state the success class because it is terminal | Archiving a draft that was rejected three times and abandoned should not read as an achievement |

**Do not skip the classes and map statuses straight to colours.** Six statuses mapped to six
colours is not a classification, and the seventh arrives with nothing forcing anyone to think
about where it belongs.

## §7 Navigation admission rules

Must answer: how many segments · each segment's distinguishing feature · each segment's badge rule · what doesn't belong in the nav at all.

Spell out **the consequence of putting something in the wrong segment** — one per segment, specific about what will happen. Cap the "never empties" segment and explain that the cap's job is to force a consolidation decision — including what happens once the cap is reached, and who decides. A cap with no at-cap instruction is a dead end (see §1, totality).

## §8 Non-happy-path placement

Must answer: for empty / loading / partial failure / whole-region failure — where each goes, how it presents, and **what's forbidden**.

Rules only; don't draw every page. Add a "special case → destination" table (business-level failures, exceptions needing human intervention, success confirmations) and a blank template to fill in when a new archetype is added.

## §9 Change process

Must answer: what to do when placement succeeds · what to do when it fails · the bar for a new type · how the allowlist stays in sync · what to do when overturning an old conclusion.

On failure, require a "region application" answering a fixed set: which object is this a facet of / why won't an existing region hold it / does it empty / how much width does it need / what's the closest compromise if no new region is granted. Inability to answer means the requirement itself isn't thought through — that's not a layout problem.

Pin the sync order: **allowlist → type definition → code**, never reversed; and when document and code disagree, the code changes.

## §10 Anti-patterns

Three columns: don't | why | instead. **None of the three may be empty** — "don't do X" gets worked around; "don't do X, because it causes Y, do Z instead" gets followed.

Sources: every "don't do it that way" conclusion from the interview + every approach overturned during iteration + every place you nearly got it wrong yourself. This chapter grows over time, and that's healthy.

## Appendix A — Not decided by this spec

List the questions **explicitly out of scope** and where they belong instead (visual presentation, business logic, permissions, data model). This appendix limits damage: without it, an agent that can't find an answer here invents one.

## Appendix B — Overturned

Four columns: was | became | why overturned.

**Never delete when overturning a conclusion.**

This appendix is a **declared exception** to `decision-record`'s cut. By that rule "what was ruled out and why" is a decision and belongs in a decision record, not in the authoritative document; this appendix is claimed under the exception that skill states, and the reason for never deleting lives there. Do not resolve the apparent contradiction by moving this appendix out — that was considered and rejected, see Appendix C.

## Appendix C — Traces

The §1 verification, written down. Four columns: input | hostile or ordinary | where it landed | what the trace exposed.

Both kinds must be present. Hostile-only proves nothing about a tree that stops on everything; ordinary-only proves nothing about the holes. Requirements:

- **Every row names a leaf** — a region name from §2, or the explicit stop. "Roughly the inspector" is not a landing.
- **Record the traces that found something, not only the ones that passed.** A trace whose "what it exposed" column is empty on every row means either a perfect tree or a trace that was written after the fact to look like one, and a reader cannot tell which. The rows that changed the tree are the ones worth keeping.
- **When a trace lands on the stop but another chapter says the thing has a home, the tree is what's wrong** — fix the tree, then record both the finding and the fix here. Do not record a known hole and leave it.
- **Every pass carries its date and what triggered it** — "2026-08-21, after the row inserted into §1.1", not a bare date. Appending seats a superseded pass beside a current one: the date orders them, and only the trigger says which tree each was verified against. Without it the staleness the paragraph below permits stops being readable and becomes merely present.

This appendix goes stale as the tree changes, and that is acceptable: it is dated evidence of one verification pass, not a rule. Re-trace when the trunk changes, and append rather than rewrite.

Being "not a rule" is exactly why it is also a **declared exception** to `decision-record`'s cut, on the same footing as Appendix B — and it carries a second reason Appendix B does not. **Whether the verification happened at all is invisible in the output unless it leaves a trace here.** That was measured, not reasoned: six runs produced sound trees and sound fallbacks, and not one of them left a trace; nothing in the result disagreed. Moving the traces into a separate file has been proposed twice (it would let a judge grade trace *quality* on a short input) and rejected both times on this ground.

---

## Anti-patterns for writing this document itself

| Don't | Why | Instead |
|---|---|---|
| Long prose describing "what the interface looks like" | The code and the wireframe already show that; the document exists to answer "where does a new thing go" | Decision tree plus allowlist |
| Detailed "must hold" cells with "must not hold" left blank | That's a manual, not a spec | Fill in the forbidden cell on every row |
| Anti-patterns that only say "don't do X" | They get worked around | Add the reason and the replacement |
| **MUST** / **NEVER** everywhere with no reasoning | Today's models reason well — give them the why and they generalize to cases you didn't cover; give them only prohibitions and they follow the letter | One line of reasoning per rule |
| Color / font-size / spacing values | Duplication with the visual spec is a drift source | Reference "see visual spec §X" |
| Enumerating every page for completeness | It becomes a feature spec, and goes stale fast | Abstract into page archetypes |
| Naming two destinations without the criterion that picks between them ("it goes in A *or* B") | The reader guesses, and the guess is unauditable. This one migrates: make §1's leaves single-valued and it reappears in a chapter's admission rule, which is where it was last caught | One destination, or the question that decides. A chapter may point back at §1's branch instead of restating the criterion |
| Promising properties the design can't deliver | e.g. claiming "positions are stable, muscle memory works" when a sliding window guarantees they move | Promise only what holds, and write down explicitly what doesn't |
