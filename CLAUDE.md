# Working on this repo

This repository ships **15 skill packages**. `skills/` is the only directory installed to users; everything else (`testing/`, `examples/`, `docs/`) is development-only and deliberately stays out.

## One rule

**After changing anything under `skills/` or `testing/`, run `./testing/run.sh`.**

That is the whole checklist. There is deliberately no list of "things to keep in sync" here — the manifests, the README index and the package list all derive from the disk, and `testing/structure/invariants.sh` is what checks they still agree. A hand-maintained list beside a script that checks the same thing is a second source of truth, and the first time they disagree the list becomes a lie.

Read `testing/structure/invariants.sh` to see what is actually enforced. It is the authority, not this file.

## The four gates

Ordered by cost. `./testing/run.sh` runs the two free ones; the paid ones have their commands in their own READMEs. Costs are measured, not estimated — 2026-08-27.

| | What it judges | Cost | Where | In CI |
|---|---|---|---|---|
| 0 | Disk structure, and that each assertion can actually fail | $0 | `testing/structure/` | **yes** |
| 1 | The eval suite's schema, and every grader's coherence | $0 | `testing/preflight.sh` | no — needs the `claude` CLI, auth, and a gated feature |
| 2 | Whether a grader can tell right from wrong | $0.74 a round (8 fixtures) | `testing/grader-check/` | no — costs money |
| 3 | Whether the plugin changes behaviour | $2.60/run; ~$36 for a full `--runs 3` | `testing/evals/` | no — costs money |

**A green CI does not mean mergeable.** `.github/workflows/gates.yml` runs `./testing/run.sh` — the same entry point as locally — and there that amounts to gate 0 only, because it is the only one that is both free and self-contained. Gate 1 is free too and still cannot run there: with no `claude` CLI on the runner, it skips itself. The one rule above is unchanged: run `./testing/run.sh` locally, which does run gate 1.

Gate 1 is `claude plugin eval --max-cost-usd 0`: the suite is fully loaded, validated and coherence-checked, then every run is skipped. It costs nothing and takes under a second. That surface has **no public documentation page**; its reference lives inside the `claude` binary. `docs/reference/EXTRACT.md` extracts it to `docs/reference/plugin-eval.md`, which is gitignored — it is Anthropic's text and does not ship under this repo's MIT license (ADR-0016). Extract it before working on the gates; the local copy is the documentation.

## What the invariants are protecting

Three of them exist because the failure already happened, and every one of those failures was **invisible in the output**:

- Four question-asking units once omitted their `call the Skill tool with "decision-interview"` line. The behaviour looked completely normal — the model produces recommendations-with-costs on its own — so nothing in the output revealed that the discipline was never loaded. It was briefly misdiagnosed as "skill composition is probabilistic".
- A precondition gate was written without one of its qualifiers, which would have permanently blocked every maintenance edit on an existing project.
- A pull request described a mechanism — "invariants.sh gained a 24th check" — with a supporting table of statistics. Neither the check nor the statistics ever existed. Nothing disagreed, because nothing was comparing the prose to the code.

If you find yourself reasoning from "the output looks right" to "the mechanism works", stop. That inference has been wrong here three times, and the third time the "output" being trusted was a description of a test.

**The same trap applies one level up.** An assertion that exists is not an assertion that can fail, and an assertion that can fail against the violation you had in mind is not one that can fail against the same violation written differently. Both of those have shipped here green. That is why `testing/structure/invariants-effectiveness.sh` exists, and why a new assertion is not finished until it has a case there.

## Fingerprint assertions

The recurring defect in this repo is an assertion anchored on a **fingerprint of the currently-correct file** rather than on the rule. Fingerprints hold the file still; they do not stop a different spelling. When writing one, say in a comment what it is anchored on — a word, a list, a structure, a syntactic position, a closed set — and for a word or a list, say what gets through.

This is where the recursion stops. A check that enforced "every assertion declares its anchor" would itself be anchored on a word. It is a review item, on purpose.

## Decisions

`docs/adr/` records decisions about **developing this plugin** — positioning, principles, package boundaries, implementation order. It is not the same namespace as the ADRs the plugin writes into a user's project (`docs/ui-contract/adr/`), which record decisions about *that* project's interface.

Accepted records are not edited. A single decision inside one is overturned by writing a new record that supersedes it. Paths inside accepted records go stale when directories move; invariant 27 warns about that rather than failing, and the correction lives in a later record.
