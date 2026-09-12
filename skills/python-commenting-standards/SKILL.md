---
name: python-commenting-standards
description: Comment and docstring standards for Python in AIP. TRIGGER when cleaning up comments or docstrings, reviewing code before commit for comment quality, writing new Python modules (Cognite Functions, scripts, Streamlit apps), or user says "too many comments" / "audit docstrings".
---

# Python Commenting Standards

Apply this skill when:
- Cleaning up comments or docstrings in any Python file
- Reviewing code before commit for comment quality
- Writing new Python modules in AIP (Cognite Functions, scripts, Streamlit apps)
- Writing ANY new comment or docstring as a side effect of other work — extracting a helper function, adding a cross-link note between two near-duplicate code paths, leaving a deferred-work note. The skill applies at the moment the comment is drafted, not only during a dedicated cleanup pass.
- A user says "too many comments", "clean up comments", "audit docstrings", or similar

---

## 1. The Foundational Rule: Why, Not What

Code shows *what* happens. Comments explain *why*. If a reader can infer the "what" from the code itself, the comment is noise — and noise goes stale.

**Audience:** write for a new contributor with no access to internal planning documentation (`docs-codex/`, `docs-claude/`, `docs-ai/`), chat history, ticket tracker, or post-mortems. If the comment only makes sense to someone who has read that documentation, a Slack thread, or an incident report, rewrite it as a self-contained statement of the invariant or constraint being protected.

**Complexity carve-out:** for genuinely complex code (non-obvious algorithm, tricky concurrency, dense math), it is acceptable to also explain *how* — but only alongside the *why of the complexity* (the constraint that forced the unusual approach). Never explain the *how* alone.

**Bad — restates the code:**
```python
# Retry 3 times
for _ in range(3):
    call_api()

# Convert set to list
result = list(unique_items)
```

**Good — explains the constraint or intent:**
```python
# CDF time-series ingest occasionally 502s during leader election;
# 3 retries covers the typical ~6s failover window.
for _ in range(3):
    call_api()
```

---

## 1a. Plain Words, Hard Budget (comments are for someone dumb)

Write every comment for a smart reader with ZERO project context and ZERO
domain vocabulary. If a word needs the project, the platform, or browser
internals to be understood, gloss it in the same line or drop it.

Same four rules as the `explain-like-im-dumb` skill, applied to comments:
SIMPLE (plainest true framing), CONCRETE (real names, real values),
CONCISE (only what the reader needs) — and structure over prose.

**Hard rules:**

0. **Necessity filter first — cut, don't compress.** A comment keeps only
   what the next editor must know to avoid breaking the code. Everything
   else is deleted, not squeezed into denser sentences. A 3-line comment
   that crams five facts is as bad as a 7-line essay.
1. **Block comments: 3 lines maximum.** Anything longer is documentation and
   belongs in the docstring of the function that owns the behaviour — or is
   narrative and belongs nowhere.
2. **One fact per sentence.** No em-dash chains packing three findings into
   one sentence.
