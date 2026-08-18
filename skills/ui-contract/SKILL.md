---
name: ui-contract
description: Establish a project's UI contract through a one-question-at-a-time interview: layout.md (structural spec: placement decision tree, region-name allowlist, extension rules), design.md (visual spec), and a low-fidelity wireframe as the reference implementation, plus enforcement that stops agents putting features in the wrong place. Use when the user wants a design system or design spec, a layout or structure spec, information architecture (IA), a module/region breakdown, rules for where a new feature goes, a way to stop a team or an AI agent from drifting the interface structure, to turn Figma mockups into something developers can build against, or an interface skeleton / wireframe for team alignment. Triggers without the word "spec" too: "new features keep landing in random places", "our UI gets messier every sprint", "make the AI stop restructuring my frontend". Chinese: 界面规范/布局规范/结构规范/信息架构/设计规范/设计系统/线框图/界面骨架/新功能该放哪/界面越改越乱.
compatibility: Works in any agent with filesystem access. The wireframe step needs Node and a TypeScript toolchain; without TypeScript the compile-time region allowlist cannot be enforced and degrades to an honor-system rule.
metadata:
  author: yannikzz
  version: "0.1.0"
---

# UI Contract

## What this produces

Three artifacts that together form a contract both humans and coding agents can follow:

| Artifact | Owns | Test |
|---|---|---|
| `layout.md` | **Structure**: region tree, column widths, page archetypes, extension-slot enumerations, content routing, switching rules | Things that **do not** change when you swap the brand skin |
| `design.md` | **Visual**: type, color, shadow, radius, spacing scale, interaction-state styling, component variants | Things that **do** change when you swap the brand skin |
| Wireframe | The runnable reference implementation of both, **deliberately carrying no brand visuals** | Agents copy structure instead of guessing it |

**There is exactly one cut: "does this change when the brand skin changes?"** Changes → `design.md`. Doesn't → `layout.md`. The same value living in two places is a drift source.

Aim for zero overlap, but **do not claim absolute zero overlap** — there is usually one or two genuine coupling points (a spacing value that determines how many grid columns fit, say; change one and you must revisit the other). Handle those by **marking them explicitly** on both sides: "⚠ changing this requires revisiting §X of the other spec — this is the only place the two specs are coupled." Naming a coupling is far safer than declaring zero overlap and letting it drift silently.

## Language

Write the deliverables in **the language the user is speaking**. Do not ask, and do not make it a configuration option — just follow their language.

If that language has an entry in `references/glossary.md`, **use the canonical terms there**. Otherwise pick one rendering per concept, record your choices in a glossary section of the structural spec, and stay consistent. The failure mode this prevents is real: the same concept translated differently on every run, so two projects can no longer talk to each other.

## The most important thing: do not copy someone else's information architecture

This skill teaches a **method**, not any product's answers. The region tree, the page archetypes, the slot enumeration, the nav segments — every project answers those **for itself**.

If any of these thoughts show up, you are already contaminating the user's product:

| Thought | Reality |
|---|---|
| "Products like this always use three columns" | Three columns was some other product's answer. Ask how many this product needs, and why |
| "The side panel should have tabs for tasks / members / details" | The enumeration comes from *this* product's first-class objects, not from your memory |
| "Let me build a reasonable default first and show the user" | Users accept defaults. That spec then stops being theirs |
| "Mobile can use the same shell" | Different form factor, entirely different region tree. See the form-factor branches in the interview |

The only things you bring in are **methods**: the cut, the decision tree, the allowlist, the enforcement layers, how to write anti-patterns.

## Flow

```
0  Identify the starting point; inventory what already exists
1  Rigorous interview (one question at a time, each with a recommendation and its cost)
2  Write layout.md            (docs first)
3  Align / slim down design.md
4  Build the wireframe        (code second — it will expose holes in the spec; write them back)
5  Install enforcement
```

**Do not reverse the order.** Wireframe first, spec second, and the spec degrades into a description of existing code rather than a constraint on future code.

---

## 0. Starting point and inventory

Look things up yourself. Do not ask the user anything you can find. Glob/Grep for:

- Existing `design.md` / `DESIGN.md` / `design-system.md` / `tokens.css` / `tailwind.config.*` / `theme.*`
- Existing `layout.md` / `IA.md` / `architecture.md` / any doc that already describes regions
- Existing prototype or frontend code: stack, component layout, whether TypeScript is in use
- `CLAUDE.md` / `AGENTS.md` at the repo root and in subdirectories

Then classify:

| Start | Looks like | Approach |
|---|---|---|
| **A — greenfield** | An idea or a paragraph; no mockups, no docs | Spend an extra interview round on form factor and first-class objects — there is no mockup to reverse-engineer |
| **B — mockups exist** | Figma screenshots, design images, competitor screenshots; no docs | Reverse-engineer the region tree from the images (see reading discipline below), then interview |
| **C — visual spec exists, structural spec missing** | A design.md or token system exists, but nobody ever wrote down where new features go | **The most common case.** Focus on cutting the boundary and moving structural content out of the existing doc (§3) |

