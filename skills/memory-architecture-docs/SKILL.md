---
name: memory-architecture-docs
description: >
  Use when a repository has docs-ai/current/ or docs-ai/roadmap/, or when the
  user asks to create this planning architecture. Covers reading, planning,
  creating, editing, checking, and archiving ROADMAP.md, CURRENT_TASK.md,
  TO_DO.md, and DONE.md. Also use before implementing work governed by an
  unchecked TO_DO.md item.
---

# Memory Architecture Docs

## Scope

Apply only when repository contains `docs-ai/`, or user asks to adopt this
architecture. Do not create `docs-ai/` merely because repository uses Codex.

All memory docs live at repository root:

```text
docs-ai/
├── current/
│   ├── CURRENT_TASK.md
│   ├── TO_DO.md
│   └── DONE.md
└── roadmap/
    └── ROADMAP.md
```

Never create these files elsewhere.

`AGENTS.md` contains Codex-specific repository guidance. This skill governs
planning architecture; do not duplicate unrelated `AGENTS.md` rules here.

## Context Transfer Contract

Write plans for an agent with zero knowledge of this session.

Every planned item must preserve:

1. Intent: why action matters.
2. Exact location: file path, symbol, line anchor when useful.
3. Interface: real function signature, schema, payload, or config shape.
4. Decision: chosen option, rejected option, and reason.
5. Verification: command plus observable expected result.
6. Constraints: compatibility, non-goals, untouched files, performance limits.
7. Gotchas: surprising callers, data states, deployment details, or risks.
8. Pattern to mirror: existing file or implementation when one exists.

For a TDD-required item, preserve these fields in addition to all eight
requirements:

9. Behavioral contract: Given / When / Then observable behavior.
10. Test location and name: exact test path and identifier.
11. Commands: exact RED, GREEN, and broader regression commands.
12. Expected proof: RED assertion failure and GREEN result.
13. Exemption decision: when applicable, reason, rejected test, and alternate
    proof.

A plan fails if executor must rediscover decision, location, or data shape.

For a complex phase, run `audit-plan-zero-context` before posting it for user
confirmation.

## ROADMAP.md

- Location: `docs-ai/roadmap/ROADMAP.md`.
- Holds major future phases only.
- Read once when broad project direction matters.
- Update when major phase completes or next phase moves into `CURRENT_TASK.md`.

## CURRENT_TASK.md

Use this fixed section order:

```text
Goal
Architecture
Key Files
Key Findings & Risks
Decisions Log
Definition of Done
```

Rules:

- Store patterns, diagrams, paths, contracts, and decisions.
- Do not store implementation bodies.
- Under `Key Findings & Risks`, keep TDD evidence in a `### TDD Evidence`
  subsection with columns: `Item`, `Contract`, `RED`, `GREEN / regression`,
  and `Exemption`.
- Record only durable TDD evidence: causal test result, production symbol
  changed, regression result, or accepted exemption. Do not copy implementation
  bodies into this record.
- Record decision immediately: `- Chose X over Y — reason Z.`
- Definition of Done must be observable: test count, query result, grep count,
  or exact behavior.

## TO_DO.md

### Structure

```md
### Phase N — Title

- [ ] **N.M** Concise feature behavior:
  - Why this action exists.
  - Production plan: `<production path>::<symbol>`; interface/data shape:
    `<input> -> <output>`; intended smallest change: `<behavior>`.
  - Test plan: `<test path>::<test name>`; pattern to mirror:
    `<existing test>`.
  - Constraints, non-goals, and rejected alternative: `<details>`.
  - TDD: required|exempt.
  - Contract: Given `<precondition/input>`, when `<action>`, then
    `<observable result>`.
  - Test map: `<case 1>`; `<boundary/error/regression case when relevant>`.
  - RED: `<targeted command>`; expected assertion:
    `<expected>`, actual pre-feature result: `<actual>`; production files
    unchanged.
  - GREEN: `<production path>::<symbol>`; smallest change:
    `<behavior>`; `<targeted command>` exits 0.
  - REFACTOR: `<behavior-preserving cleanup or none>`; rerun targeted command.
  - Regression: `<broader regression command>` exits 0 and output contains
    `<expected result>`.
  - When TDD: exempt — Reason: `<why focused test has no signal or cannot run
    safely>`; Rejected test: `<type> — why`; Alternate proof:
    `<command/check> -> <observable result>`.
  - RED evidence: `<command>` exited 1; expected `<value>`, got `<value>`;
    production files unchanged.
  - GREEN evidence: `<command>` exited 0 after `<production path>::<symbol>`
    changed; regression `<command>` exited 0.
  → `<regression command>` exits 0 and output contains `<expected result>`.
```

