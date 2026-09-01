---
name: ui-contract-assets
description: Build the asset layer that lives in a project's production tree - the region-name allowlist as a RegionId union type, region metadata, and the structural container that stamps a runtime region marker. Long-lived code that business features import from, following the project's own stack. Use after the structural spec exists and before any wireframe or feature code is written.
---

# Asset layer

Produces **production code**, not a demo. It ends up in the project's own source tree, follows the project's own stack, and is maintained for as long as the product lives — **and because of that, it does not arrive there unasked**: see §Where it lands, and when. Starting point: [assets/region.tsx.template](assets/region.tsx.template).

For pushing rules into the type system, call the Skill tool with "constraint-by-types".
For what each artifact owns — and why this layer is an asset while the wireframe is a projection — call the Skill tool with "ui-contract-glossary".
For the deliverable's language and terminology, call the Skill tool with "deliverable-language".

## Preconditions
**Artifact paths come from `docs/ui-contract/config.md`'s paths table.** If that file doesn't exist, the specs are at the repo root. Never assume a path the config contradicts.

**This unit does not read `tokens.input.json`.** That file is a local, uncommitted knobs record for the tuning instrument; the values live in the **token file**, which the paths table names and which `ui-contract-design`'s `originate` branch writes. Reading the record and re-deriving the authority from it was a real hop in an earlier version and it is gone — the read-the-record hop landed 2 of 5 measured runs (2026-08-25), and on a project that keeps its workbench out of the repository the record does not survive a clone at all. Consume the token file, exactly as production code does.


| Condition | Action |
|---|---|
| `layout.md` does not exist | **Stop.** There is no allowlist to encode. Call the Skill tool with "ui-contract-layout" first |
| `layout.md` §2 has no "must not hold" column | **Stop and say why.** That column is the only part of the allowlist the type system can act on; without it this layer is just a renamed div |
| Code already contains region markers or a `RegionId`-like type, but `layout.md` does not exist | **Stop and say so.** Deriving the type from the code inverts the sync order permanently |
| `layout.md` and a token file both exist | Normal path. **Consume the token file; do not rewrite it.** Values are not this unit's to author |
| `layout.md` exists, there is no token file, but a `tokens.input.json` turns up anywhere | **Legacy handover from before `originate` wrote the token file itself.** Land the token file from it *once*, say where the record was found, and say in the report that the record is no longer the source. Do not move or delete the record silently — throwing away the only trace of the user's knobs is worse than an untidy tree |
| `layout.md` exists but there is no `design.md`, no token file and no knobs record anywhere | **Produce the structural components only, and say explicitly that the token layer is missing.** Do not invent a default token set to fill the gap. This is the **normal** state before the visual half runs, not a broken one — and it is why a second pass exists, below |

## Where it lands, and when

This is production code, so **it does not go into somebody's production tree before they say so.**
Until then it is staged in the workbench, at the `asset-staged` path in `config.md`; the
`asset-layer` row holds `none yet` until the move, then holds the real path.

Staging costs nothing that exists yet. The compile-time layer only constrains **feature code**,
and before the structural half is signed off there is none — so a type sitting in the workbench
for a few days guards exactly as much as one sitting in `src/` would: nothing. What it buys is
that nobody wakes up to long-lived code in their tree that they never approved.

**Say which of the two states it is in**, every time, and never write the production path into
`asset-layer` before the files are actually there. A path in that column that is not on disk is
what `ui-contract-audit` reports as a broken setup.

## The second pass is normal, not a repair

On a greenfield project this unit runs **twice**, and both runs are correct:

| Pass | State | What it does |
|---|---|---|
| 1 | No `design.md`, no token file | Structural components only, staged in the workbench, token layer declared missing |
| 2 | `ui-contract-design` has since written the token file | Consume it. **Do not rewrite it** — values are not this unit's to author |

**Whichever pass moves the layer into the production tree closes the staged cell.** Write the real
path into `asset-layer` and set `asset-staged` back to `none yet`, in the same edit that moves the
files. Leaving both filled leaves a copy behind in the workbench — and the workbench is never
committed, so that copy diverges from the production one without ever appearing in a diff or a
review. `ui-contract-audit` check 9c reports exactly that state; do not make it the thing that
finds out.

Pass 2 is reached by being called again, not by anything remembering to come back. That pointer
lives in `ui-contract-design`'s completion list, because that is the unit that knows the token
file just landed.

## What this version contains

| In | Out |
|---|---|
| `RegionId` union type | `Shell` and `Slot` structural components |
| `REGION_META` (label + "what goes here / what must not") | Multi-stack mapping tables shipped with the plugin |
| `Region` — the structural container that stamps the runtime marker | |
| **Every other closed set the spec declares, and every prohibition expressed as an omission from one** | |
| The token file, landed from `tokens.input.json` | |

### The prohibition types belong here, not in the wireframe

