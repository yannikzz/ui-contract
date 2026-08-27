# Wireframe implementation guide

The wireframe is the spec's **runnable reference implementation**, and building it is what forces the spec's holes into the open. It is not product code, and it is not another round of exploring options.

Its only purpose: give coding agents a runnable reference for "where the regions sit, and what may go in each".

---

## Visual discipline

| Do | Don't | Why |
|---|---|---|
| Neutral greys by default, system font | **Colour *values* anywhere but the `NEUTRAL` map and `inspect.tsx`** | The rule is no colour **values** here, not no colour. A skeleton carrying its own brand values becomes a second source of visual truth; one that reads them live from the token file cannot go stale |
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

The one thing the tuning instrument cannot give the user: **this product's real information architecture wearing the skin.** The instrument shows generic controls at real density; only the wireframe shows their actual screens. So the preview belongs here.

It was excluded once, and that was overturned. **The four rules below only work together** — changing one without checking the others puts the exclusion back in effect by accident.

| # | Rule | What it stops |
|---|---|---|
| 1 | All colour goes through `--wire-*` custom properties. **Values exist in exactly two places** — `NEUTRAL` in `wire.tsx`, and the whole of `inspect.tsx`. **This covers the whole directory** | Any brand value living here |
| 2 | Preview **reads the token file at runtime** — `import` it, never copy it | Values splitting in two, the skeleton going stale |
| 3 | **Off by default, and not persisted.** Every reload is grey | "Six months on nobody remembers it defaults to off" |
| 4 | While on, a marker that **survives a screenshot** — names the token file, says not to copy from here, and the person taking the picture cannot remove it | The screenshot. Default-off cannot reach an agent looking at a picture; this can |

Rule 4 is aimed at one exact failure: six months on, somebody opens the preview, screenshots it, and copies values out of the picture into feature code.

**State it as the requirement, not as a shape.** What has to be true is that the marker is *in the frame*, *legible in an image*, *names the token file*, and *cannot be removed by the person taking the shot*. Everything else is implementation:

| Follows from the requirement | Does **not** follow |
|---|---|
| Fixed colours — a marker tinted by the theme it warns about can vanish (measured; see below) | That it must sit at the top |
| Names the token file, so the reader of the picture knows where to go | That it must be a full-width strip |
| Not dismissible, and not hidden by collapsing the verification panel | That it must occupy layout space rather than overlay |
| Big enough to read at screenshot scale, and not croppable-by-accident like a corner badge | Any particular height |

⚠ **This used to read "do not shrink it into a corner badge", full stop.** That is a shape, not a rule, and a shape gets worked around: the next person has a different shape and no way to tell whether it satisfies anything. A corner badge does fail the requirement (easy to crop, easy to miss) — saying so *without saying why* leaves the boundary to guesswork.

**It has a cost, and it is not zero.** The marker takes about a table row's height from the product — and the wireframe's other job is showing real density. Measured: the ⏳ calculation for "how many rows fit a screen" came out 8px over budget, **less than the marker's own height**. So verify density with the preview off, or place the marker so it does not shift layout. Either is fine; pretending the cost is not there is not.

**The apparatus file's export list has exactly one home: the file itself.** It carries an
ASCII `APPARATUS:` line in its header, and both readers — `check-colours.sh` in the generated
project, and this repo's own invariants — read it rather than keeping a copy.

The exemption is a file and its exports are a declared closed list; what this settles is where
the declaration lives. Written into three places, one decision cost three edits and only the
checks caught a missed one — measured twice in an afternoon, adding `SkinBanner` and renaming
`DemoBar` to `DemoPanel`. The decision belongs where it is made: adding a name shows up in that
file's diff.

Two properties the readers must keep, and both are the same rule seen elsewhere:

- **The marker stays ASCII** even when the comment is written in the deliverable's language — as with the paths table's Key column and the declaration table's three keywords.
- **A missing declaration fails loudly.** "No `APPARATUS:` line" must never be read as "nothing is declared", because that silently exempts every export in the file.