Rules:

- One checkbox equals one coherent, reviewable change.
- Item title is one concise sentence.
- Put multiple actions, rationale, conditions, and snippets in sub-bullets.
- TDD fields supplement, never replace, exact planned production/test paths,
  symbols, interfaces, data shapes, constraints, non-goals, rejected
  alternatives, and pattern to mirror.
- Include `BEFORE` / `AFTER` snippets for non-trivial code changes when they
  remove ambiguity.
- Use placeholders such as `{{table_name}}`, never project-specific IDs.
- State dependencies, preconditions, rollback, invariants, and non-goals when
  relevant.
- Mark destructive work with `⚠️ DESTRUCTIVE`.
- Destructive work always requires user confirmation before execution.
- Do not add speculative work. Put future ideas in `CURRENT_TASK.md` or leave
  them out.

### Verification

- Every item ends with concrete `→` acceptance criterion.
- Prefer verification as final sub-bullet of change item.
- Create standalone verification item only when it has isolated purpose and
  observable output.
- “Runs clean,” “reviewed,” and “looks correct” are invalid criteria.
- Risky criteria need escape hatch:

  `→ DIFF_CLEAN; if DIFF_FOUND, STOP and investigate.`

## TO_DO Gate

Never modify source code unless exact action exists in unchecked `TO_DO.md`
item.

For a TDD-required item, invoke `test-driven-development` before production
edit. Record causal RED proof in both `TO_DO.md` and `CURRENT_TASK.md` before
GREEN implementation. An exemption requires reason, rejected test, and
explicit alternate proof in both records.

When requested work is absent:

1. Add proposed item or items to `TO_DO.md`.
2. Show user exact additions.
3. Stop.
4. Wait for explicit approval before source-code changes.

Do not write TO_DO items and implement them in same response.

During execution, if required action falls outside current item:

1. Stop before editing source.
2. Propose new TO_DO item.
3. Wait for approval.

When user asks `check N.M`, `tick N.M`, or `mark N.M done`, only update that
checkbox unless they ask for more.

When user says `implement N.M` or `proceed`, execute existing unchecked item
rather than re-planning it.

## DONE.md

- One line per completed phase:

  `- **Phase N:** Summary (completed YYYY-MM-DD)`

- Archive only after user confirms phase works.
- Then add DONE entry and remove completed phase from `TO_DO.md`.
- Do not archive individual hotfixes or one-off tasks.

## Source-Code Boundary

Planning-doc names, phase IDs, and checklist references must not leak into
source code, comments, docstrings, or literals.

Write durable rationale in code itself. Never write:

```text
See TO_DO.md
Per Phase 3
CURRENT_TASK item 3.2
```

Before completing source item, check touched files for:

```text
TO_DO
CURRENT_TASK
DONE.md
ROADMAP
```

Expected result: zero planning-document references.

## Execution Discipline

- Read current `TO_DO.md` before beginning next item.
- Work one checkbox at a time unless user explicitly approves batch.
- For TDD-required behavior, write and run one focused test before production
  edit; do not start GREEN until RED fails for intended assertion.
- After GREEN and relevant regression proof, update both `TO_DO.md` and
  `CURRENT_TASK.md` with concise RED/GREEN evidence before checking item.
- Run commands owned by TO_DO item; do not hand ordinary verification back to
  user.
- Prefer existing repository commands for reset, backfill, migration, and
  verification.
- Do not use ad hoc data-writing commands unless no safe defined command exists
  and user explicitly confirms.
- Record blockers and decisions in `CURRENT_TASK.md` as they appear.

## Session Loop

1. Read first unchecked TO_DO item.
2. Read CURRENT_TASK context needed for it and preserve full implementation
   plan.
3. For TDD-required work, invoke `test-driven-development`, write next test,
   run RED, and record causal evidence in both planning records.
4. Implement only smallest GREEN change for current contract; rerun focused
   test.
5. Refactor only with focused test green; run stated broader regression.
6. Record GREEN/regression proof or exemption alternate proof in both records.
7. Mark item complete.
8. Report result and ask before next item when needed.
9. When phase is complete, request archive confirmation.
