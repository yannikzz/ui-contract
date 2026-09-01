# The skin preview

**Read this on the pass where `design.md` is connected, and not before.** The structural half
builds the projection from `layout.md` alone: there is no token file for a preview to read, so
nothing here applies and the projection is grey — which is a finished state, not a placeholder.

Nothing in this file changes the colour rule itself. That rule — **colour *values* live only in
`NEUTRAL` and in `inspect.tsx`** — holds on both passes and stays in `implementation.md`
§Visual discipline, where every build reads it.

---

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
