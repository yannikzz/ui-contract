# Question bank — structural spec

One question at a time; every question carries a recommendation **and its cost**. For the discipline itself, call the Skill tool with "decision-interview".

**Questions that belong to other units, and where their answers already are:**

| Question | Owner | Read the answer from |
|---|---|---|
| Where the files go, what they're called, whether you may edit an existing visual spec | `ui-contract-setup` | `docs/ui-contract/config.md` |
| Which ambiguous values are visual vs structural | `ui-contract-design` | `design.md` opening |
| Wireframe fidelity | `ui-contract-wireframe` | — |
| How hard enforcement should be | `ui-contract-enforce` | — |

**Do not re-ask a question whose answer is already on disk.** Read it. Re-asking is how a user ends up answering the same thing three times across three sessions.

---

## Group 1 — Form factor and first-class objects
*(Mandatory for a greenfield start. With mockups or existing code, derive it first, then confirm.)*

This group defines the answer space for everything below. Get it wrong and the rest tilts.

**Q1 What is this product's shell?**
Desktop application window / in-browser SPA / mobile app / embedded panel / web UI alongside a CLI.
Different form factors mean genuinely different region-tree depth — never stretch one form factor's skeleton over another.

**Q2 What "things" do users open and reference over and over in this product?**
These are the **first-class objects**. Three tests: ① it has its own identity (can be referenced or linked) ② it can be opened on its own ③ it has a lifecycle beyond one session.

This enumeration directly determines the admission list for "what the focus slot may hold". **A process state is not an object** ("pending review", "expired" are states of an object). **A view is not an object** ("the reports page" is a page).

**Q3 Within one screen, which two kinds of information do users most often need simultaneously?**
This decides whether a second persistent column is needed at all. "Neither" is a valid answer — that's a single-column product, so don't manufacture a sidebar.

---

## Group 2 — Surface

**Q4 How much surface should the spec cover?**

| Option | You get | You lose |
|---|---|---|
| Shell + primary scenario + 2–4 page archetypes (recommended) | Every future page has a placement rule: pick an archetype, then fill it | Moderate length |
| The primary screen only | Fastest to something visible | Every other destination in the nav has nothing to go on; agents will each invent something |
| Every page, spelled out | Most complete | Large, and very easily degenerates into a feature spec rather than a layout spec |

---

## Group 3 — Extension slots *(this group is where the spec earns its keep)*

**Q7 What model governs the focus slot outside the main area?**
*(If Q3 answered "no second column", ask the equivalent about replaceable blocks inside the main area.)*

