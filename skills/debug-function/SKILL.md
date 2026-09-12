---
name: debug-function
description: |
  Use when debugging a Cognite Function deployed via Cognite Toolkit —
  diagnosing wrong output, runtime crashes, OOM kills, or forming hypotheses
  about handler/core failures. TRIGGER on: user asks to debug/diagnose/
  investigate a Cognite Function; TypeError/ValueError/OOM appears in function
  logs; user considers writing a side-car script that re-implements function
  logic (anti-pattern this skill exists to prevent). Covers: hypothesis-first
  instrumentation inside the real handler.py / core.py, local execution via
  `poetry run cdf run function`, function-level requirements.txt vs repo
  pyproject.toml dep-source distinction, [MEM] probe forensics for OOM bugs,
  and the two-run rule (single-metric reproduction vs cold-path acceptance).
---

# Debug a Cognite Function — Diagnose, Don't Replicate

Use this skill when the user asks to debug, diagnose, investigate, or form hypotheses about a Cognite Function deployed via the Cognite Toolkit, or reports one producing wrong output or failing in CDF. Also use proactively when any debugging approach would otherwise involve writing a script that re-implements function logic.

---

## The golden rule

**Instrument the real function. Never replicate it.**

A replica script drifts from the real code the moment anyone edits `handler.py`. Every bug you "fix" in the replica may not exist in production, and every bug you miss is hidden by the divergence. Add a `logging` call to the real file; run the real file.

---

## Workflow

### 1. Read before touching

Locate the function source under:
```
Asset%20Information%20Platform/motoroilhellas/modules/.../functions/<function_name>/
```
Read `handler.py` **end-to-end** before proposing any change. Also read `requirements.txt`.

### 2. State the hypothesis

Before writing a single line of code, state one sentence:

> *"I suspect the failure is at `<stage>` because `<evidence>`."*

The hypothesis is the gating condition for logging. No hypothesis → no logging added.

### 3. Refactor only if it blocks isolation

If `handler.py` mixes I/O and logic so tightly you cannot isolate the hypothesised point, split first:

```
handler.py     # thin adapter: parse args → call core → return result
core.py        # pure logic — no CDF calls, unit-testable
cdf_io.py      # all CDF reads/writes
```

Add this as a TO_DO.md item and wait for confirmation before touching source. Don't refactor opportunistically — only to unblock the current hypothesis.

### 4. Instrument surgically

Add `logging` **only at the point(s) your hypothesis is about**. If you suspect the upsert payload is wrong, log the payload going into `upsert_metrics`. Don't also log read/compute unless those are part of the hypothesis.

Log the **data shape relevant to the question** — not breadcrumbs:

```python
import logging, json
log = logging.getLogger(__name__)

# Good — answers the hypothesis ("is the payload malformed?")
log.info("fn_026.upsert_payload | n=%d | sample=%s",
         len(result), json.dumps(result[:2], default=str))

# Bad — tells us nothing specific
log.info("fn_026 — entering upsert step")
```

Prefix convention: `fn_<id>.<event> | key=value` — greppable in Fusion UI and local output.

### 5. Run locally under Poetry via the Run plugin

> **Dep source — CRITICAL:** Each function's `requirements.txt` governs its venv — **not** the repo's `pyproject.toml`. The Toolkit Run plugin builds each function's venv from its own `requirements.txt`. Versions can diverge significantly from the repo dev environment. Before diagnosing any SDK-level behavior, always read the function's own:
> `motoroilhellas/modules/.../functions/<function_name>/requirements.txt`
>
> Library versions inside a function can be completely different from what `pyproject.toml` declares — never assume they match.

```bash
cd "Asset%20Information%20Platform"
poetry run cdf run function <external_id> --payload payload.json
```

- `payload.json` lives at `other_scripts/JeanArnaud/debug_<function_name>/payload.json` — never inside the function folder.
- The Run plugin uses the `function_local_venvs/<function_name>/` venv (auto-managed — never edit it manually).
- `--payload` is a JSON object matching the `data` argument your handler expects.

