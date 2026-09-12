---
name: audit-plan-zero-context
description: >
  Audit a drafted TO_DO phase for zero-context executability. Use as last step
  of heavy planning before posting a phase for confirmation, or when user asks
  "audit the plan", "is this plan self-contained", "zero-context check", or
  "$audit-plan-zero-context". A fresh Codex subagent checks whether another
  agent could execute the phase without guessing. Reports gaps only; makes no
  source edits; ends at the Confirmation Firewall.
---

# Audit Plan Zero-Context

## Scope

Apply before user approval for newly drafted, complex phase.

Do not apply during execution of already-approved phase. Record execution
blockers in `docs-ai/current/CURRENT_TASK.md` instead.

## Question

Could an agent with no memory of planning session execute this phase without
guessing?

## Process

1. Read target phase in `docs-ai/current/TO_DO.md`.

2. Spawn one fresh Codex subagent with only:

   - Phase block verbatim.
   - Paths to `docs-ai/current/CURRENT_TASK.md` and `TO_DO.md`.
   - Repository access equivalent to executing agent.
   - Prompt below.

   Do not give planning conversation, hidden reasoning, or clarification. If
   auditor needs information, planning docs must contain it.

   ```text
   You are executing this phase with zero prior context. Do not write code or
   edit files.

   For each item, in order, report a GAP when you cannot determine:

   - Exact file and symbol to change from item's locator.
   - Exact interface, type, schema, payload, or configuration shape.
   - Intent: why change exists.
   - Runnable verification command and expected result.
   - Constraints and non-goals preventing unrelated changes.
   - Rejected alternative behind any design decision.
   - Existing pattern or implementation to mirror.

   Then list questions you would need answered before starting.

   Report facts and gaps only. No praise, style feedback, recommendations, or
   source edits.
   ```

3. Classify each gap:

   - missing intent
   - vague location
   - missing interface or data shape
   - missing decision or rejected alternative
   - unverifiable criterion
   - missing constraint or non-goal
   - unwritten gotcha
   - missing reference implementation

4. Draft changes to planning docs that close each gap.

5. Report gaps and proposed doc edits. Stop. Do not apply edits or source-code
   changes until user confirms.

## Report Format

```text
GAP <number> — <item ID> — <gap class>
Missing: <what executor cannot know>
Add: <exact planning-doc text>

Questions requiring human answer:
- <question>

Executable without guessing: <passing items>/<total items>.
```

## Boundaries

- Do not feed auditor planning conversation.
- Do not answer gaps only in chat; record answers in planning docs.
- Do not reopen approved design decisions.
- Do not apply fixes in same response as audit report.
- Do not modify source files.

## Cross-Reference

`memory-architecture-docs` defines Context Transfer Contract, TO_DO format,
and Confirmation Firewall enforced by this audit.
