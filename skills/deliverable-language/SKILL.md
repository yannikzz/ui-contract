---
name: deliverable-language
description: Write deliverables in the language the user is speaking, and pin one rendering per concept so terminology stays stable across runs. Covers picking the language without asking, recording term choices in the authoritative document, and keeping a translated vocabulary consistent. Use whenever a skill produces written artifacts for a user whose language may not be the skill body's language.
---

# Deliverable language

Skill bodies are written in one language. **Deliverables follow the user's.** Those are different questions and they get different answers.

## Pick it, don't ask

Write the deliverables in **the language the user is speaking**. Do not ask which language they want, and do not make it a configuration option — just follow them.

Asking implies it is negotiable and costs a turn on something you can already observe.

## Pin one rendering per concept

The failure mode this exists to prevent is concrete: **the same concept gets translated differently on every run**, so two projects — or two agents on one project — end up unable to talk to each other. One writes it one way, the next writes it another, and neither is wrong in isolation.

So:

- If the invoking skill ships a canonical term table for the user's language, **use those exact terms**. Don't improve on them; consistency is worth more than a better word.
- If it doesn't, pick **one** rendering per concept, **write your choices into a glossary section of the authoritative document**, and stay consistent for the rest of the project.

That glossary section is not decoration. It is what lets the next run — or the next agent — reuse your vocabulary instead of inventing a parallel one.

## What stays untranslated

Identifiers that the code or a machine consumes — type names, keys, attribute values, file names — stay in their original form regardless of the deliverable's language. Translating a name that something greps for breaks the thing the name existed for.

The human-readable label next to such an identifier does get translated. The identifier itself never does.

## Mixed-language projects

If the project's existing documents are in one language and the user is speaking another, say what you found and let them choose; don't silently switch a project's language halfway through. Matching the existing documents is usually right, but that is their call, not yours.
