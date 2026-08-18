# design.md skeleton

Owns the **visual** layer: everything that changes when you swap the brand skin. No region tree, no column widths, no page archetypes — those live in `layout.md`.

If the project already has a visual spec, **do not rewrite it.** Do three things: add the division-of-labor statement, move structural content out, align region names with the allowlist. See the last section.

---

## Opening: division of labor with layout.md

Put a blockquote right under the title stating: what this document owns, what `layout.md` owns, that the cut is "does it change when the brand skin changes", that the two have zero overlap, and that **this document contains no region tree and no column widths**.

Its purpose is that an agent reading either document knows where the other half is.

## §1 Design philosophy

Roughly three core principles, each a one-sentence claim plus two or three sentences of elaboration. Good principles can be used to **judge new situations**, not just describe the current one.

Test: take a component the spec doesn't cover and hold it against the three principles — can you derive how it should look? If not, the principles are too vague to be useful.

## §2 Color

Three tables:

- **Surfaces and layers**: background / card face / borders / fill levels / disabled. This table defines spatial hierarchy.
- **Text hierarchy**: **cap it at 4–5 levels and write "no adding a further level" explicitly**. State each level's use, what distinguishes adjacent levels, and which way round they go.
- **Brand and semantic colors**: for each, its meaning and an **enumerated set of use sites**.

The rules that actually keep an interface from getting muddy:

- **The brand color appears only at the enumerated sites** (typically: the single primary action per screen, the current selection, one specific state). The moment it's used decoratively, the "clickable / in motion" signal is dead.
- **Semantic colors carry state only**, with area limited to small labels / status dots / low-opacity tints. Never wash a whole card, row, or large button in a semantic color.
- If there are two similar brand colors (one for filled surfaces, one for inline text), **state that they are not interchangeable** or they will be mixed up.
- If dark mode isn't designed yet, mark it "to be confirmed", give a derived mapping, and state one principle (usually: preserve the same spatial hierarchy rather than inverting).

## §3 Type

- **Families**: body/UI, monospace, fallback chain. If stray families crept into the mockup, state plainly that it's an oversight and is to be corrected everywhere.
- **Size scale**: about five steps, each with its role and use sites; the peak step gets a "at most N per screen" limit. Write the hard rule: **no arbitrary pixel sizes**, and a new size must enter the table before it enters code.
- **Weights**: three or four steps. Designate the **single** weight allowed for certain elements (small status labels, for instance, where weight is what carries legibility).

## §4 Spacing

A base grid (usually 4px) plus a spacing-semantics table: each step maps to a **relationship** (tightly bound / same group different item / within a subsection / between groups / block padding). Spacing carries information; it isn't nudged by feel.

List the permitted half-steps explicitly; everything else is forbidden. Name and converge the drift values that recur in the mockup (`9px` / `7px` / `14px` and friends).

**This chapter contains values only, never the region tree.** Per-region padding may be tabulated, but structural relationships belong to `layout.md`.

## §5 Interaction states

The ladder: rest → hover → pressed → selected → focused → disabled.

One row per element type, with effect and token. Key rules:

- **Hover is always lighter than selected**, and selected carries one more visual dimension than hover (color plus weight, or color plus fill).
- **Handle the "selected + hover" compound explicitly.** Without it, hovering an already-selected item makes the selection visibly downgrade — the most common implementation bug here, worth its own subsection with a correct and an incorrect example.
- Pressed uses a slight scale, stepped by element size; no enlarging feedback.
- Focus rings use a mechanism that only appears for keyboard navigation, so mouse clicks don't trigger them.

## §6 Icons and avatars

Name one icon library; no mixing. Cap icon sizes at three or four steps. Identity marks (avatars, tiles) are a **separate scale** — don't blend them with icons. State the radius for each.

Add one rule: identity marks are distinguished by their graphic, not by background color — coloring each identity by function is the fastest route to a garish interface.

## §7 Radii

A step table: value | use. Principle: **the larger the container, the larger the radius**; the top step belongs to top-level containers only, never to inner blocks.

Hard rule: an arbitrary radius must enter the table first; no writing off-table values in feature code.

## §8 Motion

Principles (fast, restrained, predictable) plus a duration table (scenario → duration) plus the list of permitted transition classes.

If the product has state transitions (queued → running → done), require that **state color changes go through a transition** — an instant switch makes users doubt what they saw.

## §9 Component usage

- Component sourcing priority (check the existing library first → extend via variants → build last).
- **Button hierarchy**: variants from strongest to weakest with visual weight, styling, and use sites, plus a hard "at most N of the strongest per view".
- Components that must be absolutely consistent (status labels and the like) get their own section: give the **single specification**, declare that only color varies, and forbid changing geometry, adding borders, adding icons, or changing size.
- Distinguish shapes that look similar but mean different things (small square-cornered labels versus pills) and state that they are not interchangeable.

## §10 Anti-patterns

Three columns: don't | why | instead. None may be empty.

Sources: problems already visible in the mockup, plus the shortcuts implementers reach for (shadows everywhere, casual gradients, skeleton screens, transient toasts used as action confirmation).

## §11 Checklist

Grouped tick items (structure / color / type / spacing and shape / states / other) to run before submitting any UI change. Phrase them so they can be checked mechanically — not "is it attractive".

## Appendix — Mockup reality → spec value mapping

Where spec values differ from the mockup (they nearly always do), list: mockup's actual value | occurrences | spec value | where to correct.

**This appendix records mockup facts, not the spec.** It serves two purposes: telling developers which column to implement, and telling designers what to fix. **Do not touch it when aligning region names** — it references layer names from the mockup.

Also flag which of the converged items **actually change how things look**, and recommend a separate design sign-off for those.

---

## When a visual spec already exists (start C)

1. **Add the division-of-labor statement** (see Opening). Change nothing else yet.
2. **Move structural content out**: find the sections that describe region trees, column widths, page archetypes; move the structure into `layout.md`, leaving behind only spacing/feel values plus a one-line "structure: see layout.md §X". Rename the section too if its title promised structure ("Layout skeleton" → "Skeleton spacing and feel").
3. **Align region names with the allowlist**: replace old component-style names (camel-cased widget names) with allowlist names. This step is easy to half-finish — grep out every old name and replace them one by one, touching **only the normative body**; leave mockup-reality appendices as they are.
4. Report to the user afterwards: which sections you touched, how many region names you replaced, and what you deliberately left alone.
