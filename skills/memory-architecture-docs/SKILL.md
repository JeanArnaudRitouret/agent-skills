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
- Record decision immediately: `- Chose X over Y — reason Z.`
- Definition of Done must be observable: test count, query result, grep count,
  or exact behavior.

## TO_DO.md

### Structure

```md
### Phase N — Title

- [ ] **N.M** Concise atomic action:
  - Why this action exists.
  - Exact file, symbol, data shape, or constraint.
  → `command` exits 0 and output contains `expected value`.
```

Rules:

- One checkbox equals one coherent, reviewable change.
- Item title is one concise sentence.
- Put multiple actions, rationale, conditions, and snippets in sub-bullets.
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
- Run commands owned by TO_DO item; do not hand ordinary verification back to
  user.
- Prefer existing repository commands for reset, backfill, migration, and
  verification.
- Do not use ad hoc data-writing commands unless no safe defined command exists
  and user explicitly confirms.
- Record blockers and decisions in `CURRENT_TASK.md` as they appear.

## Session Loop

1. Read first unchecked TO_DO item.
2. Read CURRENT_TASK context needed for it.
3. Implement only item scope.
4. Run stated verification.
5. Mark item complete.
6. Report result and ask before next item when needed.
7. When phase is complete, request archive confirmation.