Whichever artifact already exists, do not rebuild it — but **do align the boundary**. An existing visual spec almost always has structural content mixed in (region trees, column widths); that content moves to `layout.md`, leaving a one-line pointer behind.

Tell the user which start you identified and what you found, then proceed.

---

## 1. The interview

The question bank lives in `references/interview.md`. **Read it.** This section is only about discipline.

### Interview discipline

- **One question at a time. Wait for the answer.** Four questions at once makes thinking impossible, especially for non-technical users.
- **Give a recommendation, and state the cost.** Users need "what do I lose by picking this", not a menu. An option without a stated cost carries no information.
- **Look up facts; put decisions to the user.** How wide is that column, what stack is in use, where does that value live — find out yourself. Whether this *should* be the design — that's theirs.
- **When the user overrides your recommendation, accept it and list the knock-on effects.** They move forward one step; you are responsible for saying which already-settled conclusions that step disturbs.
- **When the user pushes back or looks confused, explain before re-asking.** Never re-throw the same question verbatim.

### Reading mockups (start B)

A mockup is an exploration, not a spec. Read it with active suspicion:

- **Repeated elements are usually copy-paste artifacts.** Six identically-named rows in a sidebar, five rows of the same string in a list — ask "is this intent or placeholder" before writing it down as a structural fact.
- **Ownership follows geometry, not intuition.** A bar that extends over the right-hand column does not belong to the left card. Facts like this change the whole region tree — and therefore change where new features are allowed to go.
- **When the mockup contradicts an existing doc, say so and let the user decide.** Do not silently pick a side.
- Value drift (`9px` / `13.5px` and friends) is normal in mockups. Converging it belongs to `design.md`, not `layout.md`.

### What the interview produces

Flatten every settled conclusion into one numbered table for the user to confirm, plus two separate blocks:

- **What I'll decide myself** (things the mockup already answers, or purely mechanical choices — don't spend the user's attention)
- **What's explicitly out of scope** (goes into the structural spec's "not decided by this spec" appendix)

Only start writing docs after the user confirms that table.

### Where conclusions ultimately live (important)

That numbered table is a **one-off conversational artifact**. Do not turn it into a fourth document. **Do not start a separately-maintained "decision log"** — it will drift from `layout.md`, and an agent reading two contradictory sources picks one at random.

Conclusions belong here:

| Content | Destination |
|---|---|
| "We decided to do it this way" | A **rule with its reasoning** in the relevant chapter of `layout.md` |
| "We considered that and rejected it" | `layout.md` Appendix B, "Overturned" — was / became / why |
| "We're not covering that" | `layout.md` Appendix A, "Not decided by this spec" |
| "This still needs the user's call" | Ask. If you can't, put it above Appendix B as open, and **name it in conversation** — don't bury it in a file |

Exception: if the user explicitly wants a shareable decision document (team-alignment scenarios), write one — but put a line at the top saying "**`layout.md` is authoritative; this file only records why, and what was overturned**", so it can't become a second source of truth.

---

## 2. Write layout.md

The skeleton and per-chapter requirements are in `references/layout-md-outline.md`. **Read it.**

Three things decide whether this document is useful at all:

1. **The placement decision tree goes first (§1).** It is the entry point: an agent takes a new requirement, walks the tree, implements directly if it lands — and **stops if it doesn't**. A layout document without a decision tree gets read and forgotten.
2. **Every row of the region allowlist (§2) needs a "must not hold" cell.** Listing only what goes in a region is documentation; stating what must *not* go in is a spec. The forbidden entries come from every "don't make it X" conclusion in the interview.
3. **Every anti-pattern carries a reason and a replacement.** "Don't do X" gets worked around. "Don't do X, because it causes Y, do Z instead" gets followed.

`layout.md` contains **no color values, font sizes, radii, or spacing values** — only structural parameters (column widths, minimum sizes, region counts). Where a value is needed, write "see design.md §X".

---

## 3. Align / slim down design.md

Skeleton in `references/design-md-outline.md`. This step is the main event for start C.

- Add a division-of-labor statement at the top of `design.md`, naming the cut ("does it change when the brand skin changes").
- **Move structural content out**: region trees, column widths, page archetypes. Leave a one-line "structure: see layout.md §X" behind, and rename the section if its title promised structure.
- **Align region names with the allowlist.** Old component-style names (camel-cased widget names) must be replaced with allowlist names, or an agent reading both docs gets two vocabularies — and the allowlist mechanism fails on the spot.
- Appendices that record *mockup* reality (value-drift mapping tables and the like) **stay untouched** — they document the mockup, not the spec.

---

## 4. Build the wireframe

Implementation guide in `references/wireframe.md`; the mechanical skeleton is `assets/wire.tsx.template`. **Read both.**

### Why the wireframe deliberately carries no brand visuals

This is the counterintuitive part, and the most important: **a skeleton with brand visuals becomes a second source of visual truth.** Agents copying the skeleton copy the colors and radii along with it; once `design.md` changes, the skeleton is a stale spec — and agents trust the code in front of them more than a document. A skeleton with no brand visuals to copy has no such drift.