3. **No jargon without a gloss.** "overlay interception", "actionability
   checks", "synthetic HTML5 drag", "clone semantics" — banned unless the
   same line says what it means in plain words ("fake drag events", "another
   element sits on top and swallows the click").
4. **No measurement narrative.** "established by live measurement", "measured
   2026-08-31", "after the redesign" — that is history; git and the docs
   carry it. State the rule, not how you learned it.
5. **Never duplicate the functions' own docstrings.** If each function below
   a shared comment explains its own why, the shared comment shrinks to a
   pointer: `# See each function's docstring for how and why.`

**Bad — 7-line essay, stacked jargon, duplicates the docstrings below it:**
```python
# The redesign ships two drag widgets that need different techniques, both
# established by live measurement. The matching-pair widget is keyboard-driven:
# Enter on a source selects it, Enter on a zone places it — and Enter on a
# FILLED zone removes the placement again, so filling must only ever touch
# empty zones. The fill-the-blanks widget accepts a synthetic HTML5 drag
# (DragEvent + DataTransfer); pointer-based drags die on overlay interception
# and its blanks never become focusable, so neither mouse nor keyboard works.
```

**Good — pointer, 2 lines:**
```python
# Selectors for the two drag question types. How each is answered, and why
# only that way works, is on auto_answer_redesigned_pairs / _words below.
```

The load-bearing facts (Enter on a filled zone removes the word; fake drag
events are the only thing the blanks accept) move into the docstrings of the
functions that act on them — one fact each, plain words.

---

## 2. PEP 8 / PEP 257 Rules That Matter

**Inline comments** — at least two spaces from code, then `# ` (hash + single space). Use sparingly; only where the why cannot be expressed any other way.

**Block comments** — same indent level as the code they describe. Each line starts `# `. Separate paragraphs with a line containing only `#`.

**Docstrings** — always triple-double-quotes `"""..."""`, even one-liners (PEP 257).

**One-liner docstrings** — fit on one line, end with a period, written in **imperative mood**:
```python
# CORRECT
def get_user():
    """Return the current authenticated user."""

# WRONG
def get_user():
    """Gets the user."""   # (descriptive mood, trivial)
```

**Multi-line docstrings** — summary line, blank line, elaboration. Closing `"""` on its own line.

**Module docstring** — first statement in every file, above imports.

**Public API only** — every public module, class, and function gets a docstring. Private helpers only when non-obvious.

Sources: [PEP 8](https://peps.python.org/pep-0008/#comments), [PEP 257](https://peps.python.org/pep-0257/)

---

## 3. Docstring Style: Google (Recommended)

Use **Google style** for all new docstrings. It is the most readable in plain-text diffs and is supported natively by every major IDE and `sphinx.napoleon`.

```python
def fetch_assets(client: CogniteClient, space: str, view_id: str) -> NodeList:
    """Fetch all asset nodes from a CDF data model view.

    Args:
        client: Authenticated Cognite client.
        space: FDM space containing the view.
        view_id: External ID of the view to query.

    Returns:
        NodeList of asset nodes, potentially empty if the view has no instances.

    Raises:
        CogniteAPIError: On network or auth failures after retries are exhausted.
    """
```

NumPy style is only worth the extra vertical space for heavily scientific APIs with many array parameters. reST is hostile to plain-text reading.

Reference: [Google Python Style Guide — Docstrings](https://google.github.io/styleguide/pyguide.html#38-comments-and-docstrings)

---

## 3a. New Concepts Introduced by a Function Must Be Explained in Its Docstring

If a function invents a new distinction — a local variable, a return value, a category, a flag — that doesn't already have an established meaning in the codebase, the docstring must explain what it means and when it fires. A `Returns:` line that only repeats the variable names is not documentation; the names describe *what* is returned, not *why* the split exists or what each branch means for the caller.

This applies most often to functions returning a tuple, dict, or Pydantic model whose fields encode a classification the function itself invents.

**Bad — names only, no semantics:**
```python
def _diff_common_steps(...) -> tuple[list[int], list[int], bool]:
    """Flag same-id type drift for steps present both live and in the sidebar.

    Returns (type_mismatch_step_ids, scorm_shell_step_ids, undetectable_migration).
    """
```
A caller (or reviewer) cannot tell from this what makes a step land in one bucket vs. another, or what `undetectable_migration` actually signals.

**Good — each concept explained where it's introduced:**
```python
def _diff_common_steps(...) -> tuple[list[int], list[int], bool]:
    """Flag same-id type drift for steps present both live and in the sidebar.

    Three independent drift signals, each a separate reason to requeue:
      - mismatched: stored step_type disagrees with the sidebar's current
        type_hint, and the pair isn't a known permanent vocabulary drift —
        the platform silently swapped this step's content type in place.
      - scorm_shells: stored step_type is already 'scorm'. Existing scorm
        rows are empty ~1.5KB wrapper shells regardless of the hint, so
        they always need a re-walk to fetch the actual sub-step content.
      - undetectable_migration: the sidebar exposed no type_hint for this
        step, so a same-id legacy->scorm swap cannot be ruled out here;
        the caller surfaces this as a caveat instead of a re-queue.

    Returns (type_mismatch_step_ids, scorm_shell_step_ids, undetectable_migration).
    """
```

Rule of thumb: if you had to think for more than a few seconds about why a value goes into one bucket instead of another while writing the function, write that reasoning into the docstring — the next reader will have to do the same thinking without it otherwise.

---

## 3b. Name Other Code Exactly — Never Paraphrase It

When a comment or docstring refers to anything that exists elsewhere in the system — a table, a column, an enum member, a config key, a function, a module, a status value — spell it with its exact identifier. A periphrase forces the reader to guess which symbol is meant and makes the reference ungreppable, so it silently rots when the real name changes.

**Bad — describes the artifact instead of naming it:**
```python
"""Reads the two Bronze artifacts a SCORM wrapper step produces — the package
`data.js` course JSON and the `{uuid: html}` fragment envelope.
"""
```
Nothing here tells the reader the rows live in `raw_responses`, nor which `response_type` values to query. Grepping `scorm_course_json` does not find this file.

**Good — exact table, column, and enum values, description alongside:**
```python
"""Reads the two `raw_responses` rows a SCORM wrapper step produces:
`response_type='scorm_course_json'` (the package's data.js) and
`response_type='scorm_fragments_json'` (a `{uuid: html}` envelope).
"""
```

Applies equally to: DB objects (`raw_responses`, `steps.superseded_at`), enum members (`StepType.SCORM`, not "the scorm type"), functions (`detect_images()`, not "the image detector"), and status literals (`extraction_status='pending'`, not "marked as not yet done"). Keep the prose gloss — the rule adds the identifier, it does not replace the explanation.

---

## 3c. A Test Docstring Must State What Breakage the Test Catches — Briefly

A test's assertions already show *what* is checked. The docstring answers what they cannot: **what real defect does a failure point to?** Without it, a red test tells the reader only that a number disagreed — not whether they are looking at data corruption, a parser regression, or a stale expectation.

**Budget: a summary line plus one or two short sentences of why. That is the whole docstring.** A test docstring longer than about six lines has stopped documenting and started narrating; cut it. Exceptions (a filtered row class, an exempted category) get one clause, or a pointer to the test that covers them — not a paragraph.

Three things, compressed, not three paragraphs:

1. **Summary line = the defect the test detects**, not the condition it evaluates. `"""Catch quiz steps whose questions were parsed from an unsaved page."""`, never `"""Quiz steps have a quiz_html row."""`. A reader scanning `pytest -v` should know what is broken from the name and summary alone.
2. **The cause** — what upstream failure produces a violation, naming the function or column that writes the value.
3. **The consequence** — what silently breaks downstream. A violation with no consequence does not deserve a test.

Fold 2 and 3 into one or two sentences. If they will not fit, the test is probably asserting more than one thing.

**Bad — restates the assertion:**
```python
def test_total_steps_matches_actual_count(db):
    """total_steps equals the number of live step rows."""
```
True, and useless: the reader still cannot tell whether a mismatch means missing content or a stale counter.

**Bad — right content, three times too long:**
```python
def test_total_steps_matches_actual_count(db):
    """Catch trainings marked complete whose step extraction never finished.

    `trainings.total_steps` is written twice by `TrainingWalker`: first as the
    catalog's `stepsCount` estimate before the walk, then overwritten with
    `count_live_steps()` once every step has been visited. So a training with
    `extraction_status='complete'` whose stored `total_steps` disagrees with
    its live `steps` rows means that second write never ran — the walk died
    mid-training, or rows were archived afterwards without a recount — and the
    training is silently short on content while advertising itself as fully
    extracted.
    """
```
Every sentence is true; the mechanism recap belongs in the walker, not in each test that depends on it.

**Good — same information, two sentences:**
```python
def test_total_steps_matches_actual_count(db):
    """Catch trainings marked complete whose walk died mid-extraction.

    A mismatch means the walker's closing `count_live_steps()` write never ran,
    so `total_steps` still holds the pre-walk catalog estimate and the training
    claims content it does not have.
    """
```

---

## 4. When NOT to Comment

- **Type hints replace type comments.** `def f(x: int) -> str:` — never `# x is an int`.
- **Good names replace what-comments.** Rename `d` to `days_since_last_sync`; no comment needed.
- **Version control replaces history.** Never `# Changed by Jean on 2025-03-12`. `git blame` is authoritative.
- **Tests replace example comments** for anything non-trivial.
- **No internal-doc references in source.** Never cite `TO_DO.md`, `DONE.md`, `CURRENT_TASK.md`, phase numbers (`Phase 31.3`), internal task IDs, or internal planning documentation paths (`docs-codex/...`, `docs-claude/...`, `docs-ai/...`). These are private process artefacts; comments must stand on their own for an external reader. If the doc has durable context worth surfacing, restate the *rule* in the comment — not the pointer. This includes deferred-work notes: `# do not unify without a dedicated TO_DO item (different payload shapes)` is a violation — write `# different payload shapes; do not unify without re-verifying both call sites` instead (states the actual constraint, no tracker reference).
- **No incident-narrative breadcrumbs.** Drop dated post-mortem references (`Added 2026-05-15 after the X incident`, `since the May 2026 regression`). State the invariant being protected, not the event that motivated it. Public bug-tracker URLs are fine; internal incident names are not.
- **No line-number cross-references.** `# see L36 below`, `read at L68` rot silently on any edit. Use a symbol name or restructure so proximity makes the link obvious.

---

## 5. Anti-Patterns — Delete on Sight

| Anti-pattern | Example | Action |
|---|---|---|
| **Commented-out code** | `# result = old_fetch(...)` | Delete. Git remembers. |
| **Bare TODO** | `# TODO: fix this` | Require `# TODO(owner, TICKET-123, 2026-06-01):` or delete. |
| **Redundant docstring** | `def get_user(): """Gets the user."""` | Delete or rewrite. |
| **Test docstring restating the assertion** | `"""total_steps equals the number of live step rows."""` | Rewrite as defect + cause + consequence, 1-2 sentences (§3c). |
| **Test docstring narrating the mechanism** | A paragraph recapping how the code under test works | Cut to the defect a failure points to; the mechanism belongs where it is implemented. |
| **Section banners** | `# ========== HELPERS ==========` | Delete in files under ~300 lines. |
| **Numbered step comments** | `# 1. Fetch data`, `# 2. Filter` | Delete; extract named helpers if steps are long. |
| **Legacy diff comments** | `# --- NEW KEY LOGIC ---`, `# --- THIS CHECK PREVENTS THE ERROR ---` | Delete. |
| **Stale/misleading comments** | Docstring says "releases the slot" but that was moved to the caller | Fix or delete. Worse than no comment. |
| **Closed-hypothesis DIAG probes** | `[DIAG H3]` when H3 is in `DONE.md` | Delete or de-prefix to plain `INFO`/`DEBUG`. |
| **Internal-doc references** | `(TO_DO Phase 31.3)`, `see docs-codex/.../incidents/`, `CURRENT_TASK §4` | Delete the pointer; if the rule matters, state it inline. |
| **Incident-narrative breadcrumbs** | `Added 2026-05-15 after the mass-deletion incident`, `caused by the cognite-sdk 8.0.7 regression` | Replace with the invariant being protected (e.g. "guards against upstream truncation cascading into mass deletes"). |
| **Dated breadcrumbs** | `since 2025`, `as of Q1 2026` | Delete. Dates rot; git blame is authoritative. |
| **Line-number cross-refs** | `see L36 below`, `read at L68` | Rewrite around symbol names. |

**The DIAG probe rule (AIP-specific):** `[DIAG Hn]` log lines are investigation scaffolding. Once the hypothesis is confirmed or rejected and recorded in `DONE.md`, the `[DIAG Hn]` prefix must be removed or the entire line deleted. Leaving a closed-hypothesis probe in production code is a stale comment that misleads future readers about what is still being investigated. If the telemetry is genuinely useful post-investigation, reshape it to a plain `INFO`/`DEBUG` log without the hypothesis label.

---

## 6. When a Comment IS Warranted

A comment earns its keep when it captures knowledge that cannot be expressed in the code itself:

- **Non-obvious business rule or domain constraint** — regulatory cutoff, contract clause, ISO requirement.
- **Library bug workaround** — always link the upstream issue: `# Workaround for cognite-sdk#892; remove after >=7.50.`
- **Performance-motivated non-idiomatic code** — explain the benchmark that justified the ugliness.
- **Reference to a spec, RFC, or ticket** — links that would take a reader minutes to find otherwise.
- **Known pitfall** — "Do not reorder: CDF rejects events whose endTime precedes startTime silently."
- **Non-obvious algorithm invariant** — e.g. "Acquire ALL slots before submitting; satisfies 'both or nothing' on cancel."

---

## 7. Cognite Function `handler.py` — Required Docstring Fields

Every Cognite Function's `handler.py` module and `handle()` function together must answer what an on-call engineer needs at 02:00:

**Module-level docstring:**
- One-line summary of what the Function does and which CDF resources it touches.

**`handle()` docstring:**
```python
def handle(client: CogniteClient, data: dict) -> dict:
    """<Imperative one-line summary>.

    Trigger: <schedule / webhook / manual — e.g. "wf_005 workflow, every 30 min">.

    Payload (``data`` dict):
        Required keys and types. Example::

            {"file_ids": ["space_abc123"], "log_level": "DEBUG"}

    CDF side effects:
        - Creates / updates: <list resources, data sets, spaces>
        - Reads: <list tracker tables, views>

    Idempotency: <"Re-running with the same payload is safe; external_id dedup key is X."
                  OR "Not idempotent — duplicate runs will create duplicate edges.">

    Failure modes:
        - <What raises vs. what is swallowed + logged>
        - <Retry behaviour if scheduled>

    Returns:
        dict: <shape of return dict, who consumes it — or "None / not consumed">
    """
```

You do not need to document every field exhaustively — focus on whatever is non-obvious to a new team member reading the code for the first time.

---

## 8. Pre-Commit Checklist

Ask these questions of every comment before committing:

1. Does it explain **why**, or does it just restate the code?
2. Would a better **name** or **type hint** make this comment unnecessary?
3. Is it still **true** after my edit — or is it now a lie?
4. If it is a `TODO`, does it carry an **owner, ticket, and date**?
5. Is it **commented-out code** I should delete and trust to git?
6. For a `[DIAG Hn]` probe — is this hypothesis still **open** in `TO_DO.md`? If not, delete or de-prefix.
7. For a public function — does the docstring cover **purpose, args, returns, raises, side effects** without just restating the signature?
8. For a **test** — does the docstring name the **defect a failure points to** in a summary line plus **at most two sentences**, rather than restating the assertion or recapping the mechanism?
9. Could an **external contributor** with no access to internal planning documentation, chat, or tickets understand this comment? If it references `TO_DO.md`, a phase number, an incident date, or a `docs-codex/`, `docs-claude/`, or `docs-ai/` path — rewrite to state the rule directly.
10. Is every block comment **≤ 3 lines**, one fact per sentence, every term either plain or glossed (§1a)? Would somebody with zero context understand every word?

---

## Cross-References

- **`logging-standards`** — which log level to use and how to format log lines; where `[DIAG Hn]` probes belong.
- **`debug-function`** — how to introduce and run `[DIAG Hn]` probes during a live investigation.
- **Project instructions (`AGENTS.md` / `CLAUDE.md`)** — “Diagnose the Real Function”: instrument the actual handler, never a replica.
- **Project instructions (`AGENTS.md` / `CLAUDE.md`)** — “No Silent Logic Decisions”: every choice the code makes on behalf of the user must be visible in both a code comment AND a runtime log.
