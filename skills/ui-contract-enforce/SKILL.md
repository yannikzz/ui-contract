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

## Two passes, not one

The four layers below do not become installable at the same moment, so this unit runs twice.

| Pass | When | Installs | Why it cannot wait / cannot come earlier |
|---|---|---|---|
| **1** | Inside the structural half | **Entry** and **Directory** | Both depend on `layout.md` alone. The gap before the visual half can last weeks; during it, anything that touches the interface needs something telling it to read `layout.md` first, and an unwritten entry clause tells it nothing |
| **2** | After the asset layer has moved into the production tree | **Compile time** and **Asset boundary** | Both are installed *on the production source tree*. Before the move there is no production tree to install on |

**Do not install the compile-time layer on a staged asset layer.** A union that lives outside the product constrains only what lives beside it. Measured (2026-08-25): in the `admin-console` example, `PageWithInspector`, `TableColumnKind`, `InspectorKind` and `PageKind` are all declared in `wireframe/src/wire.tsx`; every one of them is a `layout.md` clause, and **none of them reaches a line of production code**. `ui-contract-assets` records the same measurement from the other side — kept word-for-word on both sides on purpose, so the two can be compared. It type-checks, it goes green, and it guards a directory that gets deleted.

## The layers

Documents alone don't get read — least of all when the task sounds small ("just adding a button"). Miss a layer and things leak through.

| Layer | How |
|---|---|
| **Entry** | A section in the repo-root `CLAUDE.md`: before changing any interface structure, walk `layout.md` §1; stop and use the change process if it doesn't land; every region name must be in the allowlist |
| **Directory** | A `CLAUDE.md` inside the wireframe (if there is one): what to read before touching anything, the deliberate-tradeoffs list, which file is the single source for structural parameters |
| **Compile time** | Allowlist → union type, **installed on the product source tree and covered by the project's own typecheck**. Writing a name that isn't in the table fails type-checking. See below — where this runs is part of the layer, not a detail |
| **Asset boundary** | Token values must not be hardcoded in feature code — they come from the token file. Structural containers must be imported from the asset layer, never re-declared locally |

### The compile-time layer has to sit on code that ships

A union type only fires where something type-checks against it. So "the allowlist is a union type" is half a mechanism; the other half is **which typecheck it is part of**, and that half has been left implicit.

**A wireframe's typecheck does not count.** The wireframe is a throwaway reference implementation — constraining it constrains nothing that ships, and if the project keeps its wireframe out of the repository, that typecheck does not run in CI at all. Either way the layer reports nothing and looks no different from one that is working.

Two things have to be true, and both are checkable:

1. The union type lives in the asset layer, inside the **product source tree**, and the command a contributor or CI actually runs (`tsc --noEmit`, `pnpm typecheck`, whatever the project uses) covers that path.
2. Something fails **even when no product code happens to use a given region name yet**. On a young project most of the allowlist has no call sites, so an empty product tree type-checks clean against any union at all — including one somebody weakened. The assertion file in `constraint-by-types` §2 is what closes this; without it, the layer's strength is proportional to how much code already exists, which is backwards.

**Verify it by breaking it.** Put an off-allowlist name into a product file, run the project's typecheck, and paste the error. A layer nobody has seen fail is a layer nobody has seen.

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
- [ ] **Each of those omissions also has a line in the assertion file** (`constraint-by-types` §2), so deleting the prohibition breaks the build instead of going silent
- [ ] **The union type is in the product source tree, and the project's own typecheck command covers it** — name the command. A wireframe's typecheck does not satisfy this
- [ ] **The assertion file is inside that same typecheck's `include`.** Nothing imports it, so a narrow `include` drops it silently
- [ ] **Enforcement was verified by breaking it**: an off-allowlist name was written into a *product* file, the project's typecheck was run, and the real error is pasted
- [ ] The asset boundary clause is written, and it names both halves (no hardcoded token values; no locally-declared structural containers)
