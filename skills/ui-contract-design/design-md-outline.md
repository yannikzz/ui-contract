# design.md skeleton

Owns the **visual** layer: everything that changes when you swap the brand skin. No region tree, no column widths, no page archetypes — those live in `layout.md`.

**This document holds rules, not values.** Every colour, size, radius step and spacing step lives in the **token file**, the single value authority in code. Where a value is needed, write the token's name and "see the token file", never the literal. Same shape as `layout.md` holding no visual values: the cut hasn't moved, there is one more hop.

A worked table of steps is still a rule (it says *how many steps exist and what each is for*). A hex code, a px size, or a radius literal is a value, and it belongs in the token file.

If the project already has a visual spec, **do not rewrite it.** Do three things: add the division-of-labor statement, move structural content out, align region names with the allowlist. See the last section.

---

## Opening: division of labor with layout.md

Put a blockquote right under the title stating: what this document owns, what `layout.md` owns, that the cut is "does it change when the brand skin changes", that the two have zero overlap, that **this document contains no region tree and no column widths**, and that **the token file is the value authority — this document names tokens, it does not carry their values**.

Its purpose is that an agent reading either document knows where the other half is.

**When the project has no token file yet**, the blockquote states the gap instead of naming a file: the token file is the value authority, this project has none, the names below are written as they should be, and whoever builds it fills in the values. A pointer to a path that is not on disk reads as a stale spec; a stated gap reads as an honest one. See `SKILL.md` §When there is no token file yet.

The blockquote states the other half too: **this document is the name authority.** The token file holds values; which names exist is settled here. Without that sentence an external convention silently becomes the authority, and nothing in the output reveals it — a token file generated either way looks identical.

### The naming declaration

Directly under the blockquote, one line naming the convention followed and one table, **one row per token**. Machine-readable on purpose: the health check reads its whitelist out of this table, and it is the only part of this document any script parses.

> Naming follows: **shadcn core (19 names)** · see §Token names

| Token | Origin |
|---|---|
| `background` | borrowed |
| `foreground` | borrowed |
| `surface-sunken` | this project |
| `secondary` | not used — this product has one action level |

Three origins and no others: **borrowed** (in the list below), **this project** (invented here, follows the pairing rule), **not used** (in the list but deliberately absent, with the reason on the same row). A borrowed name that is not in the list, or a name in the token file with no row here, is drift — see `ui-contract-audit`.

⚠ **Those three keywords stay in ASCII, exactly as written, even when the rest of the document is in another language.** They are the only handle a script has on this table — the health check anchors on the keywords, not the header row, precisely so a spec in the user's language stays readable. Translate them and the check finds nothing and goes quiet: the right failure, but a silent one. Put the translation in the header row or beside the table.

This is the one place in this document where an English word is not a default to be localised. Say so beside the table, or the next person will helpfully translate it.

Keep the table flat. Nesting it by chapter is the first step toward maintaining it twice.

## Token names: what this document borrows

Token names are borrowed rather than invented, for one reason only: **the same concept keeps the same name across stacks.** Invent per project and the same surface is `muted` here and `subtle` there, and the asset layer needs a translation table for every stack it touches. That is the condition under which borrowing stops paying, and it is worth reopening then.

The borrowed set is shadcn's, minus two groups. It is identical word-for-word in shadcn/ui and shadcn-svelte, and that identity **is** the benefit:

```
radius
background / foreground
card(+ -foreground)      popover(+ -foreground)
primary(+ -foreground)   secondary(+ -foreground)
muted(+ -foreground)     accent(+ -foreground)
destructive
border   input   ring
```

**Two groups are deliberately not borrowed:**

| Dropped | Why |
|---|---|
| `sidebar-*` (8 names) | Information-architecture carriers. Shipping them hands every project a nav shape it never chose — the one prohibition `ui-contract-glossary` states most strongly |
| `chart-1..5` (5 names) | Data-visualisation colours. No chapter of this document covers charts |

### This list covers one and a half chapters, not the document

State this plainly rather than letting the borrowed list read as a skeleton:

