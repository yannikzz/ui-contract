# Examples

Real output from this skill, not hand-written illustrations. Reading one is the fastest way to understand what the skill actually produces.

**`admin-console` was partially regenerated on 2026-08-25.** What that means, precisely, because the distinction is the whole value of this directory:

| | |
|---|---|
| **Regenerated** by following `ui-contract-assets`, `ui-contract-enforce` and `ui-contract-wireframe` | the asset layer (it now holds the four prohibition types), `src/ui-contract.assert.ts`, `src/tokens.css`, the wireframe's `inspect.tsx` / `wire.tsx` / colour conversion, `check-colours.sh`, and every path that moved |
| **Untouched, from the original 2026-08-21 run** | `layout.md`, `design.md`, the ten layout ADRs, the fixtures, the page files' structure, and Appendix C's traces |

It is **not** a hand-patch made to look like current output, and it is **not** a from-scratch re-run either. Calling it either one would be false, so it is called what it is. The rule it obeys is the one below: never edit this to *look* right.

### A declared deviation: the workbench is committed here

The skill now puts the wireframe in `.ui-contract-local/`, and a real project **gitignores that directory** — rehearsal does not go in the repository. This example commits it anyway, and says so in its own `.gitignore`.

The reason is that the two have different jobs. **A user's project exists to be run; an example exists to be read.** Ignoring the workbench here would delete the most-read part of the example from git and leave a directory listing behind. The deviation is not the problem — an undeclared deviation would be.

⚠ One consequence, stated rather than discovered later: `ui-contract-audit`'s check 9a reports this repository as drifting, correctly — `.ui-contract-local/` appears in this example's `.gitignore` only inside a comment explaining why it is *not* ignored, and a comment is not an ignore rule.

**And it is not a silence any more.** The example ships `audit.sh` at its root, so the check actually runs and actually says so. Read that line as the deviation being visible, which is the whole point of declaring it — not as the deviation being wrong. No pass/fail verdict for the script as a whole is quoted here, deliberately: an exit status is the sum of every check, so a sentence naming one would go stale the next time any of them moves, and this file's one rule is that it is never edited to *look* right.

### Still behind, and named one by one

| Not in the example | Added by |
|---|---|
| The naming declaration table in `design.md`, and borrowed token names | [ADR-0005](../docs/adr/0005-originate-instrument-and-borrowed-token-names.md) |
| The pointer cut — 16 references into this plugin's own development tree still stand in the produced artifacts | `invariants.sh` check 34, landed 2026-08-26 against `skills/` only |
| **The two halves, and everything that follows from the split** — this example was produced by one uninterrupted pass, so its asset layer sits in the production tree with no sign of anyone having authorised the move, its `config.md` has neither the scope authorisation nor the staged-asset row, and nothing in it distinguishes the structural half from the visual one | [ADR-0013](../docs/adr/0013-projection-layer-and-two-halves.md) |

**About that third row.** It is the largest gap in this table, and it will not be closed by an
edit: the example is the **output** of a run, and the thing that changed is what a run does.
Closing it means producing the example again. Until then, read this example as a picture of a
finished contract, not as a picture of how one is now arrived at — the artifacts are still what
the units produce, but the *order and the staging* are not.

One part of it is worth naming separately, because it reads as correct and is not: the example's
wireframe is the **projection layer**, and the example does not say so anywhere. It calls it a
reference implementation, which describes its fidelity. Nothing in the example tells the reader
it can be thrown away and rebuilt.

**About that second row, because a check does not cover it.** Check 34 scans `skills/` and stops, because inside a skill `ADR-NNNN` can only mean this repo's development tree — a skill has no ADRs of its own. The example does: `docs/ui-contract/adr/` is the *project's* namespace and it uses the same strings. `adr/design/0002` carries both readings in one file — `ADR-0006（插件侧）` on line 14 and a bare `ADR-0006` on line 54 both mean the plugin's, while `[ADR-0001](0001-direction-and-hue-basis.md)` on line 7 is a correct relative link into the project's own. No pattern separates those three, and a warn that misfires on the correct one teaches only that the warning can be ignored — `invariants.sh` check 27 states that same reason for its own exclusion. So this is named here instead of checked.

