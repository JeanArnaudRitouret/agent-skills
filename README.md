# agent-skills

Shared personal agent skills for Claude Code and Codex. Canonical instructions
live here; host directories use managed links instead of copied skill folders.

## Skills

### `add-agent-skill`

- Adds or updates a shared skill through one canonical source.
- Audits links, references, manifest entries, and README summaries before install.

### `audit-plan-zero-context`

- Audits a drafted plan from fresh-agent, zero-context perspective.
- Reports executable gaps without editing code or bypassing confirmation.

### `debug-function`

- Diagnoses Cognite Functions through hypotheses and instrumentation in real handlers.
- Covers local runs, dependency boundaries, OOM probes, and acceptance reruns.

### `explain-like-im-dumb`

- Explains code, changes, and flows with concrete names and values.
- Uses concise numbered steps and states limits of verification.

### `llm-prompt-design`

- Designs and reviews prompt templates sent to language models.
- Defines output contracts, input boundaries, examples, and edge cases.

### `memory-architecture-docs`

- Maintains `ROADMAP`, current-task, to-do, and done planning records.
- Requires zero-context implementation plans and explicit verification.

### `python-code-modification`

- Guides scripts that edit, move, or remove Python source blocks.
- Protects typed signatures and structural boundaries during mechanical changes.

### `python-commenting-standards`

- Reviews Python comments and docstrings for durable explanatory value.
- Keeps source free from private planning-document and incident references.

### `python-type-patterns`

- Chooses `Literal`, `StrEnum`, or `str` for closed string discriminator sets.
- Enforces single definitions for values such as `codex` and `claude`.

### `readme-best-practices`

- Writes and reviews README files as scannable, actionable entry points.
- Covers installation, commands, development, and maintenance documentation.

### `run-cdf-function-locally`

- Governs local Cognite Function execution and payload construction.
- Prevents unsupported flags and accidental use of wrong CDF project settings.

### `source-command-cdf-entity-matching-helper`

- Runs migrated CDF entity-matching helper workflows.
- Preserves unmatched-source semantics for downstream transformations.

### `test-driven-development`

- Drives feature behavior through focused RED, GREEN, and REFACTOR cycles.
- Requires causal evidence or documented exemption with alternate proof.
