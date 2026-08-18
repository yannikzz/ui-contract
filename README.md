# ui-contract

A Claude skill that turns "our UI keeps getting messier" into a spec that coding agents actually follow.

The problem it solves: teams have a design system (colors, type, spacing) but nothing that answers **"where does this new feature go?"** So every new feature lands wherever the last agent felt like putting it, and six months later the structure is unrecoverable.

## What it produces

| Artifact | Owns | Test |
|---|---|---|
| `layout.md` | **Structure** — region tree, page archetypes, extension-slot enumerations, content routing, switching rules | Things that **don't** change when you swap the brand skin |
| `design.md` | **Visual** — type, color, shadow, radius, spacing scale, interaction states | Things that **do** change when you swap the brand skin |
| A wireframe | The runnable reference implementation of both, deliberately carrying **no brand visuals** | Agents copy structure instead of guessing it |

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

**By hand** — copy `skills/ui-contract/` into wherever your agent keeps skills.

### Which agents this works in

`SKILL.md` is an open format, so the same folder works unmodified across agents. Only the
directory differs:

| Agent | Where skills live |
|---|---|
| Claude Code | `~/.claude/skills/` (you) or `.claude/skills/` (the project) |
| Windsurf | `.windsurf/skills/` |
| Cline | `.cline/skills/` |
| Others (Codex, Cursor, Gemini CLI, opencode, Aider…) | Check your agent's docs, then `./install.sh <that-path>` |

One caveat that isn't about the format: this skill's third enforcement layer turns the region
allowlist into a TypeScript union type, so **an agent that can't run a type-check gets two of the
three layers**, not three. The skill says so out loud when that happens rather than claiming the
allowlist is enforced.

## Use

Just describe the problem — the skill triggers on its own:

- "new features keep landing in random places, I want rules"
- "turn these Figma screenshots into something devs can build against"
- "stop Claude from restructuring my frontend every time it touches it"
- `/ui-contract` to invoke it explicitly

It then interviews you **one question at a time**, each with a recommendation and, more importantly, **what that choice costs you**. It looks up facts itself (your stack, your existing docs) and only asks you things that are genuinely decisions.

## Three ideas that make it work

**1. The wireframe carries no brand visuals — on purpose.** A skeleton with real colors becomes a *second source of visual truth*. Agents copy it, the design spec later changes, and now the skeleton is a stale spec that agents trust more than your documentation. A grey skeleton has nothing to copy, so it can't drift.

**2. The allowlist becomes a union type.** Every region name goes into `type RegionId = 'a' | 'b' | ...`. Writing a name that isn't in the spec fails type-checking. This generalizes: whenever the spec says "region X must not hold things of kind Y", *delete Y from the corresponding union* — then the violation is unwritable. That beats any `MUST` you could write into a document.

**3. The spec's entry point is a decision tree, not a description.** An agent walks 4–6 questions and lands on a specific region name. If nothing matches, it is told to **stop** rather than pick the closest-looking region. That single instruction prevents most structural drift.

## Language

Deliverables are written in whatever language you're speaking. `references/glossary.md` pins canonical term renderings so two projects (or two agents) don't end up with different names for the same concept.

## What's in here

```
skills/ui-contract/
  SKILL.md                        Main flow, iteration discipline, done-checklist
  references/interview.md         17 universal questions + form-factor add-ons
  references/layout-md-outline.md Structural spec: 10 chapters, what each must answer
  references/design-md-outline.md Visual spec skeleton + how to retrofit an existing one
  references/wireframe.md         Wireframe implementation, plus the traps we already hit
  references/glossary.md          Canonical term renderings per language
  assets/wire.tsx.template        Region allowlist machinery — copy and adapt
  examples/admin-console/         Real output: a full three-artifact set, type-checked and building
  evals/evals.json                Test scenarios, assertions, and findings from each round
.claude-plugin/                   Marketplace + plugin manifests (Claude Code install)
install.sh                        Cross-agent installer
```

`examples/admin-console/` is the fastest way to see what "done" looks like — including the part that's hard to describe: an allowlist where every row states what must **not** go there, and an appendix that records a judgement call along with the condition for reversing it.

## Testing it

`evals/evals.json` holds four scenarios spread across deliberately different form factors (mobile app, dashboard, desktop admin, content site) — because the biggest risk for a skill like this is smuggling in one product's information architecture as if it were universal.

One caveat if you run a with-skill / without-skill comparison: **the control group is contaminated by the skill's own description**, which names the three artifacts and the decision tree. A subagent sees that description in its available-skills listing even without invoking the skill. For a clean control, move the skill out of the skills directory first. Details in `evals/evals.json`.

## Contributing

The most valuable contributions are **scenarios where it produced a bad spec**. Open an issue with the prompt you used and what went wrong — a form factor whose region tree it got wrong is worth more than a wording fix.

Second most valuable: form-factor add-ons in `references/interview.md`. The current set covers desktop, mobile, dashboards and content sites. Anything else (TV, watch, embedded, extension popups, CLI companions) is a gap.

## Status and license

This repository is **private while the skill is being finished**, and no license has been
chosen yet. Until one is added, no permission to use, copy, modify, or distribute is
granted — default copyright applies. A license will land here before the repo goes public.

---

## 中文简介

这个 skill 解决的问题是：团队有设计系统（颜色、字体、间距），但没有任何东西回答「**新功能该放在界面哪里**」。于是每个新功能都落在上一个 agent 随手放的位置，半年后结构就烂了。

它产出三件东西——`layout.md`（结构规范）、`design.md`（视觉规范）、一份低保真线框原型作为可运行参考实现。切线只有一条：**换一套品牌视觉时会不会变**，会变的归视觉，不会变的归结构。

三个关键设计：**线框刻意不含品牌视觉**（否则会变成第二个视觉权威源，视觉规范一改它就成了过期规范，而 agent 更信眼前的代码）；**区域名白名单做成联合类型**，写表外的名字直接类型报错，规范里任何「某区域不许放某类东西」的规则都可以靠删掉对应联合类型成员来做成「写都写不出来」；**规范的入口是决策树而不是描述**，走不通时明确要求 agent **停下**，而不是挑一个最像的区域塞进去。

产物语言跟随你说话的语言。术语的固定译法在 `references/glossary.md`，避免两个项目对同一个概念用不同叫法。
