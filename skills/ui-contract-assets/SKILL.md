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
| `layout.md` exists, there is no token file, but `tokens.input.json` exists | **Land the token file from it** — see below. This is the `originate` branch handing over |
| `layout.md` exists but there is no `design.md`, no token file and no `tokens.input.json` | **Produce the structural components only, and say explicitly that the token layer is missing.** Do not invent a default token set to fill the gap |

## What this version contains

| In | Out |
|---|---|
| `RegionId` union type | `Shell` and `Slot` structural components |
| `REGION_META` (label + "what goes here / what must not") | Stacks other than React for the *components* |
| `Region` — the structural container that stamps the runtime marker | Multi-stack mapping tables shipped with the plugin |
| The token file, landed from `tokens.input.json` | |

`Shell` and `Slot` are named in the architecture but **do not exist yet**. Say so rather than improvising them: a structural component invented here, without a spec clause behind it, is the drift this layer exists to prevent.

One thing is waiting on them: implementing the spec's size-degradation rules was ruled to belong to this layer, and is parked in `ui-contract-wireframe` only because there is no `Shell` to hold it. Whoever builds `Shell` takes that with it — ADR-0003, deferred item 9.

## Landing the token file

`tokens.input.json` is where the user left the knobs. It is **an input record, not the value authority** — the token file this step writes is. When they disagree, the token file wins.

Two things come out of `config.md`'s paths table and neither is guessed:

| From config | Used for |
|---|---|
| Token source (path) | where the file goes |
| Token source (format) | how it is written — CSS custom properties, `theme.extend`, a theme object |

**The keys keep their names.** Mapping changes the format only. `background` stays `background` whether it lands as `--background`, a `theme.extend` key, or a field on a theme object — that is the entire point of borrowing the names, and renaming during the mapping throws it away.

If the format column is empty, ask. Inferring it by reading the file works most of the time, and the times it works nobody can tell it was inferred.

**Do not write values this file has no source for.** A token named in `design.md`'s declaration table but absent from the JSON is a gap: land the file without it and say which names are missing. Filling them in with plausible values recreates exactly the second value authority this layer exists to prevent.

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
- [ ] If a token file was landed: its keys match the declaration table's names exactly, and any name the JSON had no value for is named as missing rather than filled in
- [ ] No color values invented anywhere; no annotation code
