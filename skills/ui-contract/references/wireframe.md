# Wireframe implementation guide

The wireframe is the spec's **reference implementation and physical exam**. It is not product code, and it is not another round of exploring options.

Its only purpose: give coding agents a runnable reference for "where the regions sit, and what may go in each", and to force the spec's holes into the open while you build it.

---

## Visual discipline

| Do | Don't | Why |
|---|---|---|
| Neutral greys, system font | Brand colors, brand fonts, real shadows, real radius steps | A skeleton carrying brand visuals becomes a **second source of visual truth**. Once the visual spec changes, the skeleton is a stale spec — and agents trust the code in front of them |
| One uniform grey for every status label | Coloring by semantics | The wireframe only expresses "a status label goes here". Color semantics belong to the visual spec |
| Buttons differentiated only by grey depth | Real button styling | Hierarchy belongs to the wireframe; specific styling belongs to the visual spec |
| **Real copy, real row counts, real depth** | Lorem, three placeholder rows | An empty interface makes any layout look fine. Density is what exposes problems: columns that don't fit, long strings that break, parallel items crushed together |
| Zero business logic; clicking does nothing | Wiring data, building state machines | This exists to verify structure and placement |

Push density to the **realistic ceiling**: if the product might have six parallel items, five states, and one blocked checkpoint at once, the fixtures should contain all of it.

---

## Directory layout

```
<wireframe>/
├── CLAUDE.md          Directory-level constraints + the deliberate-tradeoffs list
├── README.md          How to run it, what each toggle verifies, why it's grey
└── src/
    ├── wire.tsx       Region allowlist (union type) + region metadata + neutral parts
    ├── fixtures.ts    Fake data (header says "not a spec")
    ├── App.tsx        Shell + archetype routing + real degradation math + demo toggles
    └── pages/*.tsx    One file per page archetype
```

`assets/wire.tsx.template` is the starting point for `wire.tsx` — copy and adapt.
`examples/admin-console/` is a complete, type-checked instance of all of this if you want to see the finished shape.

One environment gotcha worth pre-empting: pnpm 10+ blocks postinstall scripts, so a Vite project needs `allowBuilds: { esbuild: true }` in `pnpm-workspace.yaml` or the install fails and you never reach type-checking.

---

## The three enforcement layers, in code

### 1. Allowlist → union type

```ts
export type RegionId = 'app-shell' | 'nav' | 'main' | 'main.list' | ...
```

The `Region` component's `id` parameter is typed `RegionId`. Writing a name that isn't in the table fails type-checking. That isn't a documented convention; it's a compile-time constraint.

Sync order: **change `layout.md` §2 → change `RegionId` → write code.** Never reversed.

### 2. Hand other hard rules to the type system too

Wherever the spec says "region X must not hold things of kind Y", **delete Y from the corresponding union type**.

Example: if the spec says "the content stream must not hold action buttons", make sure the content-block union has no "card with buttons" variant at all — then a violation is unwritable. Put a comment next to the omission stating it is **deliberate**, or the next agent will assume something is missing and add it back.

This beats any `MUST` you could write, and costs less than a lint rule.

### 3. Region metadata → the annotation layer

A `Record<RegionId, { label: string; desc: string }>`: human-readable name plus responsibility.

`desc` says **what goes here / what must not** — not "what this is", which is visible from the screen. **A wrong description is more dangerous than wrong code**, because agents extend from it.

That gives the allowlist three forms, each with its own reader:

| Form | Where | For |
|---|---|---|
| Table (responsibility / must hold / must not hold) | `layout.md` §2 | Humans and agents reading |
| Union type | `wire.tsx` | The compiler |
| Metadata (label + description) | `wire.tsx` | The annotation layer — humans reading it on screen |

Put a line at the top of `layout.md` §2: changing this table requires changing both of those.

---

## Region markers on non-web platforms

On the web, use `data-region="..."`. React Native, Flutter, native — platforms without DOM attributes — **must find an equivalent; a type with no runtime marker is not enough**, or the allowlist and what actually renders come apart, and the annotation layer has nothing to hook into.

The React Native approach: `Region` writes the id into both `testID` and `accessibilityLabel`, **identical to the `RegionId` value** (don't invent a more readable name — identical strings are what make grep reconciliation possible). Debuggers and automated tests can then locate things by region name.

Whatever the equivalent, this check must pass: **grep every allowlist region name in the code; every one must be found.** A region that isn't found exists only in the document.

---

## Annotation layer

By default float a small badge at each region's top-left showing the **human-readable module name**; hovering the badge reveals the code name and the responsibility.

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

1. Put the structural parameters (column widths, minimum usable width, gutters) as named constants in one place, with a comment pointing at the corresponding section of `layout.md` and a note that **changing these constants changes the spec** and requires syncing the document.
2. Measure the container with `ResizeObserver`; don't use viewport breakpoints.
3. Write the degradation decision as a **pure function**: inputs are width plus user preference, outputs are each column's collapsed state and the main area's actual width. Only a pure function makes the cascade order legible at a glance — and reviewable against the spec.
4. User preference must override automatic degradation in both directions (collapsed by hand stays collapsed when space returns). Represent it as a three-state preference: `auto | open | closed`.
5. **Display the live computation on screen** (current width / main-area width / threshold / which degradations fired). That lets the rule be verified against numbers instead of by feel.

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

1. **What this is**: the reference implementation of a named spec; a low-fidelity wireframe; not product code.
2. **Before you touch anything** (not skippable): which document and sections to read; walk the decision tree; stop if it doesn't land; every region must use `Region` with an id from the allowlist; the order for adding a region.
3. **The deliberate-tradeoffs list** — a two-column table: current state | this is deliberate. Its job is to **stop the next agent from "fixing" things left out on purpose**. Include at least: no brand visuals, uniform status label color, buttons only differentiated by grey, dense fixtures, clicking does nothing, degradation measured rather than breakpointed — plus anything the spec explicitly forbids that looks like an omission on screen.
4. **The single source for structural parameters**: which file, and that changing it changes the spec.
5. How to run it, plus the type-check command (noting that allowlist validation happens right there).

---

## The no-tooling escape hatch

If the user insists on single-file HTML (zero install, double-click to view), do it — but **state plainly what they give up**:

- The allowlist becomes human-honor-system only, with no compile-time interception — and that is the most effective anti-drift mechanism available
- Component decomposition and slots can't be expressed, and extension slots are the core of the spec

Middle ground: keep `data-region` on every region in the single-file HTML, and add a validation script that scans attribute values against the allowlist. Better than nothing, weaker than the type system: a script has to be run deliberately, whereas type-checking is part of the build.

---

## Wrapping up

**Install dependencies, run type-checking, run the build, and paste the real output.** Allowlist validation happens during type-checking — skipping it means the compile-time layer isn't in force, and the code may not even compile.

Then reconcile by grep once more: every allowlist region name is findable in the type definition, the metadata table, and the actual code.

Then start the dev server for the user.

**State honestly what you verified and what you didn't.** You usually have no tool that can look at a web page, so "does the layout break, does the density look right" is beyond you — say so, and give a "verify these specific things" list for the user to check. If the environment can't install dependencies, say explicitly that the compile-time layer is unverified and needs a local run. Never let "done" cover for "never looked at it".
