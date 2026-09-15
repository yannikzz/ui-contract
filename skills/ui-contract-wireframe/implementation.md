# Wireframe implementation guide

The wireframe is the spec's **runnable reference implementation**, and building it is what forces the spec's holes into the open. It is not product code, and it is not another round of exploring options.

Its only purpose: give coding agents a runnable reference for "where the regions sit, and what may go in each".

---

## Visual discipline

| Do | Don't | Why |
|---|---|---|
| Neutral greys by default, system font | **Colour *values* anywhere but the `NEUTRAL` map and `inspect.tsx`** | The rule is no colour **values** here, not no colour. A skeleton carrying its own brand values becomes a second value authority; one that reads them live from the token file cannot go stale |
| A status label knows **which semantic class** it is, and nothing else | Picking a colour for it | The class ("needs action", "blocked", "done") does not change when the brand changes, so it is structural and belongs in the asset layer. The colour is the visual spec's, and reaches the label through a token |
| Buttons differentiated only by grey depth | Real button styling | Hierarchy belongs to the wireframe; specific styling belongs to the visual spec |
| **Real copy, real row counts, real depth** | Lorem, three placeholder rows | An empty interface makes any layout look fine. Density is what exposes problems: columns that don't fit, long strings that break, parallel items crushed together |
| Zero business logic; clicking does nothing | Wiring data, building state machines | This exists to verify structure and placement |

⚠ **This row used to read "one uniform grey for every status label".** Right about colour, wrong about class, and the cost went unnoticed: with every label the same grey, **the skin preview showed almost nothing** on a product whose visual life is its status column — one button and one nav row changed, nothing else moved. A preview that cannot show semantic colour barely answers "does this palette work on my screens".

