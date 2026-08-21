# Examples

Real output from this skill, not hand-written illustrations. Reading one is the fastest way to understand what the skill actually produces.

⚠ **`admin-console` predates ADR-0005 and ADR-0006, and has not been regenerated.** It therefore does not show two things the skill now produces:

| Not in the example | Added by |
|---|---|
| The naming declaration table in `design.md`, and borrowed token names | [ADR-0005](../docs/adr/0005-originate-instrument-and-borrowed-token-names.md) |
| The skin preview in the wireframe — `NEUTRAL`, `SKIN`, `useSkinVars`, `SkinBanner`, and the `INSPECT CHROME` block | [ADR-0006](../docs/adr/0006-wireframe-skin-preview.md) |
| The skin **editor** — `useSkin`, `SkinEditor`, `toHex` | [ADR-0007](../docs/adr/0007-wireframe-edit-panel-emits-a-prompt.md) |

Those names are listed one by one on purpose: `tests/structure.sh` reads this paragraph. Every symbol the template exports has to appear either in the example's `wire.tsx` or here. **Falling behind is allowed; falling behind silently is not.**

**It is deliberately not hand-patched to close that gap.** Editing it to look like current output would make the first line of this file false — the example's only value is that a real run produced it. A stated gap is honest; a hand-written illustration claiming to be real output is not. Closing it properly means re-running the skill.

Related, and visible in the example itself: its declared token source is a `@theme` block **inside the throwaway wireframe directory** with no colour scale at all (`docs/ui-contract/config.md`, 本轮未验证 #5). So even with a skin preview bolted on, there would be nothing for it to read. That is the same token-file gap [ADR-0004](../docs/adr/0004-token-file-gap-stated-not-pointed.md) is about.

## admin-console

**Prompt:** a user describing two Figma screenshots of an admin system in text — a 220px nav in three groups, a filter bar over a table, a 360px property panel that slides out on row click, plus a second screenshot showing a bulk-import page with no property panel and a three-step wizard. The user also mentioned that "Trash" appeared twice in the nav and suspected copy-paste.

**Deliverables are in Chinese** because the prompt was in Chinese — that is the skill's language rule in action, and it doubles as a demonstration of the `ui-contract-glossary` skill (the canonical term renderings are used consistently throughout). The structure is what matters here; the chapter map below lets you navigate it without reading Chinese.

```
admin-console/
├── layout.md                  607 lines — the structural spec
├── design.md                  350 lines — the visual spec
├── CLAUDE.md                   49 lines — repo-root enforcement
├── docs/ui-contract/                    — config + decision records; the specs themselves stay at the root
│   ├── config.md               70 lines — start point, authoritative paths table, and what was not verified
│   └── adr/layout/0001-0010            — one record per heavyweight structural decision: why, what was excluded, when to revisit
├── src/ui/region.tsx          176 lines — asset layer: 24-name region allowlist as a union type + metadata + the structural container. Production code, deliberately outside the wireframe
└── wireframe/                          — runnable low-fidelity wireframe, throwaway
    ├── src/wire.tsx           300 lines — presentation layer: annotation wrapper + neutral parts + the other hard rules as types
    ├── src/structure.ts       114 lines — structural parameters + degradation as a pure function
    ├── src/App.tsx            384 lines — shell + archetype routing + demo toggles
    ├── src/pages/*.tsx                 — one file per page archetype
    └── CLAUDE.md               70 lines — directory-level constraints + deliberate-tradeoffs list
```

### Worth looking at specifically

| Where | What it demonstrates |
|---|---|
| `layout.md` §1 | The placement decision tree, ending in specific region names, with an explicit "stop" branch and a reverse self-check list |
| `layout.md` §2 | The allowlist — note that **every row has a "must not hold" cell**. That column is what makes it a spec rather than a manual |
| `layout.md` §4.3 | "The wizard page has no property panel" written as a **hard rule enforced by the type system**, not as "we haven't built it yet" |
| `layout.md` Appendix C | **The §1 traces, written down** — nine inputs walked through the decision tree, four hostile and five ordinary. Two of the nine walked straight through it: a page-level action had no leaf anywhere in the tree even though three other chapters promised it one, and a trunk branch had no else. Neither hole was visible by reading the document — it has a tree, an explicit stop, and a reverse checklist. **Having a tree and having a total tree are different things, and only inputs separate them** |
| `layout.md` Appendix B | Overturned decisions — including B-1, which records that duplicate "Trash" was judged a mockup artifact **and states the condition under which that judgement should be reversed** |
| `src/ui/region.tsx` | The allowlist as `RegionId` — the one place it is declared, and deliberately outside `wireframe/` so regenerating the throwaway layer cannot take it along. `wire.tsx` only re-exports the type |
| `wireframe/src/wire.tsx` | `TableColumnKind` deliberately omitting `actions` and `PageWithInspector` containing only `'list'` — violations become unwritable |
| `wireframe/CLAUDE.md` | The deliberate-tradeoffs list, which exists to stop the next agent from "fixing" things left out on purpose |
| `docs/ui-contract/adr/layout/` | Ten records, each stating the decision, **the alternatives excluded and why**, the cost knowingly accepted, and a named revisit condition. They state the decision and point at the clauses that carry it — 0006 cites §5.4 rather than copying its three tests — so `layout.md` stays the single authority for what is currently correct |
| `docs/ui-contract/config.md` | The paths table every unit reads instead of guessing — and a **Not verified this round** section, which is what separates a measured value from a plausible one |

### Verified

Run from `admin-console/` — the project root holds the deps and the build config; `wireframe/` is one directory inside it.

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

- **Rendered output: viewed 2026-08-21, by an agent driving a browser — not by a human.** `pnpm dev` was started and the P1 list page screenshotted at 1464px. What that confirms: it renders with no console errors, the density is real (20 rows, long Chinese titles, six columns), and the live degradation readout is present and reporting (`外壳实测 1464 · 导航 220 (full) · 主区 1244 · 阈值 640 · 降级: 未触发`). What it does **not** confirm: the other three archetypes, the degradation cascade at narrower clamps, or any aesthetic judgement. Those still need a person — see the "toggle → what it verifies" table in `wireframe/README.md`.
- The old wording here was "never viewed by a human", which quietly implied *nobody could*. With browser tooling available an agent can look, and it should — the wrap-up advice in `ui-contract-wireframe` still assumes it cannot, and that assumption is now wrong more often than it is right.
- This was produced in a single non-interactive pass (the user said "I'm in a hurry, go with your recommendations"). A real run interviews the user one question at a time, so the decision table would be shorter and the answers would be theirs.