**Inspect chrome does not follow the skin** — badges, region outline, tooltip, banner, skin editor, demo toggle panel. They are apparatus, not product surfaces, so they carry fixed colours, and all of them live in **`inspect.tsx`, which is the exemption**: anchored on the file, not on a marker inside one. Its exports are a declared closed list, so moving a product component in — buying it the right to hardcode colour — has to be a decision somebody wrote down.

Which surfaces, and what breaks for each, is the table in §Control surfaces are not skinned
either below — one rule, not a list of exceptions.

**A role with no token stays neutral.** `SKIN` ships empty and the agent fills it from `design.md`'s declaration table — the same table the tuning instrument reads. An unmapped role simply does not change. Do not invent a value to fill the gap; that is the failure the whole split exists to prevent.

### Rule 1 covers every file, and this is where it is easy to get wrong

Measured on a real wireframe: `wire.tsx` held 17 hardcoded colour classes, and **`App.tsx`, `Inspector.tsx` and the four `pages/*.tsx` held about 140 more.** `wire.tsx` was never the only place colour lives — the page files paint directly.

Convert all of them. Skip the page files and the preview skins only the parts that happen to route through a `wire.tsx` component, which looks like a half-broken theme rather than like a bug.

**`check-colours.sh` is what enforces this in the generated project.** Ship it with the wireframe, wire it into the task runner, and run it before calling the wireframe done — the output goes in the report. It reports and fixes nothing, like every other check this plugin ships.

⚠ **It is not a CI gate, and must not be described as one.** The workbench is not committed, so on most projects this never runs in CI. Its reader is the agent editing the wireframe right now — the only moment the rule is still cheap to apply. `ui-contract-audit` audits the production tree and never looks in here, so a green health check says nothing about colour in this directory.

⚠ **Two things the check cannot catch, and both belong in its own comments rather than only here:** a brand colour added *into* `NEUTRAL` (values are legal there, so "is it actually grey" is a review question forever), and anything inside `inspect.tsx` (that is what the exemption means).

### The preview is editable, and the output is a prompt

Only the wireframe shows this product's real IA, so it is the only place where "that is wrong at this density" can be both noticed **and** acted on. `SkinEditor` gives every mapped token a field; `useSkin` keeps the edits in memory.

| | Instrument (`design` step) | Wireframe (`wireframe` step) |
|---|---|---|
| Does it exist yet | Yes — the wireframe does not | Yes |
| Shows | Generic controls | **This product's real IA** |
| Writes | `tokens.input.json` — **its only writer** | Nothing |
| Output | The JSON | A prompt, handed to an agent |

Because the instrument is the JSON's only writer, two open editors cannot overwrite each other. That is a consequence of this split, not its purpose.

**The prompt carries exact old → new values**, and **token names rather than `--wire-*` roles** — the agent edits `tokens.input.json`, whose keys are token names, and `design.md` is the name authority. Without exact values the agent's application is a guess.

**The prompt must never invent a change.** Measured: opening the native colour picker and closing it rewrites `oklch(0.47 0.15 258)` as `#1a57ad` — same colour, different notation. Report that and an agent will quietly convert the project's colour space to hex. So a change counts only when the two values resolve differently; the dirty marker and the prompt's list share one comparison, because two comparisons eventually disagree and the panel starts saying one thing while the prompt says another.

A prompt that invents changes is worse than no prompt: it is the only carrier of the user's intent in this whole path.

**And a copy button that fails silently is the same failure wearing a different coat.** `navigator.clipboard` does not exist in a non-secure context — opened over a LAN address, or with permission refused — so `navigator.clipboard?.writeText(...)` writes nothing and the optional chain swallows it. Measured: the button then reported success while the clipboard was untouched.

Two things follow, and both are cheap:

- **Report what actually happened.** Await the write, catch the failure, and say so. "Copied" and "could not copy" must not share a state with "not clicked yet".
- **Render the prompt where it can be read and selected**, always. The clipboard is a convenience; the text is the deliverable. A user who cannot copy must still be able to take it.

**Switching direction is not a token edit, and the prompt must not say it is.** The direction switch changes every mapped value at once, so the naive prompt is a twenty-line token diff — and an agent handed that edits the token file while `design.md` §1 still names the direction that was declined. Document says one thing, values say another: the second authority this whole split exists to prevent, arrived at through the mechanism meant to prevent it.

