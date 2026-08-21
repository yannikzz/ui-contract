# Wireframe implementation guide

The wireframe is the spec's **runnable reference implementation**, and building it is what forces the spec's holes into the open. It is not product code, and it is not another round of exploring options.

Its only purpose: give coding agents a runnable reference for "where the regions sit, and what may go in each".

---

## Visual discipline

| Do | Don't | Why |
|---|---|---|
| Neutral greys by default, system font | **Colour *values* anywhere but the `NEUTRAL` map** | The rule is no colour **values** here, not no colour. A skeleton carrying its own brand values becomes a second source of visual truth; one that reads them live from the token file cannot go stale. See ADR-0006 |
| One uniform grey for every status label | Coloring by semantics | The wireframe only expresses "a status label goes here". Color semantics belong to the visual spec |
| Buttons differentiated only by grey depth | Real button styling | Hierarchy belongs to the wireframe; specific styling belongs to the visual spec |
| **Real copy, real row counts, real depth** | Lorem, three placeholder rows | An empty interface makes any layout look fine. Density is what exposes problems: columns that don't fit, long strings that break, parallel items crushed together |
| Zero business logic; clicking does nothing | Wiring data, building state machines | This exists to verify structure and placement |

Push density to the **realistic ceiling**: if the product might have six parallel items, five states, and one blocked checkpoint at once, the fixtures should contain all of it.

The asset layer already carries the project's brand through the token file. The wireframe **defaults to neutral** — that is the point of the split, not an oversight to fix.

---

## Skin preview

The one thing the tuning instrument cannot give the user: **this product's real information architecture wearing the skin.** The instrument shows generic controls at real density; only the wireframe shows their actual screens. So the preview belongs here.

It was excluded once, and overturning that took ADR-0006 — read it before changing any of the four rules below, because they only work together.

| # | Rule | What it stops |
|---|---|---|
| 1 | All colour goes through `--wire-*` custom properties. **Values exist in exactly one place** (`NEUTRAL` in `wire.tsx`), and they are the wireframe's own greys. **This covers the whole directory, not just `wire.tsx`** | Any brand value living here |
| 2 | Preview **reads the token file at runtime** — `import` it, never copy it | Values splitting in two, the skeleton going stale |
| 3 | **Off by default, and not persisted.** Every reload is grey | "Six months on nobody remembers it defaults to off" |
| 4 | While on, an **undismissable banner** naming the token file and saying not to copy from here | The screenshot. Default-off cannot reach an agent looking at a picture; the banner travels with it |

Rule 4 is aimed at the exact failure ADR-0001 named. Do not make it dismissible, and do not shrink it into a corner badge.

**Inspect chrome does not follow the skin** — the annotation badges, the region outline, the tooltip, and the banner itself. They are apparatus, not product surfaces, and they carry fixed colours inside the `INSPECT CHROME` markers in `wire.tsx` (the one block `tests/structure.sh` exempts).

Two different reasons, both measured:

- A tooltip tinted by the theme it describes stops being able to describe it.
- **A banner tinted by the values it warns about can vanish.** The first version painted it with `--wire-strong` / `--wire-strong-fg`; map those to a pale brand colour and it is white on white. The guard disappears precisely where the theme makes it hardest to notice. **A warning may not depend on what it warns about.**

**A role with no token stays neutral.** `SKIN` ships empty and the agent fills it from `design.md`'s declaration table — the same table the tuning instrument reads. An unmapped role simply does not change. Do not invent a value to fill the gap; that is the failure the whole split exists to prevent.

### Rule 1 covers every file, and this is where it is easy to get wrong

Measured on a real wireframe: `wire.tsx` held 17 hardcoded colour classes, and **`App.tsx`, `Inspector.tsx` and the four `pages/*.tsx` held about 140 more.** `wire.tsx` was never the only place colour lives — the page files paint directly.

Convert all of them. Skip the page files and the preview skins only the parts that happen to route through a `wire.tsx` component, which looks like a half-broken theme rather than like a bug.

⚠ **Nothing checks this in a user's project.** `tests/structure.sh` asserts rule 1 on the template shipped with this skill; the generated wireframe is not in that repo, and `ui-contract-audit` does not look at the wireframe directory at all (it audits the production tree). So on a real project rule 1 is enforced by review only. Do not read a green health check as "no colour leaked into the wireframe".

### The preview is editable, and the output is a prompt

Only the wireframe shows this product's real IA, so it is the only place where "that is wrong at this density" can be both noticed **and** acted on. `SkinEditor` gives every mapped token a field; `useSkin` keeps the edits in memory.

