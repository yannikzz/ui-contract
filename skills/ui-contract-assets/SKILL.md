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

**One artifact is deliberately not in that table: `tokens.input.json` is always at `docs/ui-contract/tokens.input.json`.** Read it there and nowhere else. It is a working record of where the knobs were left, not a spec, so it sits beside `config.md` rather than moving with the specs — `originate` writes it to exactly that path (`ui-contract-design/originate.md` §The output lands as `tokens.input.json`). Do not search the paths table for it and do not treat its absence from that table as "the project chose somewhere else"; the location is fixed, not chosen.


| Condition | Action |
|---|---|
| `layout.md` does not exist | **Stop.** There is no allowlist to encode. Call the Skill tool with "ui-contract-layout" first |
| `layout.md` §2 has no "must not hold" column | **Stop and say why.** That column is the only part of the allowlist the type system can act on; without it this layer is just a renamed div |
| Code already contains region markers or a `RegionId`-like type, but `layout.md` does not exist | **Stop and say so.** Deriving the type from the code inverts the sync order permanently |
| `layout.md` exists, there is no token file, but `docs/ui-contract/tokens.input.json` exists | **Land the token file from it** — see below. This is the `originate` branch handing over |
| Same, but the file turns up somewhere else — the repo root, beside the specs | **Land from it, and say where you found it.** Runs from before the location was pinned put it in two different places; reporting "missing" because it is not at the pinned path would throw away the only record of the user's knobs. Do not move it silently either — say where it is and let the user decide |
| `layout.md` exists but there is no `design.md`, no token file and **no `tokens.input.json` anywhere** | **Produce the structural components only, and say explicitly that the token layer is missing.** Do not invent a default token set to fill the gap |

## What this version contains

| In | Out |
|---|---|
| `RegionId` union type | `Shell` and `Slot` structural components |
| `REGION_META` (label + "what goes here / what must not") | Multi-stack mapping tables shipped with the plugin |
| `Region` — the structural container that stamps the runtime marker | |
| The token file, landed from `tokens.input.json` | |

The starting template is React + TypeScript. **That is a starting point, not the supported set** — see below.

`Shell` and `Slot` are named in the architecture but **do not exist yet**. Say so rather than improvising them: a structural component invented here, without a spec clause behind it, is the drift this layer exists to prevent.

One thing is waiting on them: implementing the spec's size-degradation rules was ruled to belong to this layer, and is parked in `ui-contract-wireframe` only because there is no `Shell` to hold it. Whoever builds `Shell` takes that with it — ADR-0003, deferred item 9.

## Following the project's stack

This layer goes into the **user's production tree**, so it follows the stack that is
already there. The template is React + TypeScript because one of them had to be
written down first, not because the mechanism is React's.

Three things have to survive the port, and only the third is stack-shaped:

| | What it is | How it ports |
|---|---|---|
| `RegionId` | the allowlist as a union type | any stack with TypeScript — measured below |
| `REGION_META` | `Record<RegionId, …>`, exhaustiveness-checked | same |
| `Region` | the container, and the **runtime marker it stamps** | this is where stacks differ |

### Measured, not assumed (2026-08-25)

Two non-React ports were built and type-checked for real. Both caught an
off-allowlist region name at the call site, which is the whole mechanism:

| | Checker | Off-allowlist name |
|---|---|---|
| **Vue 3 SFC** | `vue-tsc` | `error TS2322: Type '"sidebar"' is not assignable to type 'RegionId'` |
| **React Native** | `tsc` | `error TS2322: Type '"sidebar"' is not assignable to type '"app-shell" \| …'` |

Vue splits the file in two — `regions.ts` for the type and metadata,
`Region.vue` for the container — because an SFC cannot export a type cleanly.
That split is the only structural change either port needed.

### The runtime marker is the part that changes

```
React / Vue / Svelte     data-region={id}   /   :data-region="id"
React Native             testID={id}  (and accessibilityLabel={id})
```

Use the **identical string**, never a more readable name — the marker is what lets
grep reconcile the code against the spec, and a prettier name breaks that silently.

⚠ **On React Native, `testID` is not ours.** It is the platform's standard e2e hook,
so "a `testID` outside the container" is evidence of a test, not of a bypass. Tell
`ui-contract-audit` by setting `MARKER_EXCLUSIVE="no"`; its check 2b then reports
that it cannot answer instead of printing a green tick. Measured: with that check
still looking for `data-region`, an RN screen containing
`<View testID="sidebar" />` — off the allowlist, never through the container —
produced three green ticks.

Whichever stack, tell the health check what to look for. Its four stack-shaped
knobs are at the top of `audit.sh`: `SRC_EXT`, `REGION_TYPE`, `REGION_COMPONENT`,
`MARKER` / `MARKER_EXCLUSIVE`.

### No type system: say the compile-time layer is gone

On plain JavaScript there is no union type, so `RegionId` cannot fail a build. The
allowlist still exists as data and check 1 still reads call sites, but enforcement
drops from three layers to two.

**Say this out loud in the report.** Do not ship a `RegionId` written as a JSDoc
comment and describe the result as enforced — a constraint nothing evaluates is a
note, and calling it enforcement is the failure this whole layer exists to prevent.

## Landing the token file

`docs/ui-contract/tokens.input.json` is where the user left the knobs. It is **an input record, not the value authority** — the token file this step writes is. When they disagree, the token file wins.

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
