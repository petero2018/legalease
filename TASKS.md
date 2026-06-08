# Assessment Tasks

---

## The Incident

Yesterday at 18:45 UTC, the CMS team deployed a scheduled update to the rankings API export.
Fivetran's 20:00 UTC sync loaded the new data. The 06:00 UTC dbt run failed.
By 07:15 UTC, the client products team escalated: the "Top Tier Firms" widget was showing
counts 15% lower than the previous day.

**What changed in the CMS export:**

|                    | Before                       | After                            |
|--------------------|------------------------------|----------------------------------|
| Ranking tier field | `ranking_tier` (integer)     | `tier_rank` (varchar)            |
| New field          | *(not present)*              | `listing_type` (varchar, nullable) |
| Post status casing | `'Publish'`                  | `'publish'`                      |

Fivetran added the new columns alongside the existing ones — it did not replace them.
The raw table now contains rows from both schema versions simultaneously.
`ranking_tier` still exists but is empty for all post-migration rows.

The submissions table has its own independent set of issues — find them.

---

## Task 1 — Staging: Rankings (30 min)

Build `stg__rankings` with a companion YAML.

The raw `raw_rankings` table contains rows from both schema versions coexisting in the same
table. Your model must handle both without data loss or silent failures.

Requirements:
1. Produce a single unified `ranking_tier` integer column from the two source columns
2. Deduplicate on `ranking_id`, keeping the row with the latest `modified_ts`
3. Filter out rows where `firm_ref` is invalid — define what "invalid" means and document it
4. Standardise `post_status` to a consistent casing
5. Cast all columns to appropriate types, handling failures gracefully

YAML requirements:
- At least 8 data quality tests — mix of generic dbt tests, `dbt_expectations`, and at least
  one Elementary anomaly test
- Every `severity: error` or `severity: warn` must have a comment explaining the business
  rationale — severity without justification will not be accepted
- Column descriptions for all columns

---

## Task 2 — Staging: Submissions (20 min)

Build `stg__submissions` with a companion YAML.

The submissions data has its own quality issues. There is no list of them — finding them
is part of the task.

Requirements:
1. Handle deduplication at the correct grain
2. Appropriate type casting and null handling
3. At least 5 data quality tests with justified severity levels

---

## Task 3 — Intermediate: Rankings (25 min)

Build `int__rankings` with a companion YAML.

Requirements:
1. Join to staged firms and practice areas to resolve display names
2. Derive `ranking_decision_status` using this logic:
   - `firm recommended` + tier 0 → `'not ranked'`
   - `firm to watch` + tier 0 AND `post_status != 'publish'` → `'not ranked'`
   - All other cases → `'ranked'`
3. Produce a clean deduplicated output — declare the grain explicitly in a comment at the
   top of the file
4. Column ordering: edition identifiers → geography → entity identifiers → ranking
   attributes → status fields → timestamps

---

## Task 4 — Mart: Firm Rankings (20 min)

Build `fct_firm_rankings` with a companion YAML.

Requirements:
1. Source from `int__rankings`
2. Add derived flags relevant to the "Top Tier Firms" client product — you decide which
   ones, justify them
3. Add a row-count floor test — justify the minimum in a comment
4. Add an Elementary `volume_anomalies` test

---

## Task 5 — Monitoring, Freshness & Schema Drift (35 min)

This is the most heavily weighted task.

**5A — Source freshness**

Configure freshness monitoring on `raw_rankings` and `raw_submissions`. Thresholds must
reflect the actual SLA: marts ready by 07:00 UTC, Fivetran syncs at 20:00 and 02:00 UTC.

**5B — Volume anomaly detection**

Configure volume monitoring on `stg__rankings` and `fct_firm_rankings`. The "Top Tier Firms"
widget is the downstream consumer — size your thresholds to protect it.

**5C — Schema drift detection**

Add a test to `stg__rankings` that fires when source columns are added, removed, renamed,
or type-changed. Choose your tool and justify it in `ANSWERS.md`.

**5D — Written response in `ANSWERS.md`**

Answer all four (max 400 words total):

1. **Downstream dependency alerting** — When schema drift is detected on `stg__rankings`,
   how do you surface which downstream models, dashboards, or client products are affected?
   Describe the mechanism.

2. **Alerting tiers** — Design a two-tier scheme:
   - **P1** (page on-call, 24/7): list the specific conditions with examples from this dataset
   - **P2** (Slack/Teams, business hours): list the specific conditions
   Which tool routes each tier? Justify your choice.

3. **Stale data runbook** — It is 07:30 UTC. `fct_firm_rankings` has not been updated since
   yesterday. Write a 5-step runbook for an on-call engineer who has warehouse access and
   can run dbt but has never seen this codebase.

4. **Pre-ingestion quality gates** — The current setup detects issues after the dbt run.
   Describe one architectural change that would catch schema drift or volume anomalies
   before rows reach the staging model.

---

## Task 6 — Incident Diagnosis (15 min)

This morning's dbt run produced:

```
Failure in test unique_stg__rankings_ranking_id
  Got 847 results, configured to fail if != 0

Failure in test not_null_stg__rankings_firm_ref
  Got 12 results, configured to fail if != 0

Warning in test accepted_values_stg__rankings_post_status__publish__draft__pending__trash
  Got 34 results, configured to warn if != 0
```

Fivetran sync log from last night:

```
[2025-01-14 20:11:43] RANKINGS: incremental sync completed
[2025-01-14 20:11:43] RANKINGS: 12,847 rows synced (+847 vs previous sync)
[2025-01-14 20:11:43] RANKINGS: sync cursor: updated_at > 2025-01-10 08:00:00
```

In `ANSWERS.md`, answer (max 400 words):

1. Root cause of each of the three test results — use the Fivetran log as evidence
2. Steps to restore the 07:00 UTC SLA within 30 minutes
3. One architectural change that makes this class of incident self-healing

---

## Evaluation Priorities

1. **Tests catch real failures** — severity is justified, not arbitrary
2. **Schema drift is handled in code and tested** — not just mentioned in prose
3. **Monitoring config is runnable** — `edr monitor` (or equivalent) produces output
4. **Operational thinking** — runbooks work for an on-call engineer at 07:30 UTC
5. **SQL grain discipline** — no accidental fan-out, grain declared explicitly