The 16 sit in `design.md`, `docs/ui-contract/config.md`, `adr/design/0001`, `adr/design/0002`, and the four wireframe files, and **all 16 are the `ADR-00xx` shape**. 

> ⚠ **This sentence was wrong from the day it was written, and the correction is instructive.** It listed `audit.sh`, which has never held a single one; it claimed `testing/structure/invariants.sh` accounted for two of the lines, when only one file ever cited it; it omitted `adr/design/0001`; and the count itself was 17, not 16. Nothing disagreed, because nothing was comparing the prose to the tree — `CLAUDE.md`'s third recorded failure, in the same shape, about a table of statistics. It reads as correct today only because the one `invariants.sh` citation was removed on 2026-08-28 for an unrelated reason (`check-colours.sh` was re-synced from its template, and the template cannot carry such a reference — check 34 forbids it inside `skills/`), which happened to bring 17 down to 16. **A number that becomes true by coincidence was still never checked.** The figures above are measured.

A shape that slips past the pattern entirely: `.ui-contract-local/wireframe/CLAUDE.md:48` cites this file, and `examples/[a-z]` cannot match a capital `R` — check 34 was widened to `[A-Za-z]` on 2026-08-26 because of that line. It is also stale on top of being unreachable. It says the missing skin preview "is named in `examples/README.md`'s lag table"; the paragraph below says nothing is behind on the wireframe's features any more. The row it points at is gone.

**The worst of them is not a dead link.** `design.md:88` cites "ADR-0001 原则 3". `ADR-0001` *does* resolve inside this example — to `adr/design/0001`, 方向选 A 审校台, which has no 原则 3. The document with six principles is this repo's own [ADR-0001](../docs/adr/0001-plugin-positioning-and-architecture.md), which a user's checkout does not contain. Following that pointer returns a different document, not a 404, and nothing about the result says so.

Cleared by re-running the affected units, not by editing these files — "It is deliberately not hand-patched to close what remains", below.


**Nothing is behind on the wireframe's features any more.** The skin preview, the token editor (`SkinEditor`, `toHex`), the direction switch and the collapsible verification panel are all present — and the last two went the other way: they were built here first and then moved into the templates, which is what `invariants.sh` check 23 caught when the example started exporting `DemoPanel` while the template still shipped `DemoBar`.

The example also carries two things the outlines only learned from it: a **border section** with one width and three enumerated levels, and **status semantic classes** split across the two specs. Both were found by building this wireframe — it had six border roles against the spec's two, and every status label the same grey — and both are now requirements in `layout-md-outline.md` / `design-md-outline.md`.

