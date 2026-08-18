# layout.md skeleton

Ten chapters plus two appendices. Chapters can be merged or renamed, but **no chapter's question may be dropped** — each missing chapter is one more category of thing agents will invent for themselves.

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

1. **Short-circuits** (3–5) — the cases where the answer is obvious; catch them first. Typically: process events, long content that needs width, action buttons.
2. **The trunk** (4–6 questions) — drawn as an ASCII tree, where every leaf is a **specific region name**, not a description.
3. **What to do when nothing matches** — write "stop" explicitly, and point to §9. That sentence matters more than the whole tree: without it, an agent picks the closest-looking region and stuffs the thing in.
4. **A reverse checklist** — "if you're about to do any of the following, you've already gone off course" — 4–6 of the most common overreaches.

Ordering principle for the trunk: **the most discriminating question goes first.** Usually that's "is this a facet of a first-class object", because it immediately separates "goes in the focus slot" from "goes in the nav".

## §2 Region-name allowlist

Must answer: which region names are legal · what each region holds · **what it must not hold**.

Four columns: region name | responsibility (one line) | must hold | must not hold. Add a fifth for size constraints where they exist.

Requirements:

- **The "must not hold" column cannot be empty.** Listing only what goes in is documentation; stating what must not is a spec. Forbidden entries come from every "don't make it X" conclusion in the interview.
- Spell out the naming convention (case, separator for nesting, maximum depth), and guarantee the **same name appears identically in the document, the type definition, and the code**.
- At the end of the table, point at its code forms (the union type plus the human-readable metadata) and state that **changing this table requires changing those too**.

## §3 Shell skeleton

Must answer: what the region tree looks like · what's fixed and what's elastic · how it degrades as space shrinks · how many context/session forms exist.

Draw the region tree as ASCII, annotating fixed sizes and elasticity. After the tree, write 2–4 **key structural facts** — the things that **can't be seen from the picture but change the extension rules** (a bar that spans several columns; two elements that look aligned but belong to different layers).

The degradation subsection covers: the trigger (minimum usable size, not viewport breakpoints), the collapse order, **what remains after collapse**, and **who wins between a manual toggle and automatic degradation** (recommend the user, in both directions).

If the product's context has multiple forms (shared space versus private space, containers at different levels), give it its own section: the hierarchy of each, its boundary, its unit of division — and **explicitly distinguish any two similar concepts**, or agents will conflate them.

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

## §7 Navigation admission rules

Must answer: how many segments · each segment's distinguishing feature · each segment's badge rule · what doesn't belong in the nav at all.

Spell out **the consequence of putting something in the wrong segment** — one per segment, specific about what will happen. Cap the "never empties" segment and explain that the cap's job is to force a consolidation decision.

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

**Never delete when overturning a conclusion.** Overturned judgments are easier to re-tread than current ones, because they look reasonable (they looked reasonable to you too, once).

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
| Promising properties the design can't deliver | e.g. claiming "positions are stable, muscle memory works" when a sliding window guarantees they move | Promise only what holds, and write down explicitly what doesn't |
