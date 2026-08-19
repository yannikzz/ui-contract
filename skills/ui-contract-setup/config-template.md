# UI contract — configuration

> Written by `ui-contract-setup`. Records **authorisations and file locations only** — no rules.
> The specs themselves are authoritative for what is correct.

## Starting point

| | |
|---|---|
| **Start** | A (greenfield) / B (mockups exist) / C (visual spec exists, structural spec missing) |
| **Identified from** | what was actually found on disk |

## What already exists

| Kind | Path | Notes |
|---|---|---|
| Visual spec | | |
| Token source | | `tailwind.config.*` / `tokens.css` / theme file — this becomes **the** token file |
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
| Token file | | the project's existing token source |
| Asset layer | | inside the project's production tree |
| Wireframe | | its own directory |
| As-built record | | `as-built.md` at the repo root |

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
