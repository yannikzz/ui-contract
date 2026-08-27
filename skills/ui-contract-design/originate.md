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

### Ground the points in this product's world, not in "admin console"

Three points drawn from the category are three points every product in that category could
have been offered. The subject's own world — what the people using it are actually doing, the
materials and instruments and vocabulary of that work — is where a point stops being generic.

A review queue is not "an admin console": it is somebody moving through a backlog for hours,
where the question every row has to answer is *does this one need me*. A monitoring console is
not that. Points named from the work land differently from points named from the category.

**Test it by swapping the product.** Take the three points and ask whether they would be
offered, unchanged, for a different product in the same category. If yes, they were drawn from
the category and the interview is about to produce the appearance of a decision.

### One of the three has to cost something

Three safe points are not a choice. If every option is defensible to everyone, the user is
picking a favourite rather than making a trade, and the result is the direction that offends
nobody — which is the same direction every similar product already has.

So **at least one of the three is deliberately unconventional for this category**, and its cost
is stated as plainly as the others'. Not a wild one: one that a reasonable person might pick
*because* of what it buys, while knowing what it gives up.

⚠ **The risk still belongs to the user, not to you.** This plugin does not produce the user's
answers. What this section asks for is a real option on the table, not an
agent taking an aesthetic risk on somebody's product. Offering a bold point and having it
declined is the mechanism working; picking it yourself is not.

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

This step used to say "call `frontend-design`", and the reason it no longer does is not
tidiness: that skill ships in a different marketplace, so most installs never had it. Measured
across real runs, the branch then went two ways — some derived the values anyway, others
deferred them to "a later round" and declared the work finished. Both deliverables read as
complete. A step whose behaviour depends on an unrelated plugin being installed is not a step.

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
test, stated as the negative: a default is not a bad-looking value, it is one that arrived
without a reason. Two derivations from the same point should land close; from different points,
they must not.

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

### The signature: one recurring treatment this product is recognisable by

A set of values can be perfectly coherent and still be the set every product in the category
has. Coherence is what the axes buy; **recognisability is a separate thing and nothing above
produces it.**

So name one — exactly one — **recurring visual treatment** that carries the direction and
appears wherever its condition appears. For a design *system* the signature is not a hero
moment; it is a treatment, because a system's job is to repeat.

| A signature is | A signature is not |
|---|---|
| How the thing this product is *for* gets expressed, everywhere it appears | A decorative element added on top |
| Derivable from the chosen direction — you can say which coordinate forced it | A flourish that would survive a change of direction unchanged |
| One thing | Three things, which is the same as none |

**Spend the boldness there and keep everything around it quiet.** A system with three signatures
has none, and the surrounding restraint is what makes the one legible.

Write it into `design.md` §1 beside the direction, and say **which coordinate forced it**. A
signature you cannot trace to a coordinate is decoration, and it is the first thing to cut.

### Then check whether you produced the category's answer

Before writing anything, run the derivation back the other way: **would this same set come out
for a different product in this category?**

Do it concretely, not as a feeling: take the brief, swap the product for a neighbour in the same
category, re-derive. Landing in the same place means the values came from the category rather
than this product — those are the parts to revise. Say which ones you changed and why.

This is not a taste check. It is the same test as "every value traces to a coordinate", applied
one level up: **a set that any similar brief produces is a set that arrived without a reason.**

⚠ The most common outcome of skipping it: a coherent, defensible, entirely generic system that
nobody can fault and nobody would recognise. It passes every check in this document — every value
traces, no framework default appears, contrast clears — and it is still the answer the category
would have given.

### Typefaces are a choice about this product, not a fallback

The axes fix size, line height and measure; they say nothing about **which faces**. Same shape
as hue: an unconstrained slot, and therefore where the default arrives.

Name why these faces suit this product's work — what they do at the density the direction asks
for, what the reading pattern is (scanning a column of statuses is not reading prose).
"The system stack" is legitimate when the reason is stated: on a tool people use for hours,
matching the OS is a decision, not an absence of one.

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

### The same trap one level up: look-level defaults

The list above catches a *value*. There are also whole *looks* that arrive without a reason —
generated design currently clusters around a few, and they appear regardless of subject:

- warm cream ground with a high-contrast serif display and a terracotta accent
- near-black ground with a single acid-green or vermilion accent
- broadsheet layout: hairline rules, zero radius, dense newspaper columns

