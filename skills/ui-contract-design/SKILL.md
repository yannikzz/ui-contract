---
name: ui-contract-design
description: Align an existing visual spec (design.md) against the structural spec - add the division-of-labor statement, move structural content out leaving a pointer, replace old component-style names with allowlist names, and move literal values into the token file so design.md holds rules rather than values. Use when a project has visual conventions that need to become a spec with a clean boundary.
---

# Visual spec — `design.md`

Produces one artifact: `design.md`, plus references into the project's **token file**. Skeleton in [design-md-outline.md](design-md-outline.md). **Read it.**

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
| No visual conventions exist anywhere — no `design.md`, no token source, no mockups | **Stop and say so plainly.** Generating a brand from nothing is a separate capability that this version does not have. Tell the user what it would involve and let them decide, rather than producing a default palette they will accept without choosing |

That last row is not a temporary gap to paper over. A default palette the user rubber-stamps is no longer their spec — which is the failure this whole method exists to prevent.

## This step aligns; it does not rewrite

If the project already has a visual spec, **do not rewrite it.** Four things:

1. **Add the division-of-labor statement** at the top, naming the cut ("does it change when the brand skin changes") and naming the token file as the value authority.
2. **Move structural content out**: region trees, column widths, page archetypes go to `layout.md`. Leave a one-line "structure: see `layout.md` §X" behind, and rename the section if its title promised structure.
3. **Move literal values out to the token file.** Hex codes, px sizes, radius literals become token references. If the project already has a token source (`tailwind.config.*`, `tokens.css`, a theme file), **that is the token file** — do not create a second one.
4. **Align region names with the allowlist.** Old component-style names (camel-cased widget names) must be replaced with allowlist names, or an agent reading both docs gets two vocabularies — and the allowlist mechanism fails on the spot.

Appendices that record **mockup** reality (value-drift mapping tables and the like) **stay untouched** — they document the mockup, not the spec.

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
- [ ] Reported to the user: which sections were touched, how many names were replaced, what was deliberately left alone