| Chapter | Covered |
|---|---|
| §7 Radii | Fully — one base plus a derived scale |
| §2 surfaces table | Yes, except `disabled` |
| §2 text hierarchy | **Partly** — the list has two levels, this chapter needs four or five |
| §2 brand and semantic | **Partly** — the list has `destructive` only; success / warning / info are not in it |
| §3 · §4 · §5 · §6 · §8 | **Not at all** |

For every uncovered chapter, name the tokens this project needs and mark them `this project` in the declaration table. One rule governs those names:

> **Pairing.** A token naming a surface has a matching `-foreground` for the text and icons that sit on it. Add the surface, add the pair.

Follow the borrowed set's shape for anything adjacent to it — `success` / `success-foreground` beside `destructive`, not `colorSuccess`. Note that the borrowed set is **not itself consistent here**: `destructive` ships without a pair. Copy the rule, not that exception.

⚠ **The pairing rule is the one rule in this document with no automated check behind it.** A pairing check would fire a false positive on `destructive` the moment it ran. It is enforced by review only — do not read its absence from the health check's output as "it passed".

## §1 Design philosophy

Roughly three core principles, each a one-sentence claim plus two or three sentences of elaboration. Good principles can be used to **judge new situations**, not just describe the current one.

Test: take a component the spec doesn't cover and hold it against the three principles — can you derive how it should look? If not, the principles are too vague to be useful.

**Where a generated brand lands.** When the brand came from `originate` rather than from the project, the chosen attribute direction is recorded here — the direction as the user picked it, and the cost that was stated alongside it. Not in a separate log: a decision that lives beside the rules it produced is the only one that gets re-read when those rules are questioned.

**Firmness markers.** Each clause may carry how hard it currently is:

| | Means | Consequence |
|---|---|---|
| 🔒 | Settled, from fact | May enter a union type or a hard stop |
| 🌡 | Provisional, from assumption | Document only, and it names its revisit condition |
| ✏ | Undecided | Goes in the "not decided here" appendix, not the body |

A generated brand is 🌡 by default — it is a hypothesis until real users have seen it. So is a borrowed naming convention: it came from another project, not from this one's structure. Marking them 🔒 claims a certainty nobody measured.

## §2 Color

Three tables:

- **Surfaces and layers**: background / card face / fill levels / disabled. This table defines spatial hierarchy.
- **Borders — one width, an enumerated set of levels.** See below; it is not a row in the surfaces table.

### Borders need their own section, and this is measured

Left inside the surfaces table, borders get one or two entries and no rules — and the
implementation then invents the rest. Measured on a real wireframe: the visual spec declared
**two** border levels and the wireframe was using **six**, three of which no token mapped at
all. With the skin preview on those three stayed wireframe grey, so the interface rendered as a
half-broken theme rather than as a missing decision. **Where there is no spec, the
implementation writes one.**

The section answers three things:

| | |
|---|---|
| **Width** | Pick one and say so. A second width is a second signal, and nobody ever defines what it means — it gets read as "more important" and spreads to everything anyone wants to emphasise. Need a stronger separation? Move a level, do not widen |
| **Levels** | An enumerated set, each with **its use sites** and a reason it exists that the others do not cover. Two is usually too few: a border drawn on a filled surface disappears at the hairline level, and that is a third job, not a preference |
| **Prohibitions** | No further level (want one? ask first whether you mean *hierarchy* — that belongs to surface contrast, not to borders), and no second width |

⚠ **The implementation's level count must equal this section's.** A wireframe with more roles
than the spec has levels is inventing spec; `check-colours.sh` check 3 reports roles that were
never mapped, which is how the six-versus-two above was found.
- **Text hierarchy**: **cap it at 4–5 levels and write "no adding a further level" explicitly**. State each level's use, what distinguishes adjacent levels, and which way round they go.
- **Brand and semantic colors**: for each, its meaning and an **enumerated set of use sites**.
- **Semantic class → token**, if the product has status labels. One row per class. The **classes**
  themselves are not defined here — they are structural (they do not change when the brand does),
  so they live in the structural spec and this table only says which token each one uses.

  Without that split the implementation has two bad options: paint every status the same grey —
  in which case the skin preview shows almost nothing on a product whose visual life is its status
  column — or invent a status→colour table of its own, which is a second authority. Measured: the
  first one, on a review queue, where turning the preview on changed one button and one nav row.