So: neutral greys, system font, status labels that only express "a status label goes here". **But the copy and the density must be real** — an empty interface makes any layout look fine; density is what exposes problems (columns that don't fit, long strings that break, parallel items crushed together).

### Stack

Look at the project's existing stack and follow it. With no existing stack, default to React + Vite + TypeScript + Tailwind.

**TypeScript is a hard requirement**, because the allowlist has to become a union type to be enforced at compile time (§5). If the user insists on no build tooling (single-file HTML), tell them plainly what they give up: the allowlist becomes human-honor-system only.

### Four things the wireframe must do

1. **Every structural container carries a region marker** (`data-region` or the platform equivalent), valued from the allowlist.
2. **Annotation layer**: shows human-readable module names by default; hovering reveals the code name and the region's responsibility. The description says "what goes here / what must not", not "what this is" — the latter is visible from the screen.
3. **Degradation rules actually implemented** (if the spec has any): triggered by measured size, not fixed viewport breakpoints. A rule that only exists in a document never gets verified.
4. **A "deliberate tradeoffs" list** in the directory-level `CLAUDE.md`, so the next agent doesn't "fix" the things you left out on purpose.

### The wireframe is the spec's physical exam

You will find holes while building it (what a region shows under a particular archetype was never decided; the overlay covers the title bar so it needs its own header…). **Write the doc first, then change the code.** Never quietly add a rule to the code that the document doesn't state.

### Type-checking is not optional

**Allowlist enforcement happens during type-checking.** Skipping it means the compile-time layer isn't actually in force — the code may not even compile, while you've told the user it's installed.

So: install, type-check, build, and paste the real output. If the environment can't install dependencies (offline, permissions), **say explicitly that the compile-time layer is unverified and the user needs to run it locally.** Don't let "the code is written" cover for "it was never run".

---

## 5. Install enforcement

Documents alone don't get read — least of all when the task sounds small ("just adding a button"). Three layers; miss one and things leak through:

| Layer | How |
|---|---|
| **Entry** | A section in the repo-root `CLAUDE.md`: before changing any interface structure, walk `layout.md` §1; stop and use the change process if it doesn't land; every region name must be in the allowlist |
| **Directory** | A `CLAUDE.md` inside the wireframe: what to read before touching anything, the deliberate-tradeoffs list, which file is the single source for structural parameters |
| **Compile time** | Allowlist → union type (`type RegionId = 'a' \| 'b' \| ...`). Writing a name that isn't in the table fails type-checking |

The compile-time layer generalizes further: whenever the spec says "region X must not hold things of kind Y", **delete Y from the corresponding union type** — then violations are unwritable. Put a comment next to the omission saying it is deliberate, or the next agent will assume something is missing and add it back. This beats any `MUST` you could write, and costs less than a lint rule.

Also pin the sync order: **change the allowlist → change the union type → write code.** Never the reverse.

---

## Iteration discipline

Once the user sees the wireframe, they will have change requests. For each one:

1. **First judge whether it belongs in `layout.md` at all.** Recording "right-align it" or "add a button" verbatim is nearly worthless; the value is in the rule it forces. Ask yourself: what structural constraint is behind this request? Would it still hold under a different brand skin?
2. **Name the existing clause it collides with.** New requests frequently contradict prohibitions you wrote yourself — surface that, then change the prohibition or the request. Never let both stand.
3. **Docs change first, code follows.** Always.
4. **When overturning an old conclusion, don't delete it** — move it to the "Overturned" appendix with the reasoning. Overturned judgments are easier to re-tread than current ones, because they looked reasonable (they looked reasonable to you too, once).
5. **Report precisely what changed**: which sections, which new anti-patterns, what followed in code.

If you discover mid-implementation that something you said earlier was inaccurate (you promised a property the design can't actually deliver, say), **say so and correct it** — don't leave the wrong conclusion in the document.

---

## Before you call it done

- [ ] Zero overlap between the two specs? Every value lives in exactly one place?
- [ ] No color / font-size / radius / spacing values in `layout.md`?
- [ ] Can the decision tree answer a real new requirement, all the way to a specific region name? Is there an explicit "stop" for when it doesn't land?
- [ ] Does every allowlist row have a "must not hold" cell?
- [ ] Does every anti-pattern have a reason and a replacement?
- [ ] Are region names identical across the doc, the type definition, and the wireframe code?
- [ ] Have you read every region description and confirmed it says **what goes here / what must not**, not "what this is"? (A wrong description is more dangerous than wrong code — agents extend from it)
- [ ] Are the few genuine coupling points marked "⚠ revisit §X of the other spec" on both sides?
- [ ] Does the wireframe run, **did type-checking actually run with output pasted**, and is the density real (not a shell)?
- [ ] Did conclusions land in `layout.md`'s clauses and appendices, rather than a separate document that will drift?
- [ ] Did you avoid writing any reference product's specific information architecture in as universal truth?
- [ ] Can the user explain what each of the three artifacts owns, and which one to open first next time they add a feature?

That last one is the easiest to skip. Tell the user in plain language **what you did / why / where it may differ from what they expected**, and be explicit about what you verified and what you didn't. You usually cannot verify rendered output — say so, and let them look.
