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

## 3. The sync order is fixed

**Change the spec → change the type → write the code.** Never the reverse.

Reversed even once, the type becomes a record of what the code happens to do, and the spec becomes a description rather than a constraint.

## 4. Type-checking is not optional

Enforcement happens **during type-checking**. Skipping it means the compile-time layer isn't actually in force — and the code may not even compile, while you have told the user it is installed.

So: install, type-check, build, and **paste the real output**. If the environment can't install dependencies (offline, permissions), say explicitly that the compile-time layer is **unverified** and the user must run it locally. Never let "the code is written" cover for "it was never run".

## When the type system isn't available

If the project genuinely has no build step, say plainly what is given up: the enumeration becomes honour-system only, with no interception — and that is the most effective anti-drift mechanism there is.

Middle ground: keep the names as runtime markers in the output, and add a validation script that scans them against the enumeration. Better than nothing, weaker than the type system — a script has to be run deliberately, whereas type-checking is part of the build.
