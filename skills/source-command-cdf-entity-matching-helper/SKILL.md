---
name: "source-command-cdf-entity-matching-helper"
description: "Migrated source command `cdf-entity-matching-helper`"
---

# source-command-cdf-entity-matching-helper

Use this skill when the user asks to run the migrated source command `cdf-entity-matching-helper`.

## Command Template

# CDF Entity-Matching Helper — Panorama-PDNA

Apply these standards every time you author or modify a Cognite Function helper script that calls the CDF Entity Matching API and writes results to a `GoldenTags.*` RAW table consumed downstream by a `tr_timeseries_*.Transformation.sql`.

**Triggers on:**
- any `fn_*_entityMatching*.py` file
- `convert_matches_to_dataframe` or any function that writes a match-results DataFrame to CDF RAW
- adding a new `usecase` dispatch in a workstream `handler.py`
- diagnosing "too many rows mapped to a global fallback asset" in a GoldenTags result table

---

## 1. Unmatched-Source Contract — No Hardcoded Global Fallback

**Never** inject a hardcoded global asset or product (`'ADNOC GAS'`, `'UNKNOWN'`, a root-node externalId, etc.) for sources that the EM API did not match. Unmatched rows must emit explicit Python `None` for all target fields.

**Why:** SQL `CASE WHEN am.externalId IS NOT NULL` downstream relies on the distinction between "matched" and "not matched". A hardcoded fallback collapses that signal — every row appears matched, the `ELSE null` branch is never taken, and broken `node_reference` calls are emitted for every unmatched source.

```python
MATCH_SCORE_FLOOR = 0.5

for item in matches['items']:
    m = item['matches'][0] if item['matches'] else None
    score = m['score'] if m else None

    if m is None or score < MATCH_SCORE_FLOOR:
        data.append({
            'source_id':          item['source']['id'],
            'source_name':        item['source']['name'],
            'match_score':        score,
            'target_id':          None,
            'target_name':        None,
            'target_external_id': None,
            'target_space':       None,
        })
    else:
        data.append({
            'source_id':          item['source']['id'],
            'source_name':        item['source']['name'],
            'match_score':        score,
            'target_id':          m['target']['id'],
            'target_name':        m['target']['name'],
            'target_external_id': m['target']['external_id'],
            'target_space':       m['target']['space'],
        })
```

---

## 2. Score-Floor Contract

Project default: `MATCH_SCORE_FLOOR = 0.5`. Define it as a module-level constant — not inline — so it is easy to audit and adjust per usecase.

Treat any match with `score < MATCH_SCORE_FLOOR` as unmatched (apply section-1 contract). Without a floor the EM API returns 0.1–0.2-similarity "matches" by default; every source row is "matched", the result table looks correct, and only downstream FDM or Grafana queries reveal the over-matching.

If a specific usecase warrants a different floor (e.g. stricter asset matching where plant names are short and collision risk is high), define a separate constant with a comment explaining the deviation.

---

## 3. Result-Table Schema — Downstream Contract

The GoldenTags result table must contain exactly these columns so the downstream SQL `LEFT JOIN` is stable across runs:

| Column | Type | Notes |
|--------|------|-------|
| `source_id` | int | Internal CDF asset/event id of the source |
| `source_name` | str | Original display name before any cleaning |
| `match_score` | float / None | None for unmatched rows |
| `target_id` | int / None | Internal CDF id of the matched target |
| `target_name` | str / None | Display name of the matched target |
| `target_external_id` | str / None | Joins to `node_reference()` arg in SQL |
| `target_space` | str / None | Joins to `node_reference()` arg in SQL |

Optional debug columns (recommended, never required by SQL):

| Column | Notes |
|--------|-------|
| `*_clean` | The cleaned form of the source name that was sent to the EM API (e.g. `product_clean`, `asset_clean`). Persist this to make post-run debugging possible without re-running the cleaning logic. |

**Empty result tables must be created with this schema.** If the EM API returns zero results (network timeout, no candidates), write an empty DataFrame with these columns rather than skipping the write. Downstream SQL `LEFT JOIN`s rely on the table existing; a missing table causes a transformation failure that is harder to diagnose than an empty join.
