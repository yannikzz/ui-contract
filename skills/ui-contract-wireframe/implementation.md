# Wireframe implementation guide

The wireframe is the spec's **runnable reference implementation**, and building it is what forces the spec's holes into the open. It is not product code, and it is not another round of exploring options.

Its only purpose: give coding agents a runnable reference for "where the regions sit, and what may go in each".

---

## Visual discipline

| Do | Don't | Why |
|---|---|---|
| Neutral greys, system font | Brand colors, brand fonts, real shadows, real radius steps | A skeleton carrying brand visuals becomes a **second source of visual truth**. Once the token file changes, the skeleton is a stale spec — and agents trust the code in front of them |
| One uniform grey for every status label | Coloring by semantics | The wireframe only expresses "a status label goes here". Color semantics belong to the visual spec |
| Buttons differentiated only by grey depth | Real button styling | Hierarchy belongs to the wireframe; specific styling belongs to the visual spec |
| **Real copy, real row counts, real depth** | Lorem, three placeholder rows | An empty interface makes any layout look fine. Density is what exposes problems: columns that don't fit, long strings that break, parallel items crushed together |
| Zero business logic; clicking does nothing | Wiring data, building state machines | This exists to verify structure and placement |

Push density to the **realistic ceiling**: if the product might have six parallel items, five states, and one blocked checkpoint at once, the fixtures should contain all of it.

The asset layer already carries the project's brand through the token file. The wireframe **overrides it to neutral** — that is the point of the split, not an oversight to fix.

---

## Directory layout

```
<wireframe>/
├── CLAUDE.md          Directory-level constraints + the deliberate-tradeoffs list
├── README.md          How to run it, what each toggle verifies, why it's grey
└── src/
    ├── wire.tsx       AnnotatedRegion + neutral parts. Imports RegionId / Region / REGION_META
    │                  from the asset layer — never redefines them
    ├── structure.ts   Structural parameter constants + the degradation pure function
    ├── fixtures.ts    Fake data (header says "not a spec")
    ├── App.tsx        Shell + archetype routing + demo toggles
    └── pages/*.tsx    One file per page archetype
```

`assets/wire.tsx.template` is the starting point for `wire.tsx` — copy and adapt.

**The allowlist is not defined here.** `RegionId`, `REGION_META` and the bare `Region` container live in the asset layer, in the project's production tree. If you find yourself declaring a region name inside the wireframe, stop — that inverts the dependency and gives the project two allowlists.

**Known temporary inversion:** `structure.ts` (parameter constants + degradation function) belongs to the asset layer conceptually, but the asset layer does not yet ship a `Shell`. For now it lives in the wireframe. Say so in the directory `CLAUDE.md` so nobody mistakes the current location for the intended one.

One environment gotcha worth pre-empting: pnpm 10+ blocks postinstall scripts, so a Vite project needs `allowBuilds: { esbuild: true }` in `pnpm-workspace.yaml` or the install fails and you never reach type-checking.

---

## Annotation layer

By default float a small badge at each region's top-left showing the **human-readable module name**; hovering the badge reveals the code name and the responsibility.

This layer lives **only** in the wireframe. Production code renders through the asset layer's bare container; the wireframe wraps it with `AnnotatedRegion`.

### The tooltip must be portalled out

**z-index cannot fix this cleanly.** An ancestor's `overflow-hidden` clips regardless of z-index, and nearly every card in a wireframe has `overflow-hidden`.

The correct approach: render the tooltip into `document.body` (a portal) with `position: fixed` and a high z-index. It is then neither clipped nor competing in the prototype's stacking contexts.

That also solves two more problems:
- **Flip direction computed from real viewport space** (open upward when there isn't room below) — don't maintain a hand-written list of "which regions open upward"; that treats the symptom.
- **Clamp horizontally to the viewport**, so tooltips on edge regions don't run off screen.

### Known traps

| Symptom | Cause | Fix |
|---|---|---|
| Text overflows the tooltip box | `white-space: nowrap` on the badge **inherits** into the tooltip | Explicitly restore wrapping on the tooltip (portalling also takes it out of the inheritance chain) |
| Tooltip hidden behind components | Clipped by an ancestor's `overflow-hidden` | Portal + fixed |
| A badge inside a scroll container scrolls away | Absolutely positioned within scrolling content | Acceptable minor flaw; note it in the README. Fixing it means wrapping the scroll container — more cost than value |
| Nested regions' badges overlap slightly | The layers genuinely nest | Unavoidable in inspect mode; just note it |

---

## Implement the degradation rules for real

If the spec has size-degradation rules, **implement them; don't leave them in the document** — a rule in a document never gets verified.

How:

1. Put the structural parameters (column widths, minimum usable width, gutters) as named constants in **one place**, with a comment pointing at the corresponding section of `layout.md` and a note that **changing these constants changes the spec** and requires syncing the document.
2. Measure the container with `ResizeObserver`; don't use viewport breakpoints.
3. Write the degradation decision as a **pure function**: inputs are width plus user preference, outputs are each column's collapsed state and the main area's actual width. Only a pure function makes the cascade order legible at a glance — and reviewable against the spec.
4. User preference must override automatic degradation in both directions (collapsed by hand stays collapsed when space returns). Represent it as a three-state preference: `auto | open | closed`.
5. **Display the live computation on screen** (current width / main-area width / threshold / which degradations fired). That lets the rule be verified against numbers instead of by feel.

Handle the first-frame case: before `ResizeObserver` reports, the measured width is 0. Return the un-degraded state for that frame, or the interface flashes its collapsed form once on load.

---

## Demo toggle bar

Placed outside the window (it isn't part of the product interface). At minimum:

- **Archetype switch** — verifies which shell parts are present per archetype
- **Key state switch** — for every place the spec defines states
- **Width clamp** (a few steps) — verifies the degradation cascade
- **Overlay toggle** (if there is one)
- **Annotation toggle**
- **Live data row** — current width, main-area width, threshold, degradations fired, user preference state

Give the README a "toggle → what it verifies" table. That table is how the user reviews the work; don't make them guess.

---

## Directory-level CLAUDE.md

Must contain:

1. **What this is**: the reference implementation of a named spec; a low-fidelity wireframe; not product code; a **consumer** of the asset layer.
2. **Before you touch anything** (not skippable): which document and sections to read; walk the decision tree; stop if it doesn't land; every region must render through `AnnotatedRegion` with an id from the allowlist; the order for adding a region (spec → asset layer → here).
3. **The deliberate-tradeoffs list** — a two-column table: current state | this is deliberate. Its job is to **stop the next agent from "fixing" things left out on purpose**. Include at least: no brand visuals (the asset layer's brand is deliberately overridden), uniform status label color, buttons only differentiated by grey, dense fixtures, clicking does nothing, degradation measured rather than breakpointed — plus anything the spec explicitly forbids that looks like an omission on screen.
4. **The single source for structural parameters**: which file, that changing it changes the spec, and that it is expected to move to the asset layer later.
5. How to run it, plus the type-check command.

---

## Wrapping up

**Install dependencies, run type-checking, run the build, and paste the real output.** For why this isn't optional, call the Skill tool with "constraint-by-types".

Then reconcile by grep: every allowlist region name is findable in the asset layer's type definition, its metadata table, and the actual wireframe code.

Then start the dev server for the user.

**State honestly what you verified and what you didn't.** You usually have no tool that can look at a web page, so "does the layout break, does the density look right" is beyond you — say so, and give a "verify these specific things" list for the user to check. Never let "done" cover for "never looked at it".
