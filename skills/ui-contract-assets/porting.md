# Porting the asset layer to another stack

Read this **when the project is not React + TypeScript**, and not before — nothing here
changes what the layer contains, only how the container stamps its marker. The rules that
hold on every stack are in `SKILL.md`.

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

⚠ **On React Native, `testID` is not ours.** It is the platform's standard e2e hook,
so "a `testID` outside the container" is evidence of a test, not of a bypass. Tell
`ui-contract-audit` by setting `MARKER_EXCLUSIVE="no"`; its check 2b then reports
that it cannot answer instead of printing a green tick. Measured: with that check
still looking for `data-region`, an RN screen containing
`<View testID="sidebar" />` — off the allowlist, never through the container —
produced three green ticks.

Whichever stack, tell the health check what to look for. Its five stack-shaped knobs
are at the top of `audit.sh`: `SRC_EXT`, `MARKER`, `MARKER_EXCLUSIVE`, and the pair
`COLOUR_NOTATION` / `COLOUR_NAMED`. Each one is a fact the script cannot look up.

⚠ **Paths are not knobs, and must not become knobs.** `REGION_TYPE`, `REGION_COMPONENT`,
`SRC` and the rest are *derived at run time* from `config.md`'s paths table — so porting
to a new stack means editing that table, not this script. The template's header records
why, with the measurement: an `SRC` knob pointed at the production tree reported every
allowlist name as "declared but never rendered"; pointed at the wireframe it reported
the wireframe's own NEUTRAL map as hardcoded-colour drift. Neither was a bug in a check.
