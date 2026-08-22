# Originating a brand

This branch runs **only** when the project has no visual conventions at all — no `design.md`, no token source, no mockups. If any of those exist, this is the wrong branch: go align them instead (`SKILL.md` §This step aligns).

Four steps, and **the order is the whole point**:

| | Step | Who does it |
|---|---|---|
| 1 | Attribute interview — three mutually exclusive directions, each with its cost | the conversation |
| 2 | Derive first values from the chosen direction | this skill |
| 3 | Tune the visual scales on a page | the user |
| 4 | Land the values in the token file | `ui-contract-assets` |

Opening with step 3 — handing someone a colour wheel before they have chosen a direction — is the exact failure this ordering exists to prevent. It turns a decision into a rubber stamp.

For the interview discipline, call the Skill tool with "decision-interview". **One question at a time.**

---

## Step 1 — the attribute interview

The user chooses on **brand attributes**, never on colours. Nobody has a defensible opinion about "blue or green"; everybody has one about "authoritative or approachable".

### Three axes

The axes are the space. They are three because three exhausts the tunable token groups without overlap:

| Axis | Token group it moves |
|---|---|
| Dense ↔ airy | Spacing scale · line height · control height |
| Sharp ↔ soft | Radius scale · shadow · border width |
| Restrained ↔ expressive | Number of colours · saturation · how much area the accent covers |

**Do not add a fourth axis.** Any fourth one necessarily moves a group one of these already moves, and the same value reachable from two places is the drift source this whole method is built against.

### Three points, not three axes

⚠ These are different things and they are easy to blur.

| | What the user hears | What you are handling |
|---|---|---|
| Language | Composite, whole ("authoritative and reliable", "light and friendly") | Coordinates on three orthogonal axes |
| Count | 3 mutually exclusive options | 3 axes |

The user picks **one of three points** in that space. Each point is described as a composite, because that is what people can judge. This also explains a composite like "authoritative ↔ approachable": it is not a fourth axis, it is one direction across all three.

**How to place the points:** the three must differ on **at least two axes**. Three points that are all somewhat soft and differ only in degree are not mutually exclusive — the user has nothing to choose between, and the interview has produced the appearance of a decision.

### Costs

Every option carries a cost, and the cost is written as **a specific consequence in this product**:

| Weak | Strong |
|---|---|
| "Less extensible" | "Table rows compress to X, so long titles truncate more often" |
| "Feels heavier" | "The accent covers enough area that the primary action stops reading as the only one" |

An option whose cost is an adjective carries no information. If you cannot name the consequence, you have not understood the option well enough to offer it.

The chosen direction and its stated cost land in `design.md` §1, marked 🌡 — a generated brand is a hypothesis until real users have seen it.

---

## Step 2 — derive the first values

This step used to say "call `frontend-design`". It no longer does, and the reason is not
tidiness: that skill ships in a different marketplace, so most installs never had it. Measured
across real runs, the branch then behaved two different ways — some runs derived the values
anyway, others deferred them to "a later round" and declared the work finished. Both produced a
deliverable that reads as complete. A step whose behaviour depends on whether an unrelated
plugin happens to be installed is not a step.

So it is derived here. That inherits the problem the delegation existed to avoid — **the most
likely outcome of "generate a brand" is another default framework blue** — and the rest of this
section is the answer to it.

### Every value has to be forced by something

The interview produced coordinates, and the axes already name which token group each one moves
(§Three axes). Derivation is reading that table in the other direction:

| Axis | What its coordinate fixes |
|---|---|
| Dense ↔ airy | The spacing step ratio, line height, control height |
| Sharp ↔ soft | The radius scale, shadow depth, border width |
| Restrained ↔ expressive | How many colours exist, how saturated they are, how much area the accent may cover |

**A value you cannot trace back to a coordinate is a value you defaulted.** That is the whole
test, and it is worth stating as the negative: a default is not a bad-looking value, it is a
value that arrived without a reason. Two derivations from the same point should land close;
two derivations from different points must not.

### The gap the axes do not close: hue

Read that table again and notice what is missing. The third axis fixes how *many* colours and
how *saturated*, and says nothing about **which hue**. Nothing else does either — and Step 1 is
deliberate that the user chooses on attributes, never on colours, so the interview will not
supply it.

That unconstrained slot is exactly where the default blue arrives. It is not laziness; it is
the only value in the set with no source.

Close it with a **stated basis**, not with a preference. Pick the hue from something nameable
about this product, and write which one in `design.md` §1 next to the direction:

| Basis | Example of the reasoning |
|---|---|
| An existing asset | A logo, a printed piece, a parent brand — if one exists it wins, and no derivation is needed |
| The domain's convention, followed | Finance and health carry hue expectations; matching them is a choice with a reason |
| The domain's convention, broken | Same expectation, deliberately refused, because the product is positioned against the incumbents |
| Adjacency avoidance | The two or three products this one sits beside all use the same hue, so this one must not |

