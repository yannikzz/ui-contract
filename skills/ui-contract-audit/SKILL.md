---
name: ui-contract-audit
description: Health-check an existing UI contract for drift. Runs automated checks that region names in code stay inside the allowlist, that the RegionId type is not bypassed by casts, that no color values are hardcoded past the token file, and that design.md carries no literal values - then reports the differences with fix suggestions and fixes nothing automatically. Produces a runnable script that lives in the repo and works in CI. Use when a project already has a layout.md or design.md and someone asks whether the spec is still in force, whether the code and the spec have drifted apart, what broke since the contract was written, or wants the contract checked before a release. Chinese: 界面规范还在起作用吗/规范和代码对不上了/检查界面契约/规范漂移/区域名违规/契约体检.
---

# Health check

Produces a **runnable script** in the user's repo (starting point: [assets/audit.sh.template](assets/audit.sh.template)) plus a difference report. This is the only unit here whose artifact is executable rather than markdown.

For the deliverable's language and terminology, call the Skill tool with "deliverable-language".

## Preconditions
**Artifact paths come from `docs/ui-contract/config.md`'s paths table.** If that file doesn't exist, the specs are at the repo root. Never assume a path the config contradicts.

**The script reads that table itself, at run time.** It does not carry a second copy of the paths, and adapting it does not mean filling paths in. Five knobs remain, and each is a fact the table cannot hold:

| Knob | Why it cannot be derived |
|---|---|
| `CONFIG` | Bootstrap — it is the path *to* the table |
| `MARKER` · `MARKER_EXCLUSIVE` · `SRC_EXT` | Stack facts. What happens when they are guessed was measured: a React Native project printed three green ticks over a real bypass |

It used to be eleven, six of them paths. **Measured, twice in one afternoon:** `SRC` set to the production tree reported all 24 allowlist names as "declared but never rendered"; set to the wireframe, it reported the wireframe's own `NEUTRAL` map as hardcoded-colour drift. Neither was a bug in a check — both were a caller getting a wide interface wrong, and both produced a confident wrong report.


| Condition | Action |
|---|---|
| No `layout.md`, and no `config.md` either | **Report "there is no contract to check" and stop.** Offer to build one; don't invent one to check against |
| No `layout.md`, but `config.md` exists | **Do not say "there is no contract to check."** Somebody ran setup, so a contract was configured and the paths simply do not point at it. Report the path mismatch and fix the paths |
| `layout.md` exists, no asset layer | **Check the document layer only**, and say which checks were skipped and why |
| Code contains region markers but no `layout.md` | Report it as the finding it is: the code has a structure nobody wrote down |

The script encodes that first split as two different exit codes, and **they must not be merged back into one**:

| Exit | Means |
|---|---|
| 0 | no drift found |
| 1 | drift found |
| 2 | nothing to check — no `layout.md`, and no config claiming there is one |
| 3 | a contract *is* configured, but this run is not looking at it — a blank Path cell (setup unfinished), or a path the table names that is not on disk. Every path the run reads is covered, not a subset: a stale `design` turns check 4 into one skip line, and a stale `tokens` makes check 3 report the real token file as drift. `workbench` is excluded on purpose — never having built a wireframe is a normal state |

A fourth tier sits **beside** the exit code rather than inside it. Clauses marked 🌡 in `design.md` are hypotheses, so they print a **warning** and leave the exit code alone: failing a build on a provisional clause hands whatever the clause borrowed a veto over the project's CI.

The cost of that is real and is not hidden: **"warnings present, exit 0" is green in CI.** The count printed at the end is the only thing that keeps such a report from being read as clean. Never silence it, and never promote a warning to drift without first moving the clause to 🔒 in `design.md` — the marker is what decides the tier, not the script.

`2` and `3` read almost the same in a terminal and are opposite conclusions: `2` says this project has no contract, `3` says it has one and this run is pointed at nothing. Sharing an exit code makes a broken setup look like a clean project, which is the one failure this whole unit exists to prevent. Report exit 3 as a finding, never as "nothing to check".

**Exit 3's meaning did not change when the paths moved into the table; only its detection did.** It used to compare a path written into the script against the table's — a comparison that no longer exists, because there is no second copy to disagree. The failure it caught changed shape rather than going away.

Two more states are deliberately **not** exit 3, and telling them apart is the whole point:

| State | Behaviour |
|---|---|
| No `config.md` at all | Defaults, **and it says so**. A legitimate state — the preconditions table above already treats it as one |
| A `config.md` with no Key column | Defaults, and it says the config predates the Key column. Treating an older config as broken would fail every project from before this change |
| A Key column with a **blank** Path cell | **Exit 3.** Somebody started setup and did not finish; substituting a default there audits a path nobody chose, and the report reads completely normal |
| A Path cell holding **`none yet`** | **Not exit 3.** It is a value, not a blank: the artifact legitimately does not exist. The checks that read it skip, and say which. `design: none yet` is a **steady state**, not a transient one — a project can stop after the structural half and never run the visual one, and reporting that as a broken setup would put a permanent red on a project that did nothing wrong. Note what the script's own comment says gets through: a **translated** placeholder is read as a path, is not found, and does exit 3 |

