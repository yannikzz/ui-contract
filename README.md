# ui-contract

A set of Claude skills that turns "our UI keeps getting messier" into a spec that coding agents actually follow.

The problem it solves: teams have a design system (colors, type, spacing) but nothing that answers **"where does this new feature go?"** So every new feature lands wherever the last agent felt like putting it, and six months later the structure is unrecoverable.

## What it produces

| Artifact | Owns | Test |
|---|---|---|
| `layout.md` | **Structure** — region tree, page archetypes, extension-slot enumerations, content routing, switching rules | Things that **don't** change when you swap the brand skin |
| `design.md` | **Visual** — type, color, shadow, radius, spacing scale, interaction states, **as rules** | Things that **do** change when you swap the brand skin |
| Token file | The **values** those rules name. The single value authority in code | — |
| Asset layer | The allowlist as a type, plus the structural container — in your production tree, long-lived | — |
| A wireframe | The **projection layer** over the two specs and their decision records — runnable, low fidelity, brand deliberately overridden to neutral greys. Rebuildable at any time, and thrown away as freely | Agents copy structure instead of guessing it |
| Health check | A script that reports drift months later, and fixes nothing | — |

There is exactly one cut: **does it change when the brand skin changes?** Everything else follows from that.

## Install

**Claude Code** — add the marketplace once, then install:

```
/plugin marketplace add yannikzz/ui-contract
/plugin install ui-contract@yannikzz
```

Same thing from your shell, without the interactive panel:

```bash
claude plugin marketplace add yannikzz/ui-contract \
  && claude plugin install ui-contract@yannikzz
```

**Any other agent** — one line:

```bash
curl -fsSL https://raw.githubusercontent.com/yannikzz/ui-contract/main/install.sh | sh
```

Rather read the script before running it? Clone the repo and run `./install.sh` — same result.

`install.sh` takes a target: `project` for this repo's `.claude/skills/`, `windsurf`, `cline`,
or any path you name. With no argument it installs to `~/.claude/skills/`.

**By hand** — copy every directory under `skills/` into wherever your agent keeps skills.
**Install all of them.** The units call each other; a subset breaks the chain silently — the
behaviour still looks normal, it just stops following the discipline.

### Which agents this works in

`SKILL.md` is an open format, so the same folders work unmodified across agents. Only the
directory differs:

| Agent | Where skills live |
|---|---|
| Claude Code | `~/.claude/skills/` (you) or `.claude/skills/` (the project) |
| Windsurf | `.windsurf/skills/` |
| Cline | `.cline/skills/` |
| Others (Codex, Cursor, Gemini CLI, opencode, Aider…) | Check your agent's docs, then `./install.sh <that-path>` |

One caveat that isn't about the format: the third enforcement layer turns the region
allowlist into a TypeScript union type, so **an agent that can't run a type-check gets three of the
four layers**, not four. The skills say so out loud rather than claiming the allowlist is enforced.

## Use

Just describe the problem — the skills trigger on their own:

- "new features keep landing in random places, I want rules"
- "turn these Figma screenshots into something devs can build against"
- "stop Claude from restructuring my frontend every time it touches it"
- "is the spec we wrote three months ago still holding?" → goes straight to the health check

They interview you with a recommendation and, more importantly, **what that choice costs you**, look up facts themselves (your stack, your existing docs), and only ask you things that are genuinely decisions.

**You can enter anywhere.** Already have a `layout.md` and only want the enforcement? Run that unit. Each one reads its inputs from disk, so it won't re-ask what an earlier session already answered.

## Three ideas that make it work

**0. The two halves are two chains, and nothing links them.** `layout.md` is handed back and
signed off on its own; the visual spec is a separate engagement, entered again rather than
arrived at. Running straight through is how a team that asked "where does a new feature go?" gets
handed a brand they never chose — measured on this plugin, 492 lines of it. The visual half is drawn
with no incoming edge rather than guarded by a prohibition, because a prohibition can be read and
walked past, and that has been measured here too.

