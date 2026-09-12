---
name: explain-like-im-dumb
description: Explain anything — a bug, a data flow, a proposed change, a chunk of the codebase, a piece of logic — in the plainest possible words, as a numbered step-by-step with real names and real values, plus a before/after when something changes. TRIGGER when the user says "explain", "explain simply", "ELI5", "explain like I'm dumb", "what is the issue", "how does this work", "walk me through", "I don't understand", or when you are about to describe a problem/flow/change in prose longer than three sentences. Also trigger when handing back a diagnosis the user must act on.
---

# Explain Like I'm Dumb

Goal: the reader finishes the explanation knowing **what is broken, why it matters, and what changes** — without knowing the codebase, without re-reading, and without asking a follow-up to decode a word you used.

Assume a smart reader with zero context on this system. Not a stupid reader — an unfamiliar one. Never write down to them; write *clearly* to them.

---

## The four rules (all four, every time)

1. **SIMPLE.** Plainest framing that is still true. No theory, no abstraction layer, no jargon. If a 12-year-old could not follow the *structure*, rewrite it.
2. **CONCRETE.** Every claim carries a real example — a real file, a real function, a real value, a real input → output pair. Banned: "the parser normalizes IDs". Required: "`parse_step()` turns `'step-42'` into `42`".
3. **STEP-BY-STEP.** A numbered list. One fact or one action per step. Never a paragraph where a list would do.
4. **CONCISE.** Only what the reader needs to act. Cut every step, sentence, and example they do not need.

Concise ≠ vague. Cut *words*, never the concrete detail that makes a step checkable.

---

## Required shape

### Explaining a problem

```
## The issue

1. <what the code is trying to do — one plain sentence>
2. <how it tries to do it — name the function and file>
3. <the thing that is actually false — with the measured number>
4. <what the code does as a result>
5. <why that is bad / what it silently breaks>
```

One numbered chain, cause first, consequence last. The reader should be able to stop at any step and still have learned something true.

### Explaining a change

Always **before / after**, always the smallest diff that carries the meaning:

```
// BEFORE (file.py, ~L156)
<the 2-5 lines as they are>

// AFTER
<the same lines, changed>
```

Then a result table proving it does what you claim:

| | result |
|---|---|
| before | `['255450', '258626', '258626']` → includes the "Suivant" button |
| after | `['255450', '258626']` → menu only |

### Explaining a flow

Numbered steps, each naming a real `file.py::function()`, each with the actual data at that point. No narration between steps.

---

## Rules for words

- Use the short word. "speed" not "performance characteristics". "fix" not "remediate". "wrong" not "suboptimal".
- The first time a system-specific term appears, say what it is in the same sentence: "Bronze (the raw HTML we save before parsing)".
- Never make the reader hold two unexplained things at once.
- A sentence with two commas and a subordinate clause is two steps. Split it.
- Say the number. "0 of 1538 pages" beats "essentially never".

---

## Always end with the limits

State plainly what the explanation does **not** cover, and what you did **not** verify. Two lines, no hedging language:

> Two things this fix does not cover: the same selectors are duplicated in the skill file; and any training scraped earlier may hold a wrong order.

If a number is measured, say so. If it is assumed, say that instead. Never let a guess wear the costume of a measurement.

---

## Correct yourself in place

If an earlier explanation of yours was wrong, say the corrected fact plainly at the top of the new one and move on:

> Correcting my earlier claim: the "button before the menu" case **does not occur** — 0 of 1538 pages. I overstated that risk.

One line. No apology, no post-mortem of how you got it wrong.

---

## Anti-patterns

- ✗ A paragraph where a numbered list belongs.
- ✗ "The system handles X" — which function, in which file?
- ✗ An abstract claim with no example after it.
- ✗ Explaining the mechanism when the reader asked what is broken.
- ✗ Jargon introduced without a plain-words gloss on first use.
- ✗ A described change with no before/after block.
- ✗ A before/after with no evidence it produces the claimed result.
- ✗ Hedging that hides whether something was measured ("appears to largely never happen").
- ✗ Burying the consequence at the end of a long sentence.
- ✗ Widening the topic beyond what was asked because it felt incomplete.

---

## Self-check before sending

1. Is every step one fact?
2. Does every claim have a real name or real value attached?
3. Could someone who has never seen this repo follow it?
4. If something changes — is there a before/after AND proof it works?
5. Did I say what I did not check?
6. Can I delete a step and lose nothing? Delete it.
