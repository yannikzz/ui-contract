# Working on this repo

This repository ships **15 skill packages**. `skills/` is the only directory installed to users; everything else (`tests/`, `evals/`, `examples/`, `docs/`) is development-only and deliberately stays out.

## One rule

**After changing anything under `skills/`, run `./tests/run.sh`.**

That is the whole checklist. There is deliberately no list of "things to keep in sync" here — the manifests, the README index and the package list all derive from the disk, and `tests/structure.sh` is what checks they still agree. A hand-maintained list beside a script that checks the same thing is a second source of truth, and the first time they disagree the list becomes a lie.

Read `tests/structure.sh` to see what is actually enforced. It is the authority, not this file.

## What the invariants are protecting

Two of them exist because the failure already happened once, and both failures were **invisible in the output**:

- Four question-asking units once omitted their `call the Skill tool with "decision-interview"` line. The behaviour looked completely normal — the model produces recommendations-with-costs on its own — so nothing in the output revealed that the discipline was never loaded. It was briefly misdiagnosed as "skill composition is probabilistic".
- A precondition gate was written without one of its qualifiers, which would have permanently blocked every maintenance edit on an existing project.

If you find yourself reasoning from "the output looks right" to "the mechanism works", stop. That inference has been wrong here twice.

## Decisions

`docs/adr/` records decisions about **developing this plugin** — positioning, principles, package boundaries, implementation order. It is not the same namespace as the ADRs the plugin writes into a user's project (`docs/ui-contract/adr/`), which record decisions about *that* project's interface.

Accepted records are not edited. A single decision inside one is overturned by writing a new record that supersedes it.
