---
name: ui-contract-enforce
description: Install the enforcement that stops a coding agent putting a new feature in the wrong place - an entry clause in the repo-root CLAUDE.md, a directory-level clause, the region-name allowlist compiled into a union type, and an asset boundary forbidding hardcoded token values and locally-declared structural containers. Use once the structural spec exists.
---

# Enforcement

Produces edits to the repo-root `CLAUDE.md` and to the type layer. No new document.

For pushing rules into the type system, call the Skill tool with "constraint-by-types".
For the interview discipline, call the Skill tool with "decision-interview".
For the deliverable's language and terminology, call the Skill tool with "deliverable-language".

## Preconditions
**Artifact paths come from `docs/ui-contract/config.md`'s paths table.** If that file doesn't exist, the specs are at the repo root. Never assume a path the config contradicts.


| Condition | Action |
|---|---|
| `layout.md` does not exist | **Stop.** There is nothing to enforce |
| `layout.md` §2 has no "must not hold" column | **Stop, and say why that column is required.** It is the only part of the allowlist that becomes a compile-time constraint. Without it, enforcement degrades to "please read the document" |
| A `RegionId`-like type exists in code but `layout.md` does not | **Stop and say so.** Enforcing a type that was derived from the code locks in whatever the code already does |

There is no wireframe precondition. Enforcement depends on the allowlist, not on anything being drawn — it runs fine in a repo that has never had a wireframe.

## The one question this unit asks

**How hard should enforcement be?**

| Option | You get | You lose |
|---|---|---|
| Decision tree up front + `CLAUDE.md` hard constraint + allowlist as a union type (recommended) | Zero extra tooling, and one layer is compile-time | — |
| Plus a validation script or lint rule | Hardest | With only a wireframe existing there isn't much to validate yet — easy to build too early |
| Documentation only | Lightest | Agents don't read a document nobody told them to read — least of all when the task sounds small |

## The layers

Documents alone don't get read — least of all when the task sounds small ("just adding a button"). Miss a layer and things leak through.

| Layer | How |
|---|---|
| **Entry** | A section in the repo-root `CLAUDE.md`: before changing any interface structure, walk `layout.md` §1; stop and use the change process if it doesn't land; every region name must be in the allowlist |
| **Directory** | A `CLAUDE.md` inside the wireframe (if there is one): what to read before touching anything, the deliberate-tradeoffs list, which file is the single source for structural parameters |
| **Compile time** | Allowlist → union type. Writing a name that isn't in the table fails type-checking |
| **Asset boundary** | Token values must not be hardcoded in feature code — they come from the token file. Structural containers must be imported from the asset layer, never re-declared locally |

The asset boundary is the newest layer and the least obvious. Layering the specs into production code created a new drift surface: the asset layer is real production code, so business pressure pushes changes into it directly — someone adds a slot to a container to ship a feature, and the spec never hears about it. The boundary clause is what makes that visible at review time.

## The three forms of the allowlist

| Form | Where | For |
|---|---|---|
| Table (responsibility / must hold / must not hold) | `layout.md` §2 | Humans and agents reading |
| Union type | The asset layer | The compiler |
| Metadata (label + description) | The asset layer | The annotation layer |

Put a line at the top of `layout.md` §2 saying that changing the table requires changing both of the others.

## Before you call this done

- [ ] Region names are identical across the document, the type definition, and the code — grep every allowlist name and find it in all three
- [ ] The repo-root `CLAUDE.md` entry clause exists and names the decision tree by section
- [ ] Every "must not hold" entry that can be expressed as a type omission has been, with a comment marking the omission deliberate
- [ ] The asset boundary clause is written, and it names both halves (no hardcoded token values; no locally-declared structural containers)
