---
name: test-driven-development
description: >
  Mandatory before production edits for new features or behavior updates in
  every language and test framework. Use for bug fixes with a feasible focused
  regression test and untested refactors after characterization. Discover
  project test commands, paths, and patterns. Docs-only, formatting, and
  behavior-preserving renames need documented exemption and alternate proof;
  “small” alone is not an exemption. Record causal RED evidence when planning
  records exist.
---

# Test-Driven Development

## Why and when

TDD makes intended behavior executable before implementation exists. It is a
design and regression-control practice, not a promise that every task is faster.

Test observable contract: given an input and precondition, expect an output,
state change, error, or stored result. Do not test private method structure or
implementation sequence when consumers cannot observe it.

Use focused tests when new code contains decisions: branches, validation,
mapping, parsing, joins, filters, date logic, window logic, state transitions,
or external contracts. Do not create isolated tests for language/runtime
primitives that already provide the signal.

## Test map

Before coding, list ordered behavior cases. Each case states:

```text
Given: <precondition and input>
When:  <public action>
Then:  <observable result>
```

Start with smallest case that forces a useful interface or decision. Add a
happy path, boundary, invalid/error case, and known regression case only when
each changes behavior. Do not write whole feature suite at once.

For every chosen case, plan exact test path/name, production path/symbol,
targeted command, broader regression command, expected RED assertion, and
expected GREEN result.

## RED

1. Add one test for next behavior before changing production code.
2. Run exact targeted command.
3. Confirm non-zero exit comes from intended assertion: expected result versus
   actual pre-feature result.
4. Confirm planned production files remain unchanged during RED.

Valid evidence contains test identifier, command, exit status, expected value,
and actual value. These do not count as RED: syntax/import failure, missing
fixture, unavailable dependency, connection error, skipped test, timeout, or
unrelated pre-existing failure.

If test passes before production change, stop. Behavior may already exist, or
test may not observe intended contract. Inspect actual behavior and sharpen the
test or remove duplicate work before continuing.

## GREEN

Write smallest production change that makes current RED test pass. Name exact
production file and symbol before editing.

Run same targeted command after change. It must exit 0. Do not weaken expected
result, skip/delete test, broaden fixture until assertion disappears, or add
untested future behavior merely because it seems likely needed.

If production change exposes another behavior, add it to test map. Complete
current GREEN first; begin next behavior with RED.

## REFACTOR

Refactor only after current targeted test is green. Make small,
behavior-preserving structural improvements: remove duplication, improve names,
or extract a cohesive helper.

Run targeted test after each structural change. If contract changes, stop
refactoring and begin a new RED cycle. Finish by running relevant broader
regression command.

## Test quality

Tests describe behavior, not construction. Prefer real domain inputs and
outputs over assertions about private helpers, call order, or mock internals.

Avoid:

- Trivial accessors or runtime/library behavior.
- Production algorithm copied into test expectation.
- One broad test hiding several independent behaviors.
- Fixtures much larger than behavior requires.
- Assertions omitted or too weak to reject wrong result.
- Slow full-suite command as inner loop when focused command exists.

Mock or fake only I/O boundaries such as network, clock, filesystem, database
client, or third-party service. Do not mock core domain behavior that test must
prove.

## Agent integrity

During RED, do not edit planned production files. Record causal evidence before
GREEN. If test changes after it was green, rerun RED before relying on it again.

At review, verify test names and assertions describe user/consumer behavior and
that implementation did not make tests pass by weakening contract. For
high-risk paths, consider an independent reviewer or a temporary revert/mutation
check proving new test fails without production change.

Never claim TDD proof from coverage alone. Coverage shows execution, not whether
test detects wrong behavior.

## Exemptions

An exemption records all three facts:

```text
Reason: <why focused automated test has no meaningful signal or cannot run safely>
Rejected test: <test type considered> — <why it is not useful>
Alternate proof: <exact command/check> -> <observable expected result>
```

Valid examples: docs/comment/format-only change; pure behavior-preserving rename
with compile/type/reference proof; configuration change with no focused runtime
contract but a stronger available validation. Existing coverage is an exemption
only when change does not alter behavior.

## Evidence format

When repository uses planning records, planned item contains full implementation
details plus concise TDD fields:

```md
- TDD: required
- Contract: Given <input>, when <action>, then <result>.
- Test map: `<case_1>`, `<case_2>`.
- RED: `<test path>::<test name>`; `<targeted command>`.
  Expected: `<assertion failure>`.
- GREEN: `<production path>::<symbol>`; smallest change: `<behavior>`.
- REFACTOR: `<allowed cleanup>`.
→ `<broader regression command>` exits 0 and output contains `<expected result>`.
```

After execution, record concise evidence in both planning records:

```md
- RED evidence: `<command>` exited 1; expected `<value>`, got `<value>`;
  production files unchanged.
- GREEN evidence: `<command>` exited 0 after `<production symbol>` changed.
```

When repository has no planning architecture, do not create one merely for TDD.
Keep same evidence in task handoff or review record if project has an approved
equivalent.

## Python adapter

Use repository’s existing test runner, normally a focused pytest node such as:

```bash
pytest <test path>::<test name> -q
```

Test public function, command, API, or module behavior. Use descriptive behavior
names such as `test_rejects_empty_<identifier>`. Prefer Arrange/Act/Assert or
Given/When/Then. For legacy refactors, first characterize observed behavior,
including edge cases, before structural edits.

After GREEN, run nearest module/package suite, then project-required type/lint
checks. Use actual repository commands, not this example if they differ.

## dbt adapter

Use native `unit_tests:` before SQL changes for logic with controlled inputs:
joins, filters, `case` branches, date/window logic, deduplication, mappings, and
incremental branches. Put unit-test YAML under project `model-paths`, alongside
models. Include every `ref`/`source` as an input and alias relations in joins.

Run focused unit test using repository command, typically:

```bash
dbt test --select "<model>,test_type:unit" --target <development target>
```

Use `data_tests:` plus targeted `dbt build` after GREEN for actual-data
invariants: grain, keys, relationships, accepted values, reconciliation, and
source assumptions. Do not unit-test warehouse primitives with no project logic.

On adapters without local unit-test execution, keep fixtures minimal and use the
approved development target. Never replace unit logic test with an unscoped
production build.

## Other stacks

Before first test, discover:

1. Existing test runner and focused selector.
2. Existing test-file location and naming convention.
3. Fastest test type proving intended contract.
4. Broader required regression/build/type/lint command.

State discovered paths and commands in implementation plan. If no executable
test path exists, use exemption process; do not invent a framework inside a
feature change unless approved scope includes test infrastructure.
