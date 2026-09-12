---
name: run-cdf-function-locally
description: >
  ⚠️ MANDATORY — TRIGGER BEFORE ANY `cdf run function` COMMAND IS WRITTEN.
  Activate on: "run fn_XXX", "run function", "run locally", "test the function",
  "execute locally", "verify the fix", "re-run", "backfill", "create a payload",
  "trigger the function", "fire the schedule", constructing a `cdf run` command,
  writing a Schedule YAML, or ANY `--payload` / `--data` flag usage attempt.
  This skill PREVENTS the two most common mistakes: using `--payload` (flag does
  not exist) and hitting the wrong CDF project because of a `.env` override.
  Must be read completely before any run command is written.
---

# Run a Cognite Function Locally — Complete Reference

---

## ❌ THERE IS NO `--payload` FLAG

```bash
# ❌ WRONG — flag does not exist in Toolkit CLI ≥0.6
poetry run cdf run function local fn_026 --payload payload.json
poetry run cdf run function local fn_026 --data '{"key": "value"}'

# ✅ CORRECT — schedule is the only data-injection mechanism
poetry run cdf run function local fn_026_moh_upsert_inspection_metric \
  --schedule schedule_fn_026_moh_upsert_inspection_metric_local \
  --env=moh-dev
```

`--payload`, `--data`, `--json` do not exist. **`--schedule <name>` is the
only way to pass data to a function.**

---

## ⚠️ `.env` OVERRIDES `--env` FOR CDF CREDENTIALS

`Asset%20Information%20Platform/.env` is loaded first and sets `CDF_PROJECT`,
`CLIENT_ID`, etc. These **override** the `--env` flag's auth — even if you pass
`--env=moh-dev`, if `.env` says `CDF_PROJECT="moh-prod"` you hit prod.

Before every run:

```bash
grep "CDF_PROJECT" "Asset%20Information%20Platform/.env"
# Must match the target env — moh-dev or moh-prod
```

Symptom of mismatch: 404 on RAW table / FDM node that exists in dev but not
prod (or vice-versa).

---

## Invocation triage

| Goal | Pattern |
|---|---|
| Recurring production run | Schedule YAML with live cron + `{{var}}` templating, deploy via `cdf deploy` |
| Manual-only / one-shot / local test | Schedule YAML with never-fires cron `'0 0 31 2 *'` + `cdf run function local --schedule` |
| Dynamic batch (N variants at runtime) | Python script that appends Schedule blocks to Schedule.yaml, runs, then cleans up — see `run_fn_014_backfill.py` pattern |
| Ephemeral debug run | Same as manual-only — create a never-firing debug schedule with `force_reprocess_all: false` |

---

## Full run sequence

```bash
# 1. Verify .env points to the right project
grep "CDF_PROJECT" "Asset%20Information%20Platform/.env"

# 2. Build — resolves all {{var}} from config.{env}.yaml
cd "Asset%20Information%20Platform"
poetry run cdf build --env=<env>

# 3. Run
poetry run cdf run function local <fn_external_id> \
  --schedule <schedule_name> \
  --env=<env>
```

Run from the directory containing `cdf.toml` (`Asset%20Information%20Platform/`).
Requires `[plugins] run = true` in `cdf.toml` (already enabled).

The function venv lives in
`motoroilhellas/function_local_venvs/<fn_external_id>/` — auto-managed. Never
edit it manually.

---

## Schedule YAML — rules (Toolkit ≥0.6)

Every function that needs local execution requires a schedule entry.

**Template** (copy `data:` from the corresponding `wf_XXX.WorkflowVersion.yaml`
task's `parameters.function.data:` block — do not hand-roll values):

```yaml
- name: schedule_<fn_external_id>_local
  functionExternalId: <fn_external_id>
  description: "Local-only manual trigger. Never fires in CDF."
  cronExpression: "0 0 31 2 *"      # Feb 31 — canonically unreachable
  data:
    # exact copy of the workflow task's data: block
    raw_db_inspection_classes: '{{raw_db_inspection_classes}}'
    raw_table_inspection_classes: '{{raw_table_inspection_classes}}'
  authentication:
    clientId: {{cicd_client_id}}
    clientSecret: {{cicd_client_secret}}
    tokenUri: {{cicd_token_uri}}
    cdfProjectName: {{cdf_project_name}}
    scopes: {{cicd_scopes}}
```

**Rules:**

1. **No `externalId:` field.** Toolkit identifies schedules by
   `functionExternalId + name`. Adding `externalId:` is ignored and misleading.
2. **Never-fires cron:** `'0 0 31 2 *'`. Older code uses `'0 0 31 * 1'` — do
   not propagate that form.
3. **Full 5-field `authentication:` block** — the 2-field form silently breaks
   on prod.
4. **Copy `data:` from workflow verbatim.** Never commit `payload*.json` files
   with hardcoded env-specific values — bypasses `{{var}}` resolution and drifts
   from the workflow spec.
5. **Backfill-only fields** go on top of the copied block
   (e.g. `backfill_mode: true`).

---

## Verification

```bash
# Confirm {{vars}} resolved — no placeholders remain
grep -A 5 "<schedule_name>" build/functions/*.yaml
```

| Log line | Meaning |
|---|---|
| `✓ 4/4 ... successfully executed code` | Clean exit |
| `✓ 3/4 ... successfully imported code` then crash | Runtime error — read the traceback |
| `404` on RAW / FDM | `.env` project mismatch |
| `KeyError` on data param | Missing key in schedule `data:` block |

Re-run the same command immediately after success — result must be idempotent.

---

## Related skills

- `debug-function` — Hypothesis-first instrumentation inside the real
  `handler.py`, `[MEM]` probe forensics, two-run OOM acceptance rule. Use when
  the function runs but produces wrong output.
