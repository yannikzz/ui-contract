---
name: ui-contract-design
description: Align an existing visual spec (design.md) against the structural spec - add the division-of-labor statement, move structural content out leaving a pointer, replace old component-style names with allowlist names, and move literal values into the token file so design.md holds rules rather than values. Use when a project has visual conventions that need to become a spec with a clean boundary. Or originate one when there are none at all - choose a brand direction on attributes rather than colours, derive the values, tune them on a page. Chinese: 生成品牌/配色规范/token 命名/主题调校.
---

# Visual spec — `design.md`

Produces one artifact: `design.md`, plus references into the project's **token file**. Skeleton in [design-md-outline.md](design-md-outline.md). **Read it.**

Two branches, same artifact and same completion criteria — so this is one unit, not two:

| What the project has | Branch |
|---|---|
| A visual spec, a token source, or mockups | **align** — this file, below |
| None of those | **originate** — [originate.md](originate.md). **Read it before asking anything.** |

For the interview discipline, call the Skill tool with "decision-interview".
For which document a thing belongs in, call the Skill tool with "ui-contract-glossary".
For the deliverable's language and terminology, call the Skill tool with "deliverable-language".
For handling change requests, call the Skill tool with "spec-before-code".

## Preconditions
**Artifact paths come from `docs/ui-contract/config.md`'s paths table.** If that file doesn't exist, the specs are at the repo root. Never assume a path the config contradicts.


| Condition | Action |
|---|---|
| `layout.md` does not exist | **Stop.** The allowlist is what region names get aligned against; without it this step produces a second vocabulary. Call the Skill tool with "ui-contract-layout" first |
| `design.md` exists but `layout.md` does not | **Stop and say so.** Aligning a boundary against a document that doesn't exist means inventing the other half |
| No visual conventions exist anywhere — no `design.md`, no token source, no mockups | **Go to `originate.md`.** Do not start from this file's align procedure — there is nothing to align against |
| Nothing exists **and** the user asks for "something that looks good, you pick" | Still `originate.md`, still the interview. **Do not hand over a default palette.** A palette the user rubber-stamps is no longer their spec, which is the failure this whole method exists to prevent |

## This step aligns; it does not rewrite

If the project already has a visual spec, **do not rewrite it.** Four things:

1. **Add the division-of-labor statement** at the top, naming the cut ("does it change when the brand skin changes") and naming the token file as the value authority.
2. **Move structural content out**: region trees, column widths, page archetypes go to `layout.md`. Leave a one-line "structure: see `layout.md` §X" behind, and rename the section if its title promised structure.
3. **Move literal values out to the token file.** Hex codes, px sizes, radius literals become token references. If the project already has a token source (`tailwind.config.*`, `tokens.css`, a theme file), **that is the token file** — do not create a second one.
4. **Align region names with the allowlist.** Old component-style names (camel-cased widget names) must be replaced with allowlist names, or an agent reading both docs gets two vocabularies — and the allowlist mechanism fails on the spot.

**Token names are not part of that.** Region names get aligned; token names do not. Record what the project already calls them in the declaration table, marked `this project`, and change nothing. Renaming tokens turns a boundary alignment into a repo-wide rename that touches every consumer — a change request, which goes through `spec-before-code`.

Appendices that record **mockup** reality (value-drift mapping tables and the like) **stay untouched** — they document the mockup, not the spec.

## The document is the name authority

The token file holds the **values**; this document settles which **names** exist. Say so in the opening blockquote, and carry the declaration table (`design-md-outline.md` §Opening) with it.

This has to be written down for the same reason the value authority is: without it, a borrowed naming convention quietly becomes the authority instead, and **nothing in the output shows it** — a token file produced either way is byte-for-byte the same. The health check reads its whitelist from that table, so a missing table degrades the check to nothing.

The same applies to `tokens.input.json` when the `originate` branch produced one:

| | Records | On conflict |
|---|---|---|
| `tokens.input.json` | where the user left the knobs (an input record) | does not count |
| the token file | the values that are currently correct | wins |

Its keys are the names from the declaration table. Per-stack mapping changes the format, never the names.

## When there is no token file yet

Say so **in the document, not only in the report** — the reader who never sees the report is the one this has to reach. Write the token references as they should be, and two things with them:

- **Name no path that is not on disk.** Write "the token file is the value authority; this project does not have one yet" rather than pointing at `src/tokens.css` and hoping. Following a pointer to a missing file is how a reader concludes the whole spec is stale.
- **Say who closes the gap.** No unit here generates the token file — the asset layer produces structural components only. Whoever builds it fills in the values under the names written here.

Do **not** silently invent values back into `design.md` to make it self-contained. A document that quietly re-absorbs its values is exactly the second value authority this rule exists to prevent.

## Before you call this document done

- [ ] `design.md` contains no literal color or size values; the token file is the single value authority
- [ ] Structural content has been moved out and only a one-line pointer remains
- [ ] Every region name matches the allowlist; no old component-style naming survives in the normative body
- [ ] Mockup-reality appendices were left alone
- [ ] If no token file exists yet, `design.md` says so in its own body, and no path to a missing file is written anywhere in it
- [ ] The declaration table is present in the opening section, one row per token, each row marked `borrowed` / `this project` / `not used` — **those three keywords in ASCII even in a non-English deliverable**, because the health check anchors on them and a translation silently turns the check off
- [ ] Every row marked `borrowed` is actually in the borrowed set; no `sidebar-*` and no `chart-*` among them
- [ ] Chapters the borrowed set does not cover say so, and their names follow the pairing rule
- [ ] On the `originate` branch: the three directions differ on at least two axes, and each cost is a consequence in this product rather than an adjective
- [ ] On the `originate` branch: every derived value traces to a coordinate from the interview, and the **hue's basis is named in `design.md` §1** — an existing asset, the domain's convention followed, the same convention deliberately broken, or adjacency avoidance. If none applies, `design.md` says so and marks the hue as the weakest value in the set. The three axes fix count and saturation but **not hue**, so this is the one slot with no source, and the one where a framework default arrives
- [ ] On the `originate` branch: no value in `tokens.input.json` is a framework default (the list is in `originate.md` §Do not emit a framework default) — emitting one means the coordinates never reached the values
- [ ] On the `originate` branch: the hue's basis is stated **without a literal colour** — not the chosen value, not the default being contrasted against. `design.md` carries no hex anywhere, and explaining a choice is not an exemption from that
- [ ] On the `originate` branch: `tokens.input.json`'s location is **recorded in `config.md`'s paths table** — unrecorded, every run picks its own, and `ui-contract-assets` looks it up there
- [ ] On the `originate` branch: the derived values were **written to `tokens.input.json`** — the actual file on disk, not only described in `design.md` — because ADR-0001 决定 B hangs its revisit condition on how often a user overrides a generated brand, and the diff between this file's first version and the tuned one is that number's only source. A run that reasons about the file and never writes it leaves that condition with no data at all
- [ ] Reported to the user: which sections were touched, how many names were replaced, what was deliberately left alone