Each is legitimate **for a brief that calls for it**, and where the user asked for one their
words win. What is not legitimate is arriving at one because it was nearest to hand. Same test:
could you say which coordinate forced it? If the honest answer is "it is what I would have drawn
anyway", it is a default wearing a direction's clothes.

### The output lands as the token file, and this step writes it

The derived values go **straight into the project's token file** — the real one, at the path and
in the format `config.md`'s paths table gives, committed with the repository. That file is the
value authority; production code reads it; `design.md` points at it for every value.

**Write it here rather than handing the values on.** An earlier version wrote a record and left
another unit to land it, and that hop was measured as the least reliable link in the whole chain:
across five valid runs the handoff file landed **2 out of 5** times, and the traces of the runs
that skipped it mention the file 12 and 8 times — *thought about it, did not write it*.

The same shape appeared one link upstream — `originate` depending on a skill that was not
installed, failing silently, both branches producing deliverables that looked complete from
outside — and it was resolved the same way: **remove the hop, do not add a reminder.**

If the paths table's format column is empty, **ask**. Inferring the format by reading a
neighbouring file works most of the time, and the times it works nobody can tell it was inferred.
If the project has no token file at all yet, this step creates it — that is the greenfield case,
and it is the normal one on this branch.

### And a knobs record, which is scratch for the tuning session

Also write `tokens.input.json`: the same values, keyed by the declaration table's names, as the
starting state for Step 3's instrument.

**Know what it is before writing it — it is session scratch, not an artifact.** After option A its
whole reader list is: the instrument (Step 3), the wireframe's skin editor (same tuning session),
and one grader that runs the moment the run ends. Nothing reads it before a session and nothing
reads it after one. Once the tuned values are in the token file it is inert, and deleting it costs
nothing.

It survives at all for one reason: **it is format-neutral.** The token file may be CSS custom
properties, a `theme.extend` block, or a theme object, and the instrument is a generic HTML page
that cannot parse each of those. The JSON is the one shape every tool in that session can read.

So: never tell the user to keep it, never suggest committing it, and never describe it as where
the values live. It is written at all for two reasons:

1. Values rendered into a one-off HTML file are lost the moment the page is regenerated.
2. A template that differs on every run is not a template.

**It goes in the workbench, at `.ui-contract-local/tokens.input.json`.** Fixed, not chosen — the
paths table exists so a project can put its **specs** where it wants them, and this is not a spec.
Two rounds of measurement earned the pinning: with nothing said, runs split three to two over
where to put it, every choice defensible; then "record where it went in the paths table" was
tried, and the split stayed exactly where it was. Writing a choice down makes it visible; it does
not make it the same choice twice.

The reason for pinning changed when the handoff was removed, and the old one is no longer true:
it used to be that a **downstream unit** had to find the file. There is no downstream unit any
more. What is left is the instrument and a grader, both of which need one answer rather than a
recorded one — and a grader's `target.path` is not a glob.

⚠ **The two files are not interchangeable, and the difference is the point.** The token file is
committed and authoritative. The knobs record is local, disposable, and loses to the token file
in any disagreement — see Step 4.

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

⚠ **The JSON's identity has to be written down, or it becomes a second value authority.**
The identity table is in `ui-contract-design`'s own body — carry it into the deliverable from
there rather than from a copy here, and do not demote it to a code comment.

**The JSON's keys are the names from the declaration table.** The mapping into the project's format — CSS custom properties, `theme.extend`, a theme object — changes the *format* and never the *names*. That is where cross-stack naming actually pays off.

The JSON stays stack-neutral; the token file is where the format is chosen. **Both are written in Step 2, by this unit.** `ui-contract-assets` does not land values from the record any more — it consumes the token file, exactly as production code does. A second unit reading a local, uncommitted record and re-deriving the authority from it is the hop that was removed.

---

## Dark mode is not in this version

Registered as pending, deliberately not built. It is not "the same values rendered differently" — it is **a second complete set of values**. Supporting it turns the token file from a flat map into a map of maps, and changes four other things at once: the reference syntax in `design.md`, the health check's dangling-name check, the declaration table's shape, and the instrument's layout.

"Derive it from the light theme" is the most tempting option and the worst: a derived dark theme almost always needs hand-correction, and the first correction invalidates the premise, leaving a half-derived half-edited set that nobody can tell apart.
