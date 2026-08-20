---
name: ui-contract-audit
description: Health-check an existing UI contract for drift. Runs automated checks that region names in code stay inside the allowlist, that the RegionId type is not bypassed by casts, that no color values are hardcoded past the token file, and that design.md carries no literal values - then reports the differences with fix suggestions and fixes nothing automatically. Produces a runnable script that lives in the repo and works in CI. Use when a project already has a layout.md or design.md and someone asks whether the spec is still in force, whether the code and the spec have drifted apart, what broke since the contract was written, or wants the contract checked before a release. Chinese: 界面规范还在起作用吗/规范和代码对不上了/检查界面契约/规范漂移/区域名违规/契约体检.
---

# Health check

Produces a **runnable script** in the user's repo (starting point: [assets/audit.sh.template](assets/audit.sh.template)) plus a difference report. This is the only unit here whose artifact is executable rather than markdown.

For the deliverable's language and terminology, call the Skill tool with "deliverable-language".

## Preconditions
**Artifact paths come from `docs/ui-contract/config.md`'s paths table.** If that file doesn't exist, the specs are at the repo root. Never assume a path the config contradicts.


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
| 3 | a contract *is* configured, but the paths in the script and the paths table disagree — in either direction |

`2` and `3` read almost the same in a terminal and are opposite conclusions: `2` says this project has no contract, `3` says it has one and this script is pointed at the wrong place. Sharing an exit code makes a broken setup look like a clean project, which is the one failure this whole unit exists to prevent. Keep them apart when you adapt the template, and report exit 3 as a finding, never as "nothing to check".

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
| Every allowlist row has a "must not hold" cell | parse the table | full |
| Every declared name is findable in code | grep each name | full |
| Have **sizes** moved to the token file? | semantic judgement | agent |
| Is the decision tree still total for the last N features? | walk real commits through the tree | agent |
| Do region descriptions say "what goes here" rather than "what this is"? | semantic judgement | agent |

Seven of ten run automatically and fit in CI. **If that ratio drops much below eight tenths, this unit has degenerated into subjective re-reading and its value claim fails** — that is its stated revisit condition, not a slogan. It currently sits at seven tenths, and the reason is recorded rather than rounded away:

**Sizes cannot be checked by regex.** A visual spec legitimately discusses numbers — in prose ("no writing off-table px sizes in feature code"), and in anti-pattern rows ("six months in you'll have 13px / 13.5px / 15px at once"). Measured against a real spec, a px regex produced four hits and **all four were false positives**. A check that cries wolf on correct documents is worse than no check, because people stop reading the output. Colours stay automated: a hex code in a visual spec is unambiguous.

**Do not grep for `data-region="..."` to find region names.** The runtime marker is written once, inside the container, as an expression. The only literal occurrence in a healthy tree is the annotation layer's own display text — grepping for it finds the label, not a region. Read the ids off the container's call sites instead; keep a separate grep for literal markers, because those mean somebody wrote a raw element and skipped the type check entirely.

## What this version can and cannot see

The asset layer in this version ships only the allowlist type and the structural container. So:

- The token-file checks run only if the project already has a token source
- The "asset layer matches the region tree" check compares against the container, not against a shell
- The two agent-judgement checks are available but must be requested; they are not part of the cheap path

Say which checks ran and which were skipped. A green report that silently skipped half its checks is worse than a red one.

## Before you call this done

- [ ] The script actually ran, with real output pasted — not just written
- [ ] Every skipped check is named, with the reason
- [ ] Every finding names the clause it violates
- [ ] Nothing was auto-fixed
- [ ] The script is committed to the user's repo and works without an agent