The rules that actually keep an interface from getting muddy:

- **The brand color appears only at the enumerated sites** (typically: the single primary action per screen, the current selection, one specific state). The moment it's used decoratively, the "clickable / in motion" signal is dead.
- **Semantic colors carry state only**, with area limited to small labels / status dots / low-opacity tints. Never wash a whole card, row, or large button in a semantic color.
- If there are two similar brand colors (one for filled surfaces, one for inline text), **state that they are not interchangeable** or they will be mixed up.
- If dark mode isn't designed yet, mark it "to be confirmed", give a derived mapping, and state one principle (usually: preserve the same spatial hierarchy rather than inverting).

**The contrast threshold is a rule, so it lives here — once.** State the minimum ratio for body text on its background (4.5:1 unless this project has a reason for more), and state it in exactly one place. Two consumers read it from here: the value-tuning instrument checks it live while the user is turning knobs, and the health check re-checks it months later after somebody hand-edited the token file. Neither hardcodes it — they cannot even share code (one is an HTML template, the other a shell script), so this document is the only thing they can share.

Two things about that pair of consumers, both learned the hard way:

- **They must agree on what counts as a pair.** `X` with `X-foreground`, *and* the base pair — `background` (or `page` / `surface`) with `foreground` (or `text`), which is the pair this threshold is actually written for and the one the first rule cannot see, because the base foreground is not called `background-foreground`. The instrument had that case; the health check did not, so a token file with `background` and `foreground` both `#ffffff` — the worst contrast that exists — cleared the health check and failed the instrument, with nothing reporting a disagreement. Both carry the rule now, and an invariant compares the two name lists.
- **A translucent value has no ratio.** What it looks like depends on whatever is painted behind it, and neither tool knows the stack. Both say so rather than answering about the opaque version of the colour — a checker that returns a plausible wrong number is worse than one that returns none.

## §3 Type

- **Families**: body/UI, monospace, fallback chain. If stray families crept into the mockup, state plainly that it's an oversight and is to be corrected everywhere.
- **Size scale**: about five steps, each with its role and use sites; the peak step gets a "at most N per screen" limit. Write the hard rule: **no arbitrary pixel sizes**, and a new size must enter the table before it enters code.
- **Weights**: three or four steps. Designate the **single** weight allowed for certain elements (small status labels, for instance, where weight is what carries legibility).

## §4 Spacing

A base grid (usually 4px) plus a spacing-semantics table: each step maps to a **relationship** (tightly bound / same group different item / within a subsection / between groups / block padding). Spacing carries information; it isn't nudged by feel.

List the permitted half-steps explicitly by **token name**; everything else is forbidden. Name and converge the drift values that recur in the mockup (`9px` / `7px` / `14px` and friends) — the converged result becomes a token, and this chapter references it.

**This chapter contains the scale's semantics, never the region tree and never the literals.** Per-region padding may be tabulated by token name, but structural relationships belong to `layout.md` and the numbers belong to the token file.

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
1b. **Move values out to the token file.** Every literal in the normative body becomes a token reference. Which file that is, `ui-contract-design` states — not restated here. If the project has none, **say so in the document as well as to the user**, and write no path to a file that isn't there.
2. **Move structural content out**: find the sections that describe region trees, column widths, page archetypes; move the structure into `layout.md`, leaving behind only spacing/feel values plus a one-line "structure: see layout.md §X". Rename the section too if its title promised structure ("Layout skeleton" → "Skeleton spacing and feel").
3. **Align region names with the allowlist**: replace old component-style names (camel-cased widget names) with allowlist names. This step is easy to half-finish — grep out every old name and replace them one by one, touching **only the normative body**; leave mockup-reality appendices as they are.
4. Report to the user afterwards: which sections you touched, how many region names you replaced, and what you deliberately left alone.