The fix is not to let the wireframe choose colours but to split the question: the **class** is structural (the asset layer's `StatusKind`, exhaustively mapped so a new status must be classified), the **colour for a class** is one table in the visual spec. The wireframe still decides nothing — skin off, every class is the same grey.

**Do not skip the class layer and map statuses straight to colours.** Six statuses mapped to six colours is not a classification, and the seventh arrives with nothing forcing anyone to think about where it belongs.

Push density to the **realistic ceiling**: if the product might have six parallel items, five states, and one blocked checkpoint at once, the fixtures should contain all of it.

The asset layer already carries the project's brand through the token file. The wireframe **defaults to neutral** — that is the point of the split, not an oversight to fix.

---

## Skin preview

Once `design.md` is connected, the projection can preview the real skin on this product's own
screens — the one thing the tuning instrument cannot show. **That is a second-pass concern and
it has its own file: [skin-preview.md](skin-preview.md).** It carries four rules that only work
together, the screenshot marker requirement, the editable preview, and which control surfaces
must never follow the skin.

On the structural half there is no token file to read, so none of it applies. The colour rule
that does apply on every pass is in §Visual discipline above.

## Directory layout

```
<repo root>                        Where check-colours.sh is run from
├── check-colours.sh               The colour-discipline check. Not a CI gate — see below
└── .ui-contract-local/            The workbench. NOT committed — see below
    └── wireframe/                 ← <wireframe> from the paths table
        ├── CLAUDE.md              Directory-level constraints + the deliberate-tradeoffs list
        ├── README.md              How to run it, what each toggle verifies, why it's grey
        └── src/
            ├── inspect.tsx        The apparatus, and THE colour exemption: annotation layer,
            │                      skin banner, skin editor, and the browser chrome — viewport,
            │                      corners, panel, zones, wall. Imports RegionId / Region /
            │                      REGION_META from the asset layer — never redefines them
            ├── wire.tsx           NEUTRAL + SKIN + the neutral parts. No colour values outside NEUTRAL
            ├── structure.ts       Structural parameter constants + the degradation pure function
            ├── fixtures.ts        Fake data (header says "not a spec")
            ├── App.tsx            Browser state + shell composition. Places nothing; carries no colour
            └── pages/*.tsx        One file per page archetype
```

**The check sits outside the workbench, and both halves of that matter.** Its paths are
repo-root-relative — `WIRE_SRC=".ui-contract-local/wireframe/src"` in the template — so it is
run from the root, where the task runner already runs. Put it inside `wireframe/` and it
resolves `WIRE_SRC` against *that* directory, finds nothing, and exits 2 with
`No wireframe at … — nothing to check`: not a failure, not a pass, a no-op that inspects zero
files while looking like a clean run. The other half is that the workbench is gitignored — a
script living in it would be uncommitted too, and the one check that is meant to outlive any
particular wireframe would disappear with it.

### The wireframe is not committed, and three things follow

It lives in the workbench, which is gitignored. The reasoning is the one that was already true and is now acted on: **the wireframe's durable output was never the wireframe.** Building it forces holes in the spec into the open, the rule is document-first, so what is worth keeping lands in `layout.md` — and that is committed. The wireframe is the instrument that produced the result, not the result.

Three consequences, none of which take care of themselves:

| | |
|---|---|
| **Regeneration is the only way to get one** | So it has to be written down as steps a person can follow, not as "run the skill again". Put it in the repo-root `CLAUDE.md`: this project keeps no wireframe in the repository; regenerate with `ui-contract-wireframe`; the inputs are `layout.md`, `design.md` and the asset layer, all of which are committed |
| **The compile-time layer cannot live here** | The allowlist typecheck used to run through this directory. On a repository that does not contain it, that check never runs in CI — and it fails silently, staying green. It belongs on product source; `ui-contract-enforce` §The compile-time layer has to sit on code that ships |
| **The directory `CLAUDE.md` only reaches whoever regenerated it** | Its content derives from `layout.md`, so anyone who regenerates gets their own copy — but cross-person hard constraints belong in the repo-root `CLAUDE.md`, which is committed |

**Do not write "a runnable reference for coding agents" without qualifying it.** That sentence is currently in both the generated `CLAUDE.md` and `README.md`, and once the directory is not in the repository it is true only on the machine that built it. Write "a local reference; regenerate with X when absent" instead. An unqualified version is the kind of sentence nobody ever checks and everybody believes.

**Regenerating rebuilds `wireframe/` only.** The workbench also holds `tokens.input.json`, written by a different step. Wiping the whole workbench takes the user's brand knobs with it, silently.

`assets/wire.tsx.template` and `assets/inspect.tsx.template` are the starting points for those two files, and `assets/check-colours.sh.template` for the check — copy and adapt. **The apparatus template carries `TODO` placeholders that render as text** — the four zone titles, the corner labels, the panel's title — in addition to the ones in comments. Replace every one in the deliverable's language; `check-colours.sh` does not look for them.

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

**This section is in the wrong package and it is known.** Degradation rules were ruled to belong in the asset layer; they sit here only because that layer has no `Shell` yet. Do the work as written, and when `Shell` exists move it rather than duplicating it. `ui-contract-assets` states the same deferral from the other side.

If the spec has size-degradation rules, **implement them; don't leave them in the document** — a rule in a document never gets verified.

How:

1. Put the structural parameters (column widths, minimum usable width, gutters) as named constants in **one place**, with a comment pointing at the corresponding section of `layout.md` and a note that **changing these constants changes the spec** and requires syncing the document.
2. Measure the container with `ResizeObserver`; don't use viewport breakpoints.
3. Write the degradation decision as a **pure function**: inputs are width plus user preference, outputs are each column's collapsed state and the main area's actual width. Only a pure function makes the cascade order legible at a glance — and reviewable against the spec.
4. User preference must override automatic degradation in both directions (collapsed by hand stays collapsed when space returns). Represent it as a three-state preference: `auto | open | closed`.
5. **Display the live computation on screen** (current width / main-area width / threshold / which degradations fired). That lets the rule be verified against numbers instead of by feel.

Handle the first-frame case: before `ResizeObserver` reports, the measured width is 0. Return the un-degraded state for that frame, or the interface flashes its collapsed form once on load.

---

## The prototype browser

The apparatus around the projection is itself a small interface, and it gets the same treatment
this plugin gives the product: **named parts, one placement rule, closed sets.** Not a list of
"at least these controls" — that is a lower bound, and the tenth control lands wherever the agent
puts it. The parts and their rule are fixed in `inspect.tsx`; `App.tsx` composes them and decides
nothing about placement.

### Four parts, one rule

| Part | What it is | What goes there |
|---|---|---|
| **Viewport** | The light-grey rounded area. The projection lives inside it — either the prototype or the wall | The thing being looked at |
| **Corners** | Bottom-left and bottom-right, inside the viewport | Controls that **act on the viewport**: view switch, lens zoom, fit, canvas background |
| **Panel** | To the right, **outside** the viewport, on the page's white | Controls that **act on the prototype**, plus the readout block |
| **Wall** | The viewport's second view | Every archetype × state × width tier, side by side. §Wall below |

> **Does it change *how you look*, or *what you look at*?** The first goes in a corner; the second
> goes in the panel. Every new control answers that in one step.

The one closed exception is the panel's own collapse/expand: it is an operation, but it must stay
visible or there is no way back. Collapsed, the panel becomes a stub that still reads as clickable —
the first version left an empty 560px strip that read as a leftover, and the user could not find
the way back.

**There is no top bar.** The reason the old rule gave — the wireframe's job is showing real
density, and a permanent strip above the product distorts "how many rows fit" — still holds. A
strip that only displays numbers is not worth what it costs; the numbers go in the panel instead.

⚠ **The skin banner is still outside the panel**, across the top of the viewport, and cannot be
collapsed. A warning that can be folded away is not a warning.

### The panel: a readout block and four zones

The readout block sits above the zones and does not scroll with them: shell width as measured,
lens scale, each column's resolved state, main-area width against its threshold, which
degradations fired. It is how a degradation rule gets verified against numbers instead of by feel.

Below it, four zones in a **fixed order**, chosen by what the control changes:

| Zone | Changes | Holds |
|---|---|---|
| Screen | Which page | Archetype, wizard step |
| Condition | The environment it is seen in | Width clamp, nav preference, data state, panel state, overlay |
| View | How it is seen — on the prototype, not the viewport | Annotation toggle, skin preview toggle |
| Output | **The only zone whose result flows back into the project** | Direction switch, token editor |

`Zone` requires a `zone` prop, the zone type is a closed union, and `Panel` sorts its children by
that order. An empty zone does not render. The output zone is visually set apart because it is
different in kind: everything else is pure observation and dies with the tab; this zone produces
the prompt that edits `tokens.input.json`. Zone titles are two words; no subtitles.

**Direction switch** — the candidate directions from `originate` Step 1: the chosen one and the
ones declined. **Not themes this plugin ships** — that would be "generate a default brand", three
times, with the values living in a throwaway file. Read them from the knobs record.

⚠ **Say what the direction switch cannot show.** It swaps tokens, so a direction whose defining
trait is a *treatment* rather than a value — filling whole rows instead of marking their edge —
looks nearly identical to the chosen one. Measured on a real wireframe: the declined "fill the
row" direction differed only in chip saturation once switched. Hand it over with that stated, or
the control quietly claims to preview more than it does.

### Controls: the shape is a function of the data

`Choice` picks its own widget: a boolean is a switch, up to four exclusive options are a
segmented control, five or more are a dropdown. The agent supplies options and never a widget.
"Can choose" is where inconsistency gets in, and this removes the choice — the same move as the
zone order. Ten archetypes therefore become a dropdown; that hides the others, and ten archetypes
is also the enumeration bloat `layout.md`'s object-test exists to stop.

### Corners

Bottom-left: the view switch (prototype / wall) — rendered only when a wall is supplied.
Bottom-right: lens out / scale / in, fit-to-viewport, and the canvas background toggle. The set is
closed inside `Viewport`; a project that needs one more viewport-level control edits the apparatus
file and its `APPARATUS:` line, so the addition is a visible diff.

"Dark mode" here means the **canvas background** only. A dark version of the prototype would be a
second `NEUTRAL` map — part of the thing being looked at, and out of scope.

### The lens is not width

The viewport has a lens: trackpad pinch and ⌘+wheel zoom the canvas **around the cursor** in both
views (the browser's own page zoom is intercepted); the corner buttons zoom around the viewport's
centre; the wall pans by dragging; the canvas shows no scrollbars. **At rest the prototype is
centred on both axes** — a phone-width tier sits in the middle of the viewport, not at its top —
and once it outgrows the viewport it becomes scrollable from the top-left. The anchor is computed
from where the element actually lands after the re-render, so that transition does not jump. The lens is available on the prototype too, because a 1440 laptop minus the panel does
not fit the 1280 tier and clipping is the only alternative.

**The measured width is read from layout — `offsetWidth`, or `ResizeObserver`'s `contentRect` —
and never from `getBoundingClientRect` divided by the lens. The lens has no transition.** Measured:
with a 0.15s transition and the rect-divided-by-scale reading, every pinch tick measured mid-animation,
the shell width jittered, and the degradation flipped with it. Layout is what is being measured;
pixels are how it is shown.

### Wall

The wall lays out **every archetype × every non-happy-path state × every width tier**, each tile
rendered by the same shell at that tier's width. `Wall` itself is a two-axis grid: rows are
archetypes, columns are the width tiers in the normal state followed by each non-happy-path state
at one reference tier — the caller folds the third axis into the columns, and the column labels
say which section each came from. All three axes are already in `layout.md` — §4
archetypes, §8 states, §3.4 tiers — so the wall projects them and invents nothing. It answers the
question single-page switching cannot: does the structure hold on every page at once, and what
does a direction look like on all of them.

**It draws no arrows.** `layout.md` has no clause for how a user gets from one screen to the next;
it answers where a feature goes. A connector on the wall would be the wireframe inventing structure,
and the next agent would build to it. Flow diagrams start with a section in `layout.md`, not here.

In wall mode the screen and condition zones do not render — they have become the wall's axes — the
view and output zones act on every tile, and the readout block hides because there is no "current"
screen.

**This requires the shell to be a component that takes its width as a prop.** The prototype view
feeds it the `ResizeObserver` reading; the wall feeds it the column's width. A shell inlined in
`App.tsx` with its hooks cannot be tiled. Build it as a component from the start.

### Visual order

Page white → viewport light grey, rounded → prototype white. The panel sits on the page's white,
outside the viewport, with no line between them — the grey edge is the boundary. The chrome is
light and its colours are fixed; the exemption is unchanged.

Give the README a "control → what it verifies" table. That table is how the user reviews the work; don't make them guess.

---

## Directory-level CLAUDE.md

Must contain:

1. **What this is**: the reference implementation of a named spec; a low-fidelity wireframe; not product code; a **consumer** of the asset layer.
2. **Before you touch anything** (not skippable): which document and sections to read; walk the decision tree; stop if it doesn't land; every region must render through `AnnotatedRegion` with an id from the allowlist; the order for adding a region (spec → asset layer → here).
3. **The deliberate-tradeoffs list** — a two-column table: current state | this is deliberate. Its job is to **stop the next agent from "fixing" things left out on purpose**. Include at least: **grey is the default and the skin preview is off by default — neither is a bug**, no colour values outside `NEUTRAL`, uniform status label color, buttons only differentiated by grey, dense fixtures, clicking does nothing, degradation measured rather than breakpointed, **the wall draws no arrows**, **the lens changes the scale and not the measured width** — plus anything the spec explicitly forbids that looks like an omission on screen.

Get that first entry right. Left as the old "no brand visuals here", the next agent reads the preview mode as something to rip out.
4. **The single source for structural parameters**: which file, that changing it changes the spec, and that it is expected to move to the asset layer later.
5. How to run it, plus the type-check command.

---

## Wrapping up

**Install dependencies, run type-checking, run the build, and paste the real output.** For why this isn't optional, call the Skill tool with "constraint-by-types".

Then reconcile by grep: every allowlist region name is findable in the asset layer's type definition, its metadata table, and the actual wireframe code.

Then start the dev server for the user.

**State honestly what you verified and what you didn't.** You usually have no tool that can look at a web page, so "does the layout break, does the density look right" is beyond you — say so, and give a "verify these specific things" list for the user to check. Never let "done" cover for "never looked at it".