### 5b. Memory-bound OOM — acceptance gate and forensic strategy

**(a) The two-run distinction**
Reproduction and acceptance are not the same run for memory bugs:

- *Reproduction run:* single-metric / minimal payload
  (e.g. `{"metrics":["metric_5"]}`) is the correct scope — it isolates the
  failing step and gives the fastest iteration cycle.
- *Acceptance run:* the full cold-path orchestrator payload (e.g. `{}` which
  dispatches all 6 metrics for fn_029). Single-metric green ≠ fix. Every
  memory-fix PR must include a full cold-path log snippet as evidence. This
  rule exists because MEM.7 and MEM.11 both passed single-metric dev runs
  and then OOMed on the prod cold-path.

**(b) Reading the `[MEM]` trail**
After a cold-path run, grep `[MEM].*rss=` and look for:

- A metric whose `after compute` RSS is much larger than its `before compute`
  (that metric owns the retention).
- Any `(X freed)` line where RSS does not drop (hidden reference — grep for
  `shared_context[key]`, closure captures, and caller-side aliasing).
- The gap between inner `exit` and outer `after compute` RSS
  (dispatcher-level allocation from staging writes, etc.).

**(c) Hypothesis template for OOM**
In addition to the standard *"I suspect the failure is at `<stage>` because
`<evidence>`"*, memory hypotheses must specify:
*(i)* which `[MEM]` probe bracket shows the spike,
*(ii)* which variable is the suspected owner (by name + approximate size),
*(iii)* whether the variable is cache-written (requiring
`function-memory-hygiene` review) or merely over-retained (requiring a
`del` + visible-release log).

**(d) Cross-references**
- If installed, local `logging-standards` guidance § `[MEM] probes` — probe shape,
  mandatory placement, and visible-release convention.
- If installed, local `function-memory-hygiene` guidance — cache-design rules (R1–R4)
  including owner selection and generator-safety audit.

### 6. Exploratory scripts — import, never copy

If interactive exploration is needed outside the function, write a script under `other_scripts/JeanArnaud/` that imports the function's own modules:

```python
import sys
sys.path.insert(0, "Asset%20Information%20Platform/motoroilhellas/modules/path/to/functions/<function_name>")
from core import compute_scores
from cdf_io import read_inspections
```

Run it the same way: `poetry run python other_scripts/JeanArnaud/debug_<function_name>.py`. Never paste logic.

### 7. Iterate

Run → read log → confirm or reject hypothesis → either fix or state a new hypothesis → repeat.

Every resolved hypothesis gets one line in the project's durable decision record. That's the durable artifact of the debug session.

### 8. Cleanup gate before closing

- **Remove** log lines that were hypothesis-scoped only (answered the question; no ongoing ops value).
- **Keep** log lines with lasting value: outcome summaries, counts at system boundaries, error branches.
- **Delete** the debug script unless it's genuinely reusable (then give it a proper name in `other_scripts/JeanArnaud/`).

---

## Reusable snippets

**Minimal logging pattern**
```python
import logging, json
log = logging.getLogger(__name__)

log.info("fn_<id>.<event> | n=%d | sample=%s", len(data), json.dumps(data[:2], default=str))
log.warning("fn_<id>.unexpected_state | reason=%s | value=%r", reason, value)
```

**Payload template (`payload.json`)**
```json
{
  "window": {
    "start": "2024-01-01T00:00:00Z",
    "end":   "2024-01-31T23:59:59Z"
  }
}
```

**Run command**
```bash
cd "Asset%20Information%20Platform"
poetry run cdf run function <external_id> --payload other_scripts/JeanArnaud/debug_<function_name>/payload.json
```

**Minimal pytest for `core.py`** (only write this if the hypothesis warrants a regression test)
```python
# other_scripts/JeanArnaud/debug_<function_name>/test_core.py
import sys, pytest
sys.path.insert(0, "path/to/<function_name>")
from core import compute_scores

def test_compute_scores_empty():
    assert compute_scores([]) == []
```
Run: `poetry run pytest other_scripts/JeanArnaud/debug_<function_name>/test_core.py -v`