`layout.md` declares more closed sets than the region allowlist — which page archetypes exist, which of them may carry a property panel, which column kinds a table may hold. Each one that encodes a prohibition ("the wizard page has no property panel", "there is no actions column") becomes an omission from a union, per `constraint-by-types` §2.

**Those unions go in the asset layer.** It is tempting to declare them next to the display code that first needs them, and a wireframe is usually what first needs them — but a union that lives in the wireframe constrains only the wireframe. The wireframe is a throwaway reference implementation; the prohibition it enforces is one the *product* has to obey. Left there, feature code can do the forbidden thing and nothing objects.

Measured: in the `admin-console` example, `PageWithInspector`, `TableColumnKind`, `InspectorKind` and `PageKind` are all declared in `wireframe/src/wire.tsx`. Every one of them is a `layout.md` clause, and none of them reaches a line of production code.

The assertion file from `constraint-by-types` §2 goes in the product tree too, and imports from here.

The starting template is React + TypeScript. **That is a starting point, not the supported set** — see below.

`Shell` and `Slot` are named in the architecture but **do not exist yet**. Say so rather than improvising them: a structural component invented here, without a spec clause behind it, is the drift this layer exists to prevent.

One thing is waiting on them: implementing the spec's size-degradation rules was ruled to belong to this layer, and is parked in `ui-contract-wireframe` only because there is no `Shell` to hold it. That parking is a **named exemption with an expiry**: whoever builds `Shell` takes the degradation rules with it, and `ui-contract-wireframe` records the same expiry from the other side. An exemption without an expiry becomes a permanent one, and this repository has watched that happen.

**Whoever builds `Shell` inherits one constraint with it.** Nothing in this layer may exist without a clause in `layout.md` behind it. That is not a style preference: it is what makes the wireframe a projection of `layout.md` rather than of the asset layer, and rebuildability rests on it. `Shell` is the first thing likely to break it, because a degradation rule has a *shape* in code that the spec does not state. Write the clause first.

## Following the project's stack

This layer goes into the **user's production tree**, so it follows the stack that is already
there. The template is React + TypeScript because one of them had to be written down first,
**not because the mechanism is React's** — two non-React ports were built and type-checked for
real, and both caught an off-allowlist name at the call site.

Three things have to survive the port and only one of them is stack-shaped: `RegionId` and
`REGION_META` port to any stack with TypeScript; **the container's runtime marker is where
stacks differ.** Whatever the stack, the marker uses the **identical string** the allowlist
uses — a more readable name breaks grep reconciliation silently — and the health check has to
be told what to look for.

**On a non-React stack, read [porting.md](porting.md) before writing anything.** It carries the
measured ports (Vue 3, React Native), the marker mapping, the file split Vue needs, and the
health-check knobs — including one case where a wrong knob printed three green ticks over a
real bypass.

### No type system: say the compile-time layer is gone

On plain JavaScript there is no union type, so `RegionId` cannot fail a build. The
allowlist still exists as data and check 1 still reads call sites, but enforcement
drops from three layers to two.

**Say this out loud in the report.** Do not ship a `RegionId` written as a JSDoc
comment and describe the result as enforced — a constraint nothing evaluates is a
note, and calling it enforcement is the failure this whole layer exists to prevent.

## The token file: consume it, do not author it

The token file is the **value authority**. `ui-contract-design`'s `originate` branch writes it; the `align` branch points at the project's existing one. Either way it is already there by the time this unit runs, and this unit's job is to build structural components that read from it.

**Do not write values into it, and do not fill gaps in it.** A token named in `design.md`'s declaration table but absent from the token file is a finding, not a task: report which names are missing and let the branch that owns values close it. Filling them in with plausible ones recreates exactly the second value authority this layer exists to prevent — and it is invisible afterwards, because a token file with invented values is byte-for-byte indistinguishable from one with derived values.

**The names do not change here.** `background` stays `background` whether the file writes it as `--background`, a `theme.extend` key, or a field on a theme object. Format is the token file's business; names belong to `design.md`'s declaration table.

### The legacy handover

On a project that predates this split there may be a `tokens.input.json` and no token file. That is the one case where this unit lands values, and it is a migration, not the normal path:

| From `config.md`'s paths table | Used for |
|---|---|
| Token source (path) | where the file goes |
| Token source (format) | how it is written — CSS custom properties, `theme.extend`, a theme object |

If the format column is empty, **ask**. Inferring it by reading a neighbouring file works most of the time, and the times it works nobody can tell it was inferred.

Afterwards, say plainly in the report that the token file is now the source and the record is not. A project left believing the record still feeds anything will keep editing the wrong file.

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
- [ ] **If this pass moved the layer into the production tree: the files are gone from the staged location, `asset-layer` names the real path, and `asset-staged` is back to `none yet`** — all three, or the workbench keeps a second copy that nothing reviews