Its `design.md` §1 also carries a **signature** (`StatusEdge`: the status class as a 3px block on the row's left edge) and a written self-check against "would this come out for any product in this category". Those are `originate`'s newer requirements, absorbed from the `frontend-design` skill's approach rather than by calling it — ADR-0009 removed that dependency, and `invariants.sh` check 28 keeps it removed.

Those names are listed one by one on purpose: `testing/structure/invariants.sh` reads this paragraph, comparing both templates against both of the example's files. Every symbol the templates export has to appear in the example or here. **Falling behind is allowed; falling behind silently is not.**

**It is deliberately not hand-patched to close what remains.** Editing it to look like current output would make the first line of this file false — the example's only value is that a real run produced it. A stated gap is honest; a hand-written illustration claiming to be real output is not.

## admin-console

**Prompt:** a user describing two Figma screenshots of an admin system in text — a 220px nav in three groups, a filter bar over a table, a 360px property panel that slides out on row click, plus a second screenshot showing a bulk-import page with no property panel and a three-step wizard. The user also mentioned that "Trash" appeared twice in the nav and suspected copy-paste.

**Deliverables are in Chinese** because the prompt was in Chinese — that is the skill's language rule in action, and it doubles as a demonstration of the `ui-contract-glossary` skill (the canonical term renderings are used consistently throughout). The structure is what matters here; the map below lets you navigate it without reading Chinese. It lists **every committed file**, scaffolding included — an inventory rather than a curated selection, so that a file's absence from it means the file is absent from the example.

```
admin-console/
├── layout.md                  659 lines — the structural spec
├── design.md                  522 lines — the visual spec
├── CLAUDE.md                   73 lines — repo-root enforcement
├── docs/ui-contract/                   — config + decision records; the specs themselves stay at the root
│   ├── config.md               97 lines — start point, authoritative paths table, and what was not verified
│   ├── adr/layout/0001-0010            — one record per heavyweight structural decision: why, what was excluded, when to revisit
│   └── adr/design/0001-0002            — the same for the visual spec. A separate numbering space on purpose, not a second copy
├── audit.sh                            — the contract health check. Reports; fixes nothing. Safe in CI, unlike the one below
├── check-colours.sh                    — wireframe colour discipline. Reports; fixes nothing. NOT a CI gate
├── src/                                — production code. Regenerating the wireframe cannot touch any of this
│   ├── tokens.css                      — the token file: the value authority. Moved out of the wireframe on 2026-08-25
│   ├── ui/region.tsx                   — asset layer: 24-name allowlist as a union type, the four prohibition types, metadata, container
│   └── ui-contract.assert.ts           — the prohibitions asserted back at the compiler; deleting one fails the build with TS2578
├── package.json                        — `build` is typecheck + vite build. `check-colours` is its own script on purpose: not a gate, and exits 2 with no workbench
├── tsconfig.json                       — strict + `noUnusedLocals` + `verbatimModuleSyntax` — what makes a deleted prohibition fail the build rather than warn
├── vite.config.ts                      — `root` is the wireframe inside the workbench; `fs.allow` has to reach back out to here, or dev 403s on production imports
├── pnpm-workspace.yaml                 — one line of pnpm 10 policy: allow esbuild's postinstall, which vite needs
├── pnpm-lock.yaml                      — committed, so this example still builds the same way later
├── .gitignore                          — node_modules, dist, *.tsbuildinfo — and deliberately **not** `.ui-contract-local/`. The deviation is argued in the file itself
└── .ui-contract-local/                 — the workbench. A real project gitignores this; the example commits it, declared above
    ├── tokens.input.json               — the brand knobs, written by the design step. Regenerating the wireframe must not wipe it
    └── wireframe/                      — runnable low-fidelity wireframe, throwaway
        ├── README.md           92 lines — what one run does and does not confirm — the toggle → what it verifies table
        ├── CLAUDE.md                   — directory-level constraints + deliberate-tradeoffs list
        ├── index.html                  — vite entry, 12 lines. No structure of its own
        ├── src/main.tsx                — mounts App and pulls in index.css. 5 lines
        ├── src/index.css               — imports the production token file: the wireframe consumes values, it owns none
        ├── src/inspect.tsx             — the apparatus, and the colour exemption itself: annotation layer + demo-panel chrome
        ├── src/wire.tsx                — neutral parts + NEUTRAL, the only other place a colour value may appear
        ├── src/structure.ts            — structural parameters + degradation as a pure function
        ├── src/fixtures.ts             — fake data at deliberate maximum density: 20 rows, truncating titles, five status kinds. **Not a spec**
        ├── src/Inspector.tsx           — the focus slot. Its constraints live on the types: `page: PageWithInspector`, `kind: InspectorKind`
        ├── src/App.tsx                 — shell + archetype routing + demo toggles, and no colour of its own
        └── src/pages/*.tsx             — one file per page archetype
```

### Worth looking at specifically

| Where | What it demonstrates |
|---|---|
| `layout.md` §1 | The placement decision tree, ending in specific region names, with an explicit "stop" branch and a reverse self-check list |
| `layout.md` §2 | The allowlist — note that **every row has a "must not hold" cell**. That column is what makes it a spec rather than a manual |
| `layout.md` §4.3 | "The wizard page has no property panel" written as a **hard rule enforced by the type system**, not as "we haven't built it yet" |
| `layout.md` Appendix C | **The §1 traces, written down** — nine inputs walked through the decision tree, four hostile and five ordinary. Two of the nine walked straight through it: a page-level action had no leaf anywhere in the tree even though three other chapters promised it one, and a trunk branch had no else. Neither hole was visible by reading the document — it has a tree, an explicit stop, and a reverse checklist. **Having a tree and having a total tree are different things, and only inputs separate them** |
| `layout.md` Appendix B | Overturned decisions — including B-1, which records that duplicate "Trash" was judged a mockup artifact **and states the condition under which that judgement should be reversed** |
| `src/ui/region.tsx` | The allowlist as `RegionId`, plus `TableColumnKind` deliberately omitting `actions` and `PageWithInspector` containing only `'list'` — violations become unwritable. All of it in the **production** tree, so the prohibitions reach code that ships. They used to sit in the wireframe, where they constrained nothing |
| `src/ui-contract.assert.ts` | The other direction. A union only stops code from *using* a forbidden member; nothing stops someone *adding it back*. Each `@ts-expect-error` here goes unused the moment a prohibition is deleted, and `tsc` fails — measured: restoring `'actions'` gives `error TS2578` |
| `.ui-contract-local/wireframe/src/inspect.tsx` | The colour exemption as a **file** rather than a comment marker. Its exports are a closed declared list, so moving a product component in — which would buy it the right to hardcode colour — has to be written down |
| `.ui-contract-local/wireframe/CLAUDE.md` | The deliberate-tradeoffs list, which exists to stop the next agent from "fixing" things left out on purpose |
| `docs/ui-contract/adr/layout/` | Ten records, each stating the decision, **the alternatives excluded and why**, the cost knowingly accepted, and a named revisit condition. They state the decision and point at the clauses that carry it — 0006 cites §5.4 rather than copying its three tests — so `layout.md` stays the single authority for what is currently correct |
| `docs/ui-contract/config.md` | The paths table every unit reads instead of guessing — and a **Not verified this round** section, which is what separates a measured value from a plausible one |

### Verified

Run from `admin-console/` — the project root holds the deps and the build config; the wireframe is one directory inside the workbench.

```
pnpm typecheck      →  clean          (2026-08-27)
pnpm check-colours  →  clean          175 colour classes converted to var(--wire-*)
pnpm build          →  clean          tsc --noEmit + vite build, 374ms
```

`check-colours` is deliberately *not* part of `build`. Its own header says it is not a CI gate,
and it exits 2 when the workbench is absent — which, in a project that ignores `.ui-contract-local/`
as it should, is every fresh clone. Chaining it into `build` works here only because this example
commits its workbench, and copying that chain into a real project buys a build that fails on clone.
Run it deliberately instead.

Both directions of the enforcement claim were tested by breaking them, not by reading them:

```
# an off-allowlist region name written into a page
error TS2322: Type '"totally-made-up-region"' is not assignable to type 'RegionId'

# the prohibition itself deleted — 'actions' restored to TableColumnKind
src/ui-contract.assert.ts(24,1): error TS2578: Unused '@ts-expect-error' directive.

# a colour value written outside NEUTRAL and inspect.tsx
✗ .ui-contract-local/wireframe/src/pages/ListPage.tsx:219: const leak = "#2563eb"
```

The second one is the one worth noticing. Before the assertion file existed, deleting a prohibition compiled cleanly and changed nothing visible.

### Caveats

- **Rendered output: viewed 2026-08-21, by an agent driving a browser — not by a human.** `pnpm dev` was started and the P1 list page screenshotted at 1464px. What that confirms: it renders with no console errors, the density is real (20 rows, long Chinese titles, six columns), and the live degradation readout is present and reporting (`外壳实测 1464 · 导航 220 (full) · 主区 1244 · 阈值 640 · 降级: 未触发`). What it does **not** confirm: the other three archetypes, the degradation cascade at narrower clamps, or any aesthetic judgement. Those still need a person — see the "toggle → what it verifies" table in `.ui-contract-local/wireframe/README.md`.
- The old wording here was "never viewed by a human", which quietly implied *nobody could*. With browser tooling available an agent can look, and it should — the wrap-up advice in `ui-contract-wireframe` still assumes it cannot, and that assumption is now wrong more often than it is right.
- This was produced in a single non-interactive pass (the user said "I'm in a hurry, go with your recommendations"). A real run interviews the user one question at a time, so the decision table would be shorter and the answers would be theirs.
