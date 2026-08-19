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
| No `layout.md` | **Report "there is no contract to check" and stop.** Offer to build one; don't invent one to check against |
| `layout.md` exists, no asset layer | **Check the document layer only**, and say which checks were skipped and why |
| Code contains region markers but no `layout.md` | Report it as the finding it is: the code has a structure nobody wrote down |

## It reports; it does not fix

Fixing means changing structure, which means walking the placement decision tree — a decision that belongs to a human, not to a drift detector. Auto-fixing also inverts the sync order the whole method rests on: documents change first, code follows.

So the output is **differences plus suggestions**, and the suggestion always names the clause that was violated.

## Cheap enough to run often

The value of a health check is inversely proportional to what it costs to run. It has to be cheap enough for every release, ideally cheap enough for CI. So the **body is automated checks; agent judgement is the supplement, never the substance.**

| Check | How | Automated |
|---|---|---|
| Region names in code ⊆ allowlist | type-check + grep the runtime markers | full |
| `as any` / literals bypassing `RegionId` | grep | full |
| Hardcoded color values in feature code | regex | full |
| `design.md` holding literal values | regex | full |
| Every allowlist row has a "must not hold" cell | parse the table | full |
| Asset layer's containers match the region tree | structural comparison | full |
| Is the decision tree still total for the last N features? | walk real commits through the tree | agent |
| Do region descriptions say "what goes here" rather than "what this is"? | semantic judgement | agent |

The first six cover roughly eight tenths and can run in CI. **If that ratio ever drops much below eight tenths, this unit has degenerated into subjective re-reading and its value claim fails** — that is its stated revisit condition, not a slogan.

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
