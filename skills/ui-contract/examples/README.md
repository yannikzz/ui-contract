# Examples

Real output from this skill, not hand-written illustrations. Reading one is the fastest way to understand what the skill actually produces.

## admin-console

**Prompt:** a user describing two Figma screenshots of an admin system in text — a 220px nav in three groups, a filter bar over a table, a 360px property panel that slides out on row click, plus a second screenshot showing a bulk-import page with no property panel and a three-step wizard. The user also mentioned that "Trash" appeared twice in the nav and suspected copy-paste.

**Deliverables are in Chinese** because the prompt was in Chinese — that is the skill's language rule in action, and it doubles as a demonstration of `references/glossary.md` (the canonical term renderings are used consistently throughout). The structure is what matters here; the chapter map below lets you navigate it without reading Chinese.

```
admin-console/
├── layout.md                  562 lines — the structural spec
├── design.md                  349 lines — the visual spec
├── CLAUDE.md                   47 lines — repo-root enforcement
├── DECISIONS-TO-CONFIRM.md    106 lines — 22 decision points with choices and costs
└── wireframe/                          — runnable low-fidelity wireframe
    ├── src/wire.tsx           427 lines — 24-name region allowlist as a union type + metadata
    ├── src/structure.ts       114 lines — structural parameters + degradation as a pure function
    ├── src/App.tsx            384 lines — shell + archetype routing + demo toggles
    ├── src/pages/*.tsx                 — one file per page archetype
    └── CLAUDE.md               56 lines — directory-level constraints + deliberate-tradeoffs list
```

### Worth looking at specifically

| Where | What it demonstrates |
|---|---|
| `layout.md` §1 | The placement decision tree, ending in specific region names, with an explicit "stop" branch and a reverse self-check list |
| `layout.md` §2 | The allowlist — note that **every row has a "must not hold" cell**. That column is what makes it a spec rather than a manual |
| `layout.md` §4.3 | "The wizard page has no property panel" written as a **hard rule enforced by the type system**, not as "we haven't built it yet" |
| `layout.md` Appendix B | Overturned decisions — including B-1, which records that duplicate "Trash" was judged a mockup artifact **and states the condition under which that judgement should be reversed** |
| `wireframe/src/wire.tsx` | The allowlist as `RegionId`, plus `TableColumnKind` deliberately omitting `actions` and `PageWithInspector` containing only `'list'` — violations become unwritable |
| `wireframe/CLAUDE.md` | The deliberate-tradeoffs list, which exists to stop the next agent from "fixing" things left out on purpose |
| `DECISIONS-TO-CONFIRM.md` | Every row states the choice, the cost, and which sections get disturbed if it's reversed |

### Verified

```
pnpm install && pnpm typecheck   →  clean
pnpm build                       →  clean
```

The enforcement claim was tested directly: injecting an off-allowlist region name into a page produces

```
error TS2322: Type '"totally-made-up-region"' is not assignable to type 'RegionId'
```

so the compile-time layer genuinely holds.

### Caveats

- The rendered output was never viewed by a human. Layout correctness and density are unverified — see the "toggle → what it verifies" table in `wireframe/README.md`.
- This was produced in a single non-interactive pass (the user said "I'm in a hurry, go with your recommendations"). A real run interviews the user one question at a time, so the decision table would be shorter and the answers would be theirs.