Any of those is a reason. "It looked good" is not, and neither is silence. **If none of the four
applies, say so in `design.md` and mark the hue explicitly as the weakest value in the set** —
that is honest, and it tells the user which knob to reach for first in Step 3.

⚠ **State the basis without writing a value.** `design.md` carries no literal colours — not the
chosen one, and not the default you are contrasting against. Both violations were measured on the
first run after this section was written: one deliverable explained itself as "deeper and duller
than Tailwind blue-500 (`#3b82f6`)", another named the hue it picked. Say it in words or in token
names instead — "the category convention, pushed darker and less saturated" — and let
`tokens.input.json` hold the number. The rule this collides with is not new; it is the one at the
top of `SKILL.md`, and an explanation is not an exemption from it.

### Do not emit a framework default

These are the values that appear when the derivation did not happen. Emitting one is a signal,
not a crime — it means Step 1's coordinates never reached the values:

```
#3b82f6  #2563eb  #1d4ed8      Tailwind blue-500/600/700
#6366f1  #4f46e5                Tailwind indigo-500/600
#0ea5e9  #0284c7                Tailwind sky-500/600
#007bff  #0d6efd                Bootstrap primary (v4, v5)
#1976d2  #2196f3                Material blue 700/500
```

If a derivation genuinely lands on one of these, move it — the nearest hue that is still
consistent with the stated basis is fine, and the point is that the value stops being the one
you would have written without thinking.

### The output lands as `tokens.input.json`

Not rendered into the instrument's HTML. Three reasons, and the third is the one that pays:

1. Values rendered into a one-off file are lost the moment the page is regenerated.
2. A template that differs on every run is not a template.
3. v1 (what was derived here) and the final version (what the user tuned) become **two revisions
   of one file, and therefore diffable**. ADR-0001 决定 B hangs its revisit condition on "the
   proportion of generated brands the user overrides" — a number that has never had a source.
   This diff is that source.

**Write the file before moving to Step 3.** Not "plan to write it", not "describe it in
`design.md`" — the file on disk, now. Reason 3 is void without it: a revisit condition whose
only data source exists some of the time is not a revisit condition.

**And record where it went, in `config.md`'s paths table.** That table is already the authority
for every other artifact; this one was missing from it, so each run chose its own location — two
put it at the repo root, one under `docs/ui-contract/`, and all three were defensible because
nothing said otherwise. An unrecorded location is not only a measurement problem: `ui-contract-assets`
has to read this file to map the values into the token file, and it looks the location up in that
same table.

---

## Step 3 — the instrument

`assets/theme-studio.html.template`. One standalone page; the wireframe is not touched and stays grey.

**The knob set comes from `design.md`'s declaration table.** The template ships with no token-name list of its own — a built-in list would be this plugin deciding the project's naming, which is a second vocabulary, and the declaration table already settled that question. Reading the knobs out of the document is also what makes a dangling name (declared but absent from the token file) mechanically detectable.

**What the sample shows: generic controls only, never IA carriers.**

| In | Out |
|---|---|
| Three button levels · input / select · table rows · cards · status labels · count badges · a very long string · empty / loading / partial-failure states | Nav bars · sidebars · page headers · footers · breadcrumbs |

The right column is information architecture, not controls. Ship those and the instrument hands a nav shape to every project that installs this plugin.

**Only visual scales are tunable** — spacing, type size, radius, colour. Column widths, minimum widths and gutters belong to `layout.md`; changing one of those goes through `spec-before-code`, not through a slider.

**Contrast is validated live**, against the threshold written in `design.md` §2. The instrument does not carry its own number.

---

## Step 4 — landing the values

⚠ **The JSON's identity has to be written down, or it becomes a second value authority:**

| | Records | On conflict |
|---|---|---|
| `tokens.input.json` | where the user left the knobs (an input record) | does not count |
| the token file | the values that are currently correct (the value authority) | wins |

Do not leave this in a comment. The same class of mistake has been made twice in this repo, and both times the output looked entirely normal.

**The JSON's keys are the names from the declaration table.** Per-stack mapping changes the *format* — CSS custom properties, `theme.extend`, a theme object — and never the *names*. That is where cross-stack naming actually pays off; it is not a property of the document, it is a property of this file.

The JSON stays stack-neutral. `ui-contract-assets` maps it using the token source **and format** recorded in `config.md`.

---

## Dark mode is not in this version

Registered as pending, deliberately not built. It is not "the same values rendered differently" — it is **a second complete set of values**. Supporting it turns the token file from a flat map into a map of maps, and changes four other things at once: the reference syntax in `design.md`, the health check's dangling-name check, the declaration table's shape, and the instrument's layout.

"Derive it from the light theme" is the most tempting option and the worst: a derived dark theme almost always needs hand-correction, and the first correction invalidates the premise, leaving a half-derived half-edited set that nobody can tell apart.