| Option | You get | You lose |
|---|---|---|
| One slot + a finite type enumeration, where each type is a facet of a first-class object (recommended) | **An admission gate.** New features have exactly two routes: a tab inside an existing type, or an application to become a new type (which requires proving it's a first-class object) | Slightly more implementation work |
| A stack of cards; a new feature is a new card | Most flexible, simplest to build | **No gate.** Six months in, this column is an infinitely-scrolling junk drawer — which is the exact thing you're trying to prevent |
| Fixed segments (global signals on top, current object below) | Global signals always visible | Once the global segment has to sit on top of *every* type, it has become the slot's **frame** rather than its content, and responsibilities tangle |

**Q8 Which types are in the enumeration?**
Pick from the first-class objects in Q2. Walk each one: does it need a persistent focus position, or does it "need width, so it goes full-screen instead"?
**Things that need width should not go in a narrow slot** — the user ends up clicking one extra time to reach the place they can actually read.

**Q9 Who decides which type is showing?**

| Option | You get | You lose |
|---|---|---|
| The user's last explicit pointing, reset to a default when context switches (recommended) | Nothing gets yanked away mid-read | It won't jump to something that just happened, so a signal elsewhere must compensate |
| The system switches to whatever "just happened" | Nothing gets missed | With several things in parallel it jumps on its own; whatever you were reading gets taken |
| Purely manual, no reset on context switch | Most predictable | Slot contents disagree with context (you moved on; the slot is still showing the previous object) |

Picking the first requires a compensating rule: **don't steal the panel, but add a signal elsewhere** (a badge on the tab, a dot in the nav). Without the compensation it becomes "silently dropping things".

**Q10 How many classes of content live in the main area, and where does each go?**
Walk them until the user can't name another. A typical split — **this is a questioning frame, not the answer**:

- Things a human must act on or decide
- Milestones and result notifications
- Produced files / attachments
- Long content, back-and-forth discussion
- Process events (what step is happening right now)

The last class is the one that goes wrong most often: process events shoved into the content stream wash out the main thread. Ask "does this produce dozens a day, or a handful" — dozens means it needs its own destination and must not enter the stream.

**Q11 Where do the things a human must act on live?**

| Option | You get | You lose |
|---|---|---|
| Only in the detail area; the stream carries a one-line reference (recommended) | "Single source for actions" becomes a **structural fact** (there are no buttons in the stream to press); the stream stays uniform and scannable | One extra click; collaborative visibility drops — **which must be bought back with a summary line on the reference row** |
| Inline in the stream only | Actions sit closest to context | Cards with many fields grow tall; two or three fill a screen and looking back gets slow |
| Two hosts, mutually exclusive | Best of both | "Mutually exclusive" is a **rule humans have to maintain**; both easily end up expanded |

If they pick the first, don't grant exceptions for "lightweight" confirmations — "how light is light" is a fuzzy line, agents will invent their own threshold, and the stream fills with buttons again.

---

## Group 4 — Navigation and page archetypes

**Q12 Do the nav items differ in kind?**
Test each item with three properties rather than handing the user a taxonomy:

- **Does it empty to zero?** Yes → it's a queue, and it needs a count badge
- **Does clicking it "make something happen" or "go to a page"?** Happen → it's an action, and it should not be built as a page
- **Does it never empty?** Yes → it's a library, and it **must not carry an unread count** (a count would be read as a to-do)

Items that fail all three (org settings, infrastructure config) don't belong in the primary nav; they go to a settings layer.

Ask whether to codify that segmentation as an admission rule, and **whether to cap the "never empties" segment**. The cap's job is to force a consolidation decision — without a hard line that segment grows forever and becomes a long list.

**Q13 How many page archetypes?**
Derive from each nav destination: what structure does it need? Merge destinations with identical structure into one archetype.

While merging, watch for two patterns that **look identical but mean different things**: is the left column **mutating data** (empties, items disappear once handled) or a **fixed directory** (never grows or shrinks)? The former needs a bottom action area and "advance to the next item"; the latter is a form with save semantics. Mixing them leaves users disoriented.

For each archetype, pin down which shell parts are present and which are not.

**Q14 What happens as available size shrinks?**

| Option | You get | You lose |
|---|---|---|
| Trigger on "minimum usable size of the main content area" (recommended) | Decoupled from specific window sizes; recomputes when another column collapses and frees space | Requires measuring real size, not just declaring breakpoints |
| Fixed viewport breakpoints | Direct, easy to implement | A breakpoint doesn't know the state of the other columns, so it collapses things unnecessarily |
| Don't specify | Fastest | Every agent invents its own |

Follow-ups: **what remains after collapse** — collapsing to zero buries the "something needs you" signal, so leaving a signal rail is almost always right. And **who wins between a manual toggle and automatic degradation** — recommend the user, in both directions (collapsed by hand stays collapsed even when space returns), because automatic degradation is a fallback, not an opinion.

**Q15 Include empty / loading / partial-failure / whole-region-failure states?**

Recommend "include, but only the placement rules, not drawn pages": each archetype and each list region declares where these four go, how they present, and what's forbidden. Reasoning: leave them out and they still consume half the real implementation effort, with every agent inventing its own (skeleton screens here, toasts there, a blank page somewhere else).

---

## Form-factor add-ons

### Desktop / wide-screen web
- Besides window controls, what else may live in the window control strip? (Layout controls yes; business information and persistent signals no — those belong elsewhere.)
- Is there a bar spanning multiple columns? Which layer owns it? This determines whether it changes when one column's contents change.
- After the sidebar collapses, does it disappear or become an icon rail? Which signals **absolutely must not** be lost from the rail?

### Mobile app
- Is navigation a bottom tab bar, a drawer, or a page stack? For a page stack the region tree is **one tree per screen**, not one big tree.
- A focus slot usually doesn't exist on mobile; the equivalents are **drilling down a level** or a **bottom sheet**. Don't port the sidebar model.
- Do gesture rules belong in the spec (back, swipe-to-delete)?

### Dashboards / reporting
- The extension slot is a **grid cell**, not a "panel type" — pin down grid columns, how many cells a card may span, whether cards are draggable.
- Are filters global or per-card? Mixing the two is this category's most common structural disease.
- Chart visuals belong to `design.md`; "where a new metric card goes and how wide it is" belongs to `layout.md`.

### Content sites
- Archetypes are usually landing / list / detail / search results; confirm the shell-part tradeoffs for each.
- "Where does a new section go" is this category's core extension question — write the decision tree around it.
