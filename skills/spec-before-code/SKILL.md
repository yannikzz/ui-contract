---
name: spec-before-code
description: Keep a written specification ahead of the implementation it governs. Documents change first and code follows; holes the implementation exposes are written back as rules rather than patched silently; overturned conclusions move to an appendix instead of being deleted. Use when a project has a spec that code is supposed to obey, and change requests are arriving.
---

# Spec before code

The spec is a constraint on future work, not a description of existing work. The moment code leads and the document follows, it has quietly become the latter.

## Handling a change request

Once the user sees something running, change requests arrive. For each one:

1. **First judge whether it belongs in the spec at all.** Recording "right-align it" or "add a button" verbatim is nearly worthless; the value is in the **rule it forces**. Ask: what constraint is behind this request, and would it still hold under different surface choices?
2. **Name the existing clause it collides with.** New requests frequently contradict prohibitions you wrote yourself — surface that, then change the prohibition or the request. **Never let both stand.**
3. **Documents change first, code follows.** Always.
4. **When overturning an old conclusion, don't delete it.** Move it to the *Overturned* appendix with the reasoning. Overturned judgements are easier to re-tread than current ones, precisely because they looked reasonable — they looked reasonable to you too, once.
5. **Report precisely what changed**: which sections, which new prohibitions, what followed in the code.

## Building the thing exposes the spec's holes

This is the part people skip. Implementing a spec surfaces questions the spec never answered — a case that was never decided, a combination nobody walked through. That exposure is **the point**, not an interruption.

When it happens: **write the rule into the document first, then write the code.** Never quietly add a rule to the code that the document doesn't state. A rule that lives only in code is a rule the next agent will overwrite without knowing it existed.

(Detecting drift *after* the fact is a different job with a different owner. This skill is only about staying ahead of it while you work.)

## When you were wrong earlier

If you discover mid-implementation that something you said earlier was inaccurate — you promised a property the design can't actually deliver, say — **say so and correct it**. Do not leave the wrong conclusion standing in the document because correcting it is awkward.