So a direction change emits a **process**, not numbers: change §1 first, re-derive, then re-check the structural numbers that depend on the scale. Hand-tuned edits on top of a previewed direction are listed after it, as edits, with exact old → new. Two sections, never merged.

⚠ **Two costs, both deliberate, neither to be papered over:**

- **The hop is unrecorded.** "Turned a knob here" → "the JSON changed" goes through an agent, and nothing records that it happened.
- **Nothing remembers the edits.** No storage, no writes — close the tab and they are gone. Accepted because the alternative, a wireframe that remembers values, is a second value authority.

Say both out loud when handing the wireframe over. A user who does not know the edits are volatile will lose work.

### Control surfaces are not skinned either

Three things needed this exception, and they are one rule, not three:

> **Anything you use to control or interpret the wireframe must stay readable no matter what the skin does — so it must not follow the skin.**

| Surface | What breaks if it follows the skin |
|---|---|
| Annotation badges, region outline, tooltip | A tooltip tinted by the theme it describes cannot describe it |
| The skin banner | A warning tinted by the values it warns about can vanish |
| **The demo toggle panel** (`DemoPanel` / `Group` / `Sw` / `Readout` / `Alert`) | **The control that turns the skin off becomes unreadable — you are stuck in it** |
| The skin editor panel | Same as the toggle panel: the fields you fix a bad theme with must survive that theme |

The third one was found by converting a real wireframe and watching the toggles change colour. `Sw` and `Group` used to sit at the bottom of `App.tsx`, well past the product markup, so a "convert everything below the product marker" pass took them with it.

**That trap is now closed by where the code lives, not by this paragraph.** The panel's chrome is in `inspect.tsx`, so the conversion pass cannot reach it and `App.tsx` carries no colour of its own. The note is kept because it says *why* the file boundary is drawn there — a rule whose reason is lost gets undone by the next person who finds it inconvenient.

Rule 1 is machine-checked, not left to this note. An overturned decision needs a mechanical guard.

---

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
            │                      skin banner, skin editor, demo-panel chrome. Imports RegionId /
            │                      Region / REGION_META from the asset layer — never redefines them
            ├── wire.tsx           NEUTRAL + SKIN + the neutral parts. No colour values outside NEUTRAL
            ├── structure.ts       Structural parameter constants + the degradation pure function
            ├── fixtures.ts        Fake data (header says "not a spec")
            ├── App.tsx            Shell + archetype routing + demo toggles
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

`assets/wire.tsx.template` and `assets/inspect.tsx.template` are the starting points for those two files, and `assets/check-colours.sh.template` for the check — copy and adapt.

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

## The verification panel

**Floating and collapsible, not a bar pinned to the top.** A fixed bar costs about 180px of
vertical space, and one of the wireframe's two jobs is showing **real density** — a permanent
strip above the product distorts the very question "how many rows fit". Collapsed, it is a
corner control and the product gets the whole screen.

⚠ **The skin banner does not live inside it.** A warning that can be folded away is not a
warning; render the banner outside the panel so collapsing cannot hide it.

At minimum the panel holds:

- **Archetype switch** — verifies which shell parts are present per archetype
- **Key state switch** — for every place the spec defines states
- **Width clamp** (a few steps) — verifies the degradation cascade
- **Overlay toggle** (if there is one)
- **Annotation toggle**
- **Skin preview toggle** — off by default, never persisted; see the section above
- **Direction switch** — the candidate directions from `originate` Step 1: the chosen one and the ones declined. **Not themes this plugin ships** — that would be "generate a default brand", three times, with the values living in a throwaway file. Read them from the knobs record
- **Token editor** — every mapped token gets a field, edits apply live and die with the tab, output is a prompt
- **Live data row** — current width, main-area width, threshold, degradations fired, user preference state

⚠ **Say what the direction switch cannot show.** It swaps tokens, so a direction whose defining
trait is a *treatment* rather than a value — filling whole rows instead of marking their edge —
looks nearly identical to the chosen one. Measured on a real wireframe: the declined "fill the
row" direction differed only in chip saturation once switched. Hand it over with that stated, or
the control quietly claims to preview more than it does.

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
