---
name: constraint-by-types
description: Push rules from prose down into the type system so violations become unwritable rather than merely forbidden. Enumerations in the spec become union types, prohibitions become omissions from those unions with a comment marking them deliberate, and the sync order runs spec first then type then code. Use when a written rule needs to survive contact with future code.
---

# Constraint by types

Documents rot; types don't. Of every enforcement layer available, only the compile-time one maintains itself — everything else depends on somebody choosing to read something.

## 1. Enumerations become union types

Whenever the spec enumerates a closed set of names, that set becomes a union type, and the thing that consumes those names takes the union as its parameter:

```ts
export type Slot = 'a' | 'b' | 'c'
```

Writing a name that isn't in the table now fails type-checking. That is not a documented convention — it is a compile-time constraint.

## 2. Prohibitions become omissions

Wherever the spec says "X must not hold things of kind Y", **delete Y from the corresponding union type**. A violation then can't be written at all.

**Put a comment next to the omission stating that it is deliberate.** Without it, the next agent reads the gap as an oversight and adds Y back — restoring exactly what the spec forbade.

This beats any `MUST` you could write in prose, and costs less than a lint rule.

### The comment marks the intent. It does not hold the line.

The omission is enforced in one direction only. The compiler catches code that **uses** the forbidden member. Nothing catches somebody **adding the member back** — at that moment every existing call site still compiles, the comment above the union is now describing a rule the union no longer has, and the output is identical. That is the shape of failure this whole skill exists to prevent, reproduced one level up.

So write each prohibition down as an assertion the compiler has to keep re-checking:

```ts
// ui-contract.assert.ts — imported by nothing, type-checked with everything.
//
// Every line below is a violation the spec forbids. The directive is what carries
// the rule: while the omission holds, the line errors and `@ts-expect-error`
// consumes that error. Put the forbidden member back and the error disappears,
// the directive becomes unused, and tsc fails here with TS2578.
//
// So a prohibition that gets quietly deleted breaks the build instead of going silent.

import type { Slot, Placement } from './contract'

// spec §6.2 — a row may not host its own actions
// @ts-expect-error 'actions' is deliberately absent from Slot
export const _noActionSlot: Slot = 'actions'

// spec §4.3 — the wizard step has no side panel
// @ts-expect-error 'wizard' is deliberately absent from Placement
export const _noWizardPanel: Placement = 'wizard'
```

Two mechanics decide whether this works at all, and both fail quietly:

- **`export`, not a bare `const`.** Under `noUnusedLocals` an unused local is itself an error, and the file then fails for a reason that has nothing to do with the contract. Exporting takes it out of that rule's reach.
- **The file has to be inside the project's typecheck.** It is imported by nothing, which is exactly the kind of file a narrow `include` leaves out — and a `.assert.ts` that no compiler ever reads is indistinguishable, in the output, from one that passes.

This is the one place the type layer guards **itself**. Every other rule here protects the code from drifting away from the type; this protects the type from drifting away from the spec.

## 3. The sync order is fixed

**Change the spec → change the type → write the code.** Never the reverse.

Reversed even once, the type becomes a record of what the code happens to do, and the spec becomes a description rather than a constraint.

## 4. Type-checking is not optional

Enforcement happens **during type-checking**. Skipping it means the compile-time layer isn't actually in force — and the code may not even compile, while you have told the user it is installed.

So: install, type-check, build, and **paste the real output**. If the environment can't install dependencies (offline, permissions), say explicitly that the compile-time layer is **unverified** and the user must run it locally. Never let "the code is written" cover for "it was never run".

## When the type system isn't available

If the project genuinely has no build step, say plainly what is given up: the enumeration becomes honour-system only, with no interception — and that is the most effective anti-drift mechanism there is.

Middle ground: keep the names as runtime markers in the output, and add a validation script that scans them against the enumeration. Better than nothing, weaker than the type system — a script has to be run deliberately, whereas type-checking is part of the build.
