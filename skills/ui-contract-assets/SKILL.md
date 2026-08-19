---
name: ui-contract-assets
description: Build the asset layer that lives in a project's production tree - the region-name allowlist as a RegionId union type, region metadata, and the structural container that stamps a runtime region marker. Long-lived code that business features import from, following the project's own stack. Use after the structural spec exists and before any wireframe or feature code is written.
---

# Asset layer

Produces **production code**, not a demo. It goes into the project's own source tree, follows the project's own stack, and is maintained for as long as the product lives. Starting point: [assets/region.tsx.template](assets/region.tsx.template).

For pushing rules into the type system, call the Skill tool with "constraint-by-types".
For the deliverable's language and terminology, call the Skill tool with "deliverable-language".

## Preconditions
**Artifact paths come from `docs/ui-contract/config.md`'s paths table.** If that file doesn't exist, the specs are at the repo root. Never assume a path the config contradicts.


| Condition | Action |
|---|---|
| `layout.md` does not exist | **Stop.** There is no allowlist to encode. Call the Skill tool with "ui-contract-layout" first |
| `layout.md` §2 has no "must not hold" column | **Stop and say why.** That column is the only part of the allowlist the type system can act on; without it this layer is just a renamed div |
| Code already contains region markers or a `RegionId`-like type, but `layout.md` does not exist | **Stop and say so.** Deriving the type from the code inverts the sync order permanently |
| `layout.md` exists but there is no `design.md` and no token file | **Produce the structural components only, and say explicitly that the token layer is missing.** Do not invent a default token set to fill the gap |

## What this version contains

| In | Out |
|---|---|
| `RegionId` union type | Token file generation |
| `REGION_META` (label + "what goes here / what must not") | `Shell` and `Slot` structural components |
| `Region` — the structural container that stamps the runtime marker | Stacks other than React |

`Shell` and `Slot` are named in the architecture but **do not exist yet**. Say so rather than improvising them: a structural component invented here, without a spec clause behind it, is the drift this layer exists to prevent.

## Where it goes

Into the project's existing source tree, beside the code that will import it — not into a separate directory, and **not** into the wireframe. The wireframe imports *from* here; nothing here imports from the wireframe.

If the project has no frontend source tree yet, ask where it will live rather than guessing. That is a fact the user has and you don't.

## No brand visuals, no annotation affordances

Neither belongs here, for two different reasons:

- **Brand values** live in the token file, which is the single value authority. A component carrying its own colors becomes a second one.
- **Annotation** (region badges, inspect tooltips) belongs to the wireframe, which is throwaway. Shipping inspect-mode machinery into production code means production carries a debugging affordance forever, and a wireframe-specific palette with it.

## Type-checking is not optional

The allowlist becomes enforceable **only** when type-checking actually runs. Install, type-check, and **paste the real output**. If the environment can't install dependencies, say explicitly that the compile-time layer is unverified and the user must run it locally.

## Before you call this done

- [ ] The `RegionId` union matches `layout.md` §2 exactly — same names, no extras, none missing
- [ ] `REGION_META` descriptions say "what goes here / what must not", not "what this is"
- [ ] Every region renders a runtime marker; grep each allowlist name in the code and find it
- [ ] Type-checking actually ran, with output pasted
- [ ] No color values, no annotation code
