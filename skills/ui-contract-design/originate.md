# Originating a brand

This branch runs **only** when the project has no visual conventions at all — no `design.md`, no token source, no mockups. If any of those exist, this is the wrong branch: go align them instead (`SKILL.md` §This step aligns).

Four steps, and **the order is the whole point**:

| | Step | Who does it |
|---|---|---|
| 1 | Attribute interview — three mutually exclusive directions, each with its cost | the conversation |
| 2 | Derive first values from the chosen direction | `frontend-design` |
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

Call the Skill tool with "frontend-design". Its job is to turn the chosen direction into **good concrete values**; this skill's job was to force the choice. Keep the two apart: brand generation is the one place here that has to produce taste, and also the one place most likely to decay into another default Tailwind blue.

**The output lands as `tokens.input.json`, not rendered into the instrument's HTML.** Three reasons, and the third is the one that pays:

1. Values rendered into a one-off file are lost the moment the page is regenerated.
2. A template that differs on every run is not a template.
3. v1 (what the agent derived) and the final version (what the user tuned) become **two revisions of one file, and therefore diffable**. ADR-0001 决定 B hangs its revisit condition on "the proportion of generated brands the user overrides" — a number that has never had a source. This diff is that source.

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