**1. The wireframe carries no brand visuals — on purpose.** A skeleton with real colors becomes a *second source of visual truth*. Agents copy it, the token file later changes, and now the skeleton is a stale spec that agents trust more than your documentation. A grey skeleton has nothing to copy — and the one place an agent can go for brand values is the token file.

**2. The allowlist becomes a union type.** Every region name goes into `type RegionId = 'a' | 'b' | ...`. Writing a name that isn't in the spec fails type-checking. This generalizes: whenever the spec says "region X must not hold things of kind Y", *delete Y from the corresponding union* — then the violation is unwritable. That beats any `MUST` you could write into a document.

**3. The spec's entry point is a decision tree, not a description.** An agent walks 4–6 questions and lands on a specific region name. If nothing matches, it is told to **stop** rather than pick the closest-looking region. That single instruction prevents most structural drift.

## The units

Fifteen packages in three layers. Everything is model-invoked, so they compose.

**Domain-agnostic primitives** — reusable outside UI work entirely:

| Unit | Does |
|---|---|
| [decision-interview](skills/decision-interview/SKILL.md) | One question at a time, each with a recommendation and its cost; facts are yours to find, decisions are the user's |
| [spec-before-code](skills/spec-before-code/SKILL.md) | Documents change first; holes the implementation exposes are written back; overturned conclusions move to an appendix |
| [constraint-by-types](skills/constraint-by-types/SKILL.md) | Enumerations become union types; prohibitions become deliberate omissions; type-checking must actually run |
| [decision-record](skills/decision-record/SKILL.md) | ADRs that record why, never what — and supersede instead of rewriting |
| [deliverable-language](skills/deliverable-language/SKILL.md) | Write in the user's language; pin one rendering per concept |

**Vocabulary and facts:**

| Unit | Produces |
|---|---|
| [ui-contract-glossary](skills/ui-contract-glossary/SKILL.md) | — (the cut, the term table, "don't copy someone else's IA") |
| [ui-contract-setup](skills/ui-contract-setup/SKILL.md) | `docs/ui-contract/config.md` |
| [ui-contract-baseline](skills/ui-contract-baseline/SKILL.md) | `as-built.md` — what the interface actually is today |

**Capabilities and orchestration:**

| Unit | Produces |
|---|---|
| [ui-contract-layout](skills/ui-contract-layout/SKILL.md) | `layout.md` |
| [ui-contract-design](skills/ui-contract-design/SKILL.md) | `design.md` + token references |
| [ui-contract-assets](skills/ui-contract-assets/SKILL.md) | Asset layer in the production tree |
| [ui-contract-wireframe](skills/ui-contract-wireframe/SKILL.md) | Runnable wireframe |
| [ui-contract-enforce](skills/ui-contract-enforce/SKILL.md) | Repo-root `CLAUDE.md` + type-layer constraints |
| [ui-contract-audit](skills/ui-contract-audit/SKILL.md) | Health-check script + difference report |
| [ui-contract](skills/ui-contract/SKILL.md) | — (routes to the right unit for where you are) |

## Language

Deliverables are written in whatever language you're speaking. `ui-contract-glossary` pins canonical term renderings so two projects (or two agents) don't end up with different names for the same concept.

## Repository layout

```
skills/                 The 15 packages. Only this directory is shipped to users
testing/run.sh          The two free gates — invariants and eval-suite preflight, seconds
testing/structure/      Disk invariants, plus proof that each of them can fail
testing/preflight.sh    Eval-suite schema + grader coherence, at zero cost
testing/grader-check/   Fixtures that check the graders themselves — cents per check
testing/evals/          Three end-to-end scenarios (greenfield x2 / existing project)
examples/admin-console/ A complete three-artifact set, type-checked and building
docs/adr/               Decisions about developing this plugin
docs/reference/         The plugin-eval harness reference — it has no public docs page
.claude-plugin/         Marketplace + plugin manifests
install.sh              Cross-agent installer; traverses skills/ with nothing hardcoded
packaging/              pack.sh builds dist/ui-contract-<version>.zip for people without repo access
```

`examples/admin-console/` is the fastest way to see what "done" looks like — including the part that's hard to describe: an allowlist where every row states what must **not** go there, and an appendix that records a judgement call along with the condition for reversing it. It is **not shipped with the skills**, deliberately: one product's information architecture sitting next to an agent is the single fastest way to get it copied.