## It reports; it does not fix

Fixing means changing structure, which means walking the placement decision tree — a decision that belongs to a human, not to a drift detector. Auto-fixing also inverts the sync order the whole method rests on: documents change first, code follows.

So the output is **differences plus suggestions**, and the suggestion always names the clause that was violated.

## Cheap enough to run often

The value of a health check is inversely proportional to what it costs to run. It has to be cheap enough for every release, ideally cheap enough for CI. So the **body is automated checks; agent judgement is the supplement, never the substance.**

| Check | How | Automated |
|---|---|---|
| Region names in code ⊆ allowlist | grep the container's call sites | full |
| `as any` casts bypassing the id type | grep | full |
| Hand-written markers bypassing the container | grep | full |
| Hardcoded color values in feature code | regex | full |
| `design.md` holding literal **colours** | regex | full |
| Declaration table and token file name the same tokens | parse both, compare | full (**warn**) |
| Surface / `-foreground` pairs clear the contrast threshold | compute the ratio | full, hex only |
| Every allowlist row has a "must not hold" cell | parse the table | full |
| Every declared name is findable in code | grep each name | full |
| The workbench is actually in `.gitignore` | grep | full |
| The token file is **outside** the workbench | path comparison | full |
| No structural number is still marked ⏳ | grep | full (**warn**) |
| Have **sizes** moved to the token file? | semantic judgement | agent |
| Is the decision tree still total for the last N features? | walk real commits through the tree | agent |
| Do region descriptions say "what goes here" rather than "what this is"? | semantic judgement | agent |

Twelve of fifteen run automatically and fit in CI. **If that ratio drops much below eight tenths, this unit has degenerated into subjective re-reading and its value claim fails** — that is its stated revisit condition, not a slogan. It currently sits at twelve fifteenths — four fifths, and the three agent-judgement rows are recorded rather than rounded away:

**Sizes cannot be checked by regex.** A visual spec legitimately discusses numbers — in prose ("no writing off-table px sizes in feature code"), and in anti-pattern rows ("six months in you'll have 13px / 13.5px / 15px at once"). Measured against a real spec, a px regex produced four hits and **all four were false positives**. A check that cries wolf on correct documents is worse than no check, because people stop reading the output. Colours stay automated: a hex code in a visual spec is unambiguous.

**The contrast check reads hex only.** A project on a modern token convention writes its colours in `oklch()`, and the script cannot resolve those — so on such a project it finds no pairs at all. It reports that as **skipped, not passed**. A green tick there would be the precise failure this whole unit exists to catch, and the tuning instrument (`ui-contract-design`) is where those projects get contrast validated instead.

**The declaration table is found by its three origin keywords**, not by its header row — a spec written in the user's language has a translated header. Those keywords (`borrowed` / `this project` / `not used`) are therefore required to stay ASCII, which `ui-contract-design` states beside the table. If somebody translates them anyway this check finds nothing and says so as a skip; it never reports a wrong answer, but it does go quiet, so a green run here is not proof that the naming is sound.

**The threshold is read from `design.md`, never hardcoded.** It is found by its shape (`4.5:1`) rather than by the words around it, because the deliverable is written in the user's language. Rewrite the shape and the check goes quiet — it degrades to no check, never to a wrong one. Same property as the paths-table lookup, and for the same reason.

**Do not grep for `data-region="..."` to find region names.** The runtime marker is written once, inside the container, as an expression. The only literal occurrence in a healthy tree is the annotation layer's own display text — grepping for it finds the label, not a region. Read the ids off the container's call sites instead; keep a separate grep for literal markers, because those mean somebody wrote a raw element and skipped the type check entirely.

## What this version can and cannot see

The asset layer in this version ships only the allowlist type and the structural container. So:

- The token-file checks run only if the project already has a token source
- The declaration-table check needs both `design.md` and the token file; with either missing it skips and says which one
- The "asset layer matches the region tree" check compares against the container, not against a shell
- The two agent-judgement checks are available but must be requested; they are not part of the cheap path

Say which checks ran and which were skipped. A green report that silently skipped half its checks is worse than a red one.

## Before you call this done

- [ ] The script actually ran, with real output pasted — not just written
- [ ] Every skipped check is named, with the reason
- [ ] If any warnings printed, they are reported as warnings — not folded into "no drift found" because the exit code was 0
- [ ] Every finding names the clause it violates
- [ ] Nothing was auto-fixed
- [ ] The script is committed to the user's repo and works without an agent
