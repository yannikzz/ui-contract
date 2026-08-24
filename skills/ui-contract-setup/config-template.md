# UI contract — configuration

> Written by `ui-contract-setup`. Records **authorisations, file locations, and what was
> not verified** — no rules. The specs themselves are authoritative for what is correct.

## Starting point

| | |
|---|---|
| **Start** | A (greenfield) / B (mockups exist) / C (visual spec exists, structural spec missing) |
| **Identified from** | what was actually found on disk |

## What already exists

| Kind | Path | Notes |
|---|---|---|
| Visual spec | | |
| Token source | | `tailwind.config.*` / `tokens.css` / theme file — this becomes **the** token file. Note its **format** too, not just its path |
| Structural doc | | |
| Frontend code | | stack, whether TypeScript is in use |
| Repo-root agent instructions | | `CLAUDE.md` / `AGENTS.md` |
| Existing decision records | | `docs/adr/` — **not merged into**; that is the code/architecture namespace |

## Paths (authoritative)

Every other unit reads this table instead of assuming. Fill it in even when the answer is the default.

| Artifact | Path | Default |
|---|---|---|
| Structural spec | | `layout.md` at the repo root |
| Visual spec | | `design.md` at the repo root |
| Token file | | the project's existing token source; if there is none, write **none yet** — never a path that is not on disk |
| Token file — **format** | | how values are written there: CSS custom properties / `theme.extend` / a theme object. `none yet` if there is no token file. **Do not leave blank** — every unit that writes tokens reads this, and an agent inferring it from the file leaves no trace that it inferred |
| Asset layer | | inside the project's production tree |
| Wireframe | | its own directory |
| As-built record | | `as-built.md` at the repo root |

`tokens.input.json` is **deliberately not a row here.** It always lives at `docs/ui-contract/tokens.input.json`, beside this file. It is a working record of where the brand knobs were left, not a spec, and the units that write and read it both need one answer rather than a recorded one. Its absence from this table is not an omission to fill in.

## Authorisations

Only questions that cannot be derived from the repo belong here.

| Question | Answer |
|---|---|
| May the existing visual spec be edited? | |
| Where do the two specs live, and what are they called? | |
| Where does the wireframe live? | |
| Where does the asset layer live in the production tree? | |

Both specs sit **side by side at the same level** (usually the repo root) so they apply across sub-projects. Split across two locations and agents find only one of them.

## Legacy strategy

*Filled in by `ui-contract-baseline`, not here.* It cannot be answered before the gap between the as-built state and the spec has been measured — asking earlier only produces a guess.

| | |
|---|---|
| **Strategy** | freeze line / migrate first / hybrid |
| **Recorded in** | an ADR, because it is hard to reverse, excluded real alternatives, and has a nameable revisit condition |

## Not verified this round

Conclusions reached **without evidence** — reached by inference, or by following a recommendation because the user was in a hurry. Not rules: rules live in the specs. This section records **the delivery's verification boundary**, so the next reader can tell a measured value from a plausible one.

Leave it out only when there is genuinely nothing in it. An empty section is honest; a missing one reads as "everything was checked".

| # | What was not verified | What it affects | How to clear it |
|---|---|---|---|
| | | | |

The two that show up almost every time, because an agent structurally cannot do them:

- **Rendered output was not looked at.** Density, whether a column still fits once a panel squeezes it — these can only be seen. Say so and point at what the user should open.
- **Values were not measured off a design.** A spec whose numbers are a placeholder scale is a different artifact from one whose numbers came off a mockup, and only this section records which one was delivered.