## Testing it

Four gates, ordered by cost. Each one is a prerequisite for the next, and the first two are free.

```bash
./testing/run.sh                                   # gates 0 and 1 — free, seconds
claude plugin eval . --eval-dir testing/grader-check \
  --ablation none --scaffold --runs 1 --no-publish  # gate 2 — cents
claude plugin eval . --ablation with-without \
  --scaffold --allow-tools Write Edit --max-cost-usd 20   # gate 3 — ~$18
```

**Gate 0** keeps the 15 packages consistent with both manifests and the README index, and injects one violation per check to prove the check can report it — because a check that exists and a check that can fail are different things. Two review passes once found four checks in the health-check script that always returned green, all four defeated by the same thing: a JSX call site formatted across several lines.

**Gate 1** is `claude plugin eval --max-cost-usd 0`. The suite is fully loaded, schema-validated and coherence-checked, and then every run is skipped — under a second, nothing spent. Most of the way this suite used to break was configuration that only surfaced during a paid run; the harness reports it here for free. It asserts on the output rather than the exit code, because the cost-ceiling exit masks a load error.

**Gate 2** checks whether the graders can tell right from wrong at all. The agent runs nothing — real artifacts are placed into the sandbox by the scaffold — so one check costs cents instead of the $8 a full run costs. Every grader gets a matching pair: an artifact that must pass and one that must fail. That pair is the point. One grader was failing 15 votes in a row and got diagnosed as "too strict" purely because nobody had ever shown it a negative — the fix that looked right made it pass everything instead, including the negative.

**Gate 3** runs the real scenarios. `--ablation with-without` runs a genuine no-plugin control arm; an earlier hand-rolled control was contaminated because a subagent sees the skill's description in its listing even without invoking it.

The harness itself is documented at `docs/reference/plugin-eval.md`, vendored from the CLI because that surface has no public documentation page.

What deliberately has no automated coverage is listed in `testing/evals/README.md`, including one boundary that was measured rather than assumed: a grader cannot see tool calls replayed from a frozen transcript, so `tool_used` and `tool_order` assertions can only be verified by a paid run. Read that before trusting a green one.

## Contributing

The most valuable contributions are **scenarios where it produced a bad spec**. Open an issue with the prompt you used and what went wrong — a form factor whose region tree it got wrong is worth more than a wording fix.

Second most valuable: form-factor add-ons in `skills/ui-contract-layout/interview-layout.md`. The current set covers desktop, mobile, dashboards and content sites. Anything else (TV, watch, embedded, extension popups, CLI companions) is a gap.

## Status and license

This repository is **private while the skills are being finished**, and no license has been
chosen yet. Until one is added, no permission to use, copy, modify, or distribute is
granted — default copyright applies. A license will land here before the repo goes public.

---

## 中文简介

这套 skill 解决的问题是：团队有设计系统（颜色、字体、间距），但没有任何东西回答「**新功能该放在界面哪里**」。于是每个新功能都落在上一个 agent 随手放的位置，半年后结构就烂了。

它产出的东西——`layout.md`（结构规范）、`design.md`（视觉规范，只存规则）、token 文件（值的唯一权威）、进生产目录的资产层、一份低保真线框、四层强制机制，以及三个月后用来查漂移的体检脚本。切线只有一条：**换一套品牌视觉时会不会变**，会变的归视觉，不会变的归结构。

三个关键设计：**线框刻意不含品牌视觉**（否则会变成第二个视觉权威源，token 一改它就成了过期规范，而 agent 更信眼前的代码）；**区域名白名单做成联合类型**，写表外的名字直接类型报错，规范里任何「某区域不许放某类东西」的规则都可以靠删掉对应联合类型成员来做成「写都写不出来」；**规范的入口是决策树而不是描述**，走不通时明确要求 agent **停下**，而不是挑一个最像的区域塞进去。

十五个包全部 model-invoked，可以从任何一步进入——每个包从磁盘读上游产物，不重问上一步已经答过的问题。
