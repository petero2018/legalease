# Task 5 — Monitoring, Freshness & Schema Drift

**5C — schema drift tool choice.** I used Elementary `schema_changes_from_baseline` on the `raw_rankings` source with `fail_on_added: true` and `enforce_types: true`, plus `schema_changes` on `stg__rankings` as a downstream contract check. The baseline source test is required because `stg__rankings` may hide source drift: a new raw column or type change can be cast away before the staging output schema changes.

**1. Downstream dependency alerting.** When schema drift is detected, the useful alert is not just “a test failed”; it should say what may break next. Elementary records the failing dbt test, and `edr monitor` sends the alert. I would use the dbt manifest to walk downstream from `source.raw.raw_rankings` / `stg__rankings` and attach the affected assets: `int__rankings`, `fct__firm_rankings`, any dbt exposures or dashboards, and the Top Tier Firms product owner. Keeping dashboard and product ownership in dbt exposures or model `meta` makes the alert actionable instead of just technical.

**2. Alerting tiers.** **2. Alerting tiers.** P1 alerts should wake someone up only when client-facing data is at risk. PagerDuty handles the 24/7 page, with Elementary/dbt detecting the failure and Dagster/CI forwarding it into the incident route. P1 examples here are schema drift on `raw_rankings` or `stg__rankings`, stale raw data close to the 07:00 UTC SLA, `fct__firm_rankings` dropping below its row-count floor, a Top Tier Firms volume drop over 10%, zero-row outputs, duplicate `ranking_id`, or null `firm_ref` after staging. P2 alerts go to Slack/Teams during business hours via `edr monitor`: unexpected but non-blocking values like new `post_status`, missing optional metadata such as `edition_id`, staging volume warnings, and ranking tier distribution anomalies.

**3. Stale data runbook at 07:30 UTC.**
1. Check source freshness: `dbt source freshness --select source:raw.raw_rankings source:raw.raw_submissions`.
2. Check Fivetran/Dagster for missed 02:00 sync or failed 06:00 dbt run.
3. If raw data is fresh, rerun the path: `dbt build --select stg__rankings+ fct__firm_rankings`.
4. If tests fail, inspect failures for schema drift, null firm refs, duplicates, or volume floor breach; apply the smallest safe fix or disable only non-critical warn tests.
5. Rerun `dbt build`, run `edr monitor`, confirm `fct__firm_rankings` updated and notify stakeholders.

**4. Pre-ingestion quality gate.** Add a contract validation step between Fivetran landing and the raw production schema: land each sync into quarantine tables, compare columns/types and row volumes against the previous successful sync, and promote to raw only if the contract passes. Failures page before dbt starts, preventing bad schema or anomalous volume from reaching staging.
Or look for an alternative tool that supports "on-the-fly" data validation or data contract enforcement during transit e.g. Spark.

# Task 6 — Incident Diagnosis

**1. Root causes.** The Fivetran log shows an incremental replay/backfill: `12,847 rows synced (+847)` with cursor `updated_at > 2025-01-10 08:00:00`, not only yesterday's changes. The `unique_stg__rankings_ranking_id` failure with 847 rows means the staging model did not deduplicate the new versions by `ranking_id`; the replay loaded multiple records for the same ranking, likely old and post-CMS-export versions. The `not_null_stg__rankings_firm_ref` failure with 12 rows means the sync included records with missing or invalid firm references; these should be rejected or quarantined before the staging grain is declared valid. The `post_status` warning with 34 rows is caused by the CMS export casing/value change: statuses such as `Publish` or other unexpected variants arrived and were not normalized before the accepted-values test.

**2. Restore the 07:00 SLA within 30 minutes.**
1. Pause downstream publication of `fct__firm_rankings` and notify stakeholders that rankings are being refreshed.
2. Patch `stg__rankings` to coalesce `ranking_tier`/`tier_rank`, lowercase `post_status`, filter invalid `firm_ref`, and `qualify row_number() over (partition by ranking_id order by modified_ts desc) = 1`.
3. Run `dbt build --select stg__rankings+ fct__firm_rankings`.
4. If only non-blocking accepted-value warnings remain, proceed; if uniqueness/null failures remain, inspect sample rows and quarantine the bad records.
5. Run `edr monitor`, validate Top Tier Firms row counts against yesterday, then re-enable publication.

**3. Self-healing change.** Land Fivetran increments into versioned raw history and expose a current-record view using the source cursor and `ranking_id` merge key. That view always keeps the latest record, normalizes known schema aliases (`tier_rank` → `ranking_tier`, status casing), and quarantines invalid firm refs. dbt then reads a stable contract instead of raw replay output.