| | Instrument (`design` step) | Wireframe (`wireframe` step) |
|---|---|---|
| Does it exist yet | Yes — the wireframe does not | Yes |
| Shows | Generic controls | **This product's real IA** |
| Writes | `tokens.input.json` — **its only writer** | Nothing |
| Output | The JSON | A prompt, handed to an agent |

Because the instrument is the JSON's only writer, two open editors cannot overwrite each other. That is a consequence of this split, not its purpose.

**The prompt carries exact old → new values**, and **token names rather than `--wire-*` roles** — the agent edits `tokens.input.json`, whose keys are token names, and `design.md` is the name authority. Without exact values the agent's application is a guess and the JSON's diff stops meaning anything.

**The prompt must never invent a change.** Measured: opening the native colour picker and closing it rewrites `oklch(0.47 0.15 258)` as `#1a57ad` — same colour, different notation. Report that and an agent will quietly convert the project's colour space to hex. So a change counts only when the two values resolve differently; the dirty marker and the prompt's list share one comparison, because two comparisons eventually disagree and the panel starts saying one thing while the prompt says another.

A prompt that invents changes is worse than no prompt: it is the only carrier of the user's intent in this whole path.

⚠ **Two costs, both deliberate, neither to be papered over** (ADR-0007):

- **The hop is unrecorded.** "Turned a knob here" → "the JSON changed" goes through an agent. The v1↔final diff that ADR-0001 决定 B hangs its revisit condition on cannot tell a user's choice from an agent's misreading.
- **Nothing remembers the edits.** No storage, no writes — close the tab and they are gone. Accepted because the alternative, a wireframe that remembers values, is a second value authority.

Say both out loud when handing the wireframe over. A user who does not know the edits are volatile will lose work.

### Control surfaces are not skinned either

Three things needed this exception, and they are one rule, not three:

> **Anything you use to control or interpret the wireframe must stay readable no matter what the skin does — so it must not follow the skin.**

| Surface | What breaks if it follows the skin |
|---|---|
| Annotation badges, region outline, tooltip | A tooltip tinted by the theme it describes cannot describe it |
| The skin banner | A warning tinted by the values it warns about can vanish |
| **The demo toggle bar** (including its `Sw` / `Group` helpers) | **The control that turns the skin off becomes unreadable — you are stuck in it** |
| The skin editor panel | Same as the toggle bar: the fields you fix a bad theme with must survive that theme |

The third one was found by converting a real wireframe and watching the toggles change colour. `Sw` and `Group` sit at the bottom of `App.tsx`, well past the product markup, so a "convert everything below the product marker" pass takes them with it. Keep them hard-coded.

Rule 1 is asserted in `tests/structure.sh`. An overturned decision needs a mechanical guard, not a note.

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

**This section is in the wrong package and it is known.** The ruling on issue #1 put degradation rules in the asset layer; they sit here only because that layer has no `Shell` yet. Do the work as written, and when `Shell` exists move it rather than duplicating it — ADR-0003, deferred item 9.

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
- **Skin preview toggle** — off by default, never persisted; see the section above
- **Live data row** — current width, main-area width, threshold, degradations fired, user preference state

Give the README a "toggle → what it verifies" table. That table is how the user reviews the work; don't make them guess.

---

## Directory-level CLAUDE.md

Must contain:

1. **What this is**: the reference implementation of a named spec; a low-fidelity wireframe; not product code; a **consumer** of the asset layer.
2. **Before you touch anything** (not skippable): which document and sections to read; walk the decision tree; stop if it doesn't land; every region must render through `AnnotatedRegion` with an id from the allowlist; the order for adding a region (spec → asset layer → here).
3. **The deliberate-tradeoffs list** — a two-column table: current state | this is deliberate. Its job is to **stop the next agent from "fixing" things left out on purpose**. Include at least: **grey is the default and the skin preview is off by default — neither is a bug**, no colour values outside `NEUTRAL`, uniform status label color, buttons only differentiated by grey, dense fixtures, clicking does nothing, degradation measured rather than breakpointed — plus anything the spec explicitly forbids that looks like an omission on screen.

Get that first entry right. Left as the old "no brand visuals here", the next agent reads the preview mode as something to rip out.
4. **The single source for structural parameters**: which file, that changing it changes the spec, and that it is expected to move to the asset layer later.
5. How to run it, plus the type-check command.

---

## Wrapping up

**Install dependencies, run type-checking, run the build, and paste the real output.** For why this isn't optional, call the Skill tool with "constraint-by-types".

Then reconcile by grep: every allowlist region name is findable in the asset layer's type definition, its metadata table, and the actual wireframe code.

Then start the dev server for the user.

**State honestly what you verified and what you didn't.** You usually have no tool that can look at a web page, so "does the layout break, does the density look right" is beyond you — say so, and give a "verify these specific things" list for the user to check. Never let "done" cover for "never looked at it".
