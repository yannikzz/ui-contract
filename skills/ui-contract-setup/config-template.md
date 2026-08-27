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

| Key | Artifact | Path | Default |
|---|---|---|---|
| `layout` | Structural spec | | `layout.md` at the repo root |
| `design` | Visual spec | | `design.md` at the repo root; if the project has no visual spec yet, write **none yet** — never a path that is not on disk |
| `tokens` | Token file | | the project's existing token source; if there is none, write **none yet** — never a path that is not on disk |
| `tokens-format` | Token file — **format** | | CSS custom properties / `theme.extend` / a theme object. `none yet` if there is no token file. **Do not leave blank** — every unit that writes tokens reads this, and an agent inferring it from the file leaves no trace that it inferred |
| `src` | Production source tree | | where the product's own UI code lives — **found, not asked**; see `SKILL.md` §Look things up yourself |
| `asset-layer` | Asset layer | | inside the production source tree |
| `asset-container` | Asset layer — container, **only if it is a separate file** | | leave blank on stacks where the type and the container share one file (React, React Native). Vue splits them (`regions.ts` + `Region.vue`) |
| `workbench` | Workbench | | `.ui-contract-local/` at the repo root — **not committed** |
| `wireframe` | Wireframe | | `.ui-contract-local/wireframe/` — inside the workbench |
| `as-built` | As-built record | | `as-built.md` at the repo root |

### The Key column is for machines, and it stays ASCII

Every unit reads this table, but they read it as prose — an agent does not need the key. **One reader is a script**: `ui-contract-audit` derives its paths from here rather than carrying its own copy, so it has to find each row without knowing what language the Artifact column is written in.

Same problem and same solution as `design.md`'s declaration table, which is found by three ASCII keywords for exactly this reason. And the same stated cost: **translate a key and that lookup goes quiet** — the script degrades to not finding the row, never to finding the wrong one.

**Do not leave a Path cell blank.** "No config file at all" and "a config file somebody started and did not finish" are two different failures, and the second one is worse: a script that quietly substitutes a default for a blank row audits a path nobody chose, and the report reads completely normal. `ui-contract-audit` treats a blank cell as a broken setup (exit 3), not as "use the default".

"None yet" is a value, not a blank — write it where the Default column says to, and **write it in ASCII**, as `none yet`. Same decision and same stated cost as the Key column: the rest of the row is written in the deliverable's language, and `ui-contract-audit` matches this one on the word. Translate it and the script reads it as a path, does not find it, and exits 3 naming that cell — loud, and one edit away from correct.

**A path that names something not on disk is exit 3 too**, not just a blank one. The script checks every path it actually reads — `layout`, `design`, `tokens`, `src`, `asset-layer` — because a stale path does not make a check quiet, it makes it wrong: point `tokens` at a file that moved and the health check reports the real token file's own colour values as drift.

### The workbench, and what may not live in it

UI is one thing with two dimensions: `layout.md` governs placement, `design.md` governs
tokens. The **rehearsal** of both — the wireframe, and the record of where the brand knobs
were left — goes in the workbench. The **authority** of both stays in the repository.

The workbench is gitignored. So the rule that matters is about what must never move in:

| Rehearsal → workbench, not committed | Authority → repository, committed |
|---|---|
| the wireframe | `layout.md` · `design.md` |
| where the knobs were left | **the token file** — production code reads it for every value |
| skin edits | `docs/ui-contract/` — this file, and the decision records |

**The token file above all.** `design.md` points at it for every value, so it is the value
authority; inside a directory that is never committed, it does not merely become deletable —
it never reaches the repository, and everybody else clones a spec whose values point nowhere.
`ui-contract-audit` check 9 enforces both halves.

Two mechanical consequences of filling in the Workbench row:

- **Whatever path goes there must also be a line in `.gitignore`,** and that line is committed.
  A path recorded here with no matching ignore rule means the throwaway tree gets committed and
  nothing complains.
- Do not name it `.ui-contract/`. It differs from the committed `docs/ui-contract/` by a prefix
  while having the opposite fate, and one of the two will eventually be ignored by mistake.

`tokens.input.json` is **deliberately not a row here.** It always lives at `.ui-contract-local/tokens.input.json`, inside the workbench, and it is **scratch for a tuning session** rather than an artifact: the instrument's starting state, format-neutral so every tool in that session can read it, inert the moment the tuned values reach the token file. Its absence from this table is not an omission to fill in — the instrument and a grader both need one answer rather than a recorded one.

**It is not where the values live.** The Token file row above is. The knobs record loses every disagreement with it, and nothing downstream reads it to obtain values — `ui-contract-design`'s `originate` branch writes the token file directly. Nobody should be keeping, committing, or maintaining the record.

## Authorisations

Only questions that cannot be derived from the repo belong here.

| Question | Answer |
|---|---|
| May the existing visual spec be edited? | |
| Where do the two specs live, and what are they called? | |
| Where does the wireframe live? | |
| Where does the asset layer live in the production tree? | |
| Is the same person answering for structure **and** visuals? | |

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
