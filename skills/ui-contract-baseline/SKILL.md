---
name: ui-contract-baseline
description: Reverse-engineer what a project's interface structure actually is today - the real region tree from code or mockups, structural parameters as found, the gap against what a spec would require - and only then ask how existing code should be treated. Writes as-built.md. Use on a project that already has frontend code, before any structural spec is written.
---

# Baseline — measure the as-built state

Produces `as-built.md` at the repo root (skeleton: [as-built-outline.md](as-built-outline.md)), and fills in the legacy-strategy section of the config file that `ui-contract-setup` created.

For the interview discipline, call the Skill tool with "decision-interview".
For recording the legacy strategy, call the Skill tool with "decision-record".
For the deliverable's language and terminology, call the Skill tool with "deliverable-language".

## Preconditions
**Artifact paths come from `docs/ui-contract/config.md`'s paths table.** If that file doesn't exist, the specs are at the repo root. Never assume a path the config contradicts.


| Condition | Action |
|---|---|
| No frontend code and no mockups | **Report "this is a greenfield project; this step isn't needed" and stop.** Don't manufacture a baseline out of an idea |
| Mockups only, no code | Proceed, but mark every finding as mockup-derived — see the reading discipline below |

## Why this exists

Skipping it on an existing project means writing a structural spec that **invents a region tree with no relationship to reality**. Enforcement then locks that invention into the type system, and the whole repo lights up red.

That is why the structural spec hard-stops without this file — it is a stop, not a reminder.

## Record what is, not what should be

The single discipline of this unit. Use the names the code actually uses, even bad ones. Record the parameter values actually present, including the three inconsistent copies. Every improvement you make while transcribing destroys the mapping that the reconciliation depends on.

Judgements about what *should* be belong to the structural spec, one step later.

## Reading mockups with suspicion

A mockup is an exploration, not a spec:

- **Repeated elements are usually copy-paste artifacts.** Six identically-named rows in a sidebar, five rows of the same string in a list — ask "is this intent or placeholder" before writing it down as a structural fact.
- **Ownership follows geometry, not intuition.** A bar that extends over the right-hand column does not belong to the left card. Facts like this change the whole region tree — and therefore change where new features are allowed to go.
- **When the mockup contradicts the code, record both and let the user decide.** Do not silently pick a side.
- Value drift (`9px` / `13.5px` and friends) is normal in mockups. Converging it belongs to the visual spec, not here.

## Ask about legacy only after measuring

Once the gap table is filled in, and not before, ask how existing code should be treated:

| Option | You get | You lose |
|---|---|---|
| **Freeze line** — the spec binds new work only; existing code is grandfathered | Nothing breaks; adoption starts today | Two conventions coexist indefinitely, and the old one is the bigger one |
| **Migrate first** — bring existing code into line before the spec takes effect | One convention, cleanly | The cost lands up front, and it is the cost measured in the gap table |
| **Hybrid** — freeze line now, with named areas scheduled for migration | Adoption today, drift bounded | The schedule is a promise someone has to keep; unkept, it degenerates into the freeze line |

Do not recommend one of these from first principles. **The gap table's "cost to close" column is what makes this answerable** — read it back to the user and let the numbers argue.

Whatever they choose is hard to reverse, excluded real alternatives, and has a nameable revisit condition. It gets a decision record.

## Before you call this done

- [ ] Every finding states its source and reliability; inferred facts are marked as hypotheses
- [ ] Names are as-found, not improved
- [ ] The gap table has a cost estimate on every row
- [ ] Naming collisions with the future allowlist are listed
- [ ] The legacy strategy was asked **after** the gap table existed, and recorded as a decision record
