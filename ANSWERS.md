# Task 5 - Monitoring, Freshness & Schema Drift

**5C - schema drift tool choice.** I used Elementary because it is already part of the project, writes dbt test results into the warehouse, and is what `edr monitor` reads for alerting. The main check is `schema_changes_from_baseline` on `raw_rankings`, with `fail_on_added: true` and `enforce_types: true`. That catches added, removed, renamed, and type-changed source columns. I also kept `schema_changes` on `stg__rankings` as a second contract check on the staging output.

**1. Downstream dependency alerting.** A useful drift alert should not just say that a test failed; it should say what is now at risk. Elementary records the failing dbt test, then `edr monitor` sends the alert. I would use the dbt manifest to walk downstream from `source.raw.raw_rankings` and `stg__rankings`, then attach `int__rankings`, `fct__firm_rankings`, exposures or dashboards, and the Top Tier Firms owner. Keeping ownership in dbt exposures or model `meta` makes the alert actionable, not just technical.

**2. Alerting tiers.** P1 alerts should wake someone up only when client-facing data is at risk. PagerDuty handles the 24/7 page, with Elementary/dbt detecting the failure and Dagster or CI forwarding it. P1 examples are schema drift on `raw_rankings` or `stg__rankings`, stale source data near the 07:00 UTC SLA, `fct__firm_rankings` below its row-count floor, a Top Tier Firms volume drop over 10%, zero-row outputs, duplicate `ranking_id`, or null `firm_ref` after staging. P2 alerts go to Slack or Teams during business hours via `edr monitor`: unexpected `post_status`, missing optional metadata such as `edition_id`, staging volume warnings, and ranking tier distribution anomalies.

**3. Stale data runbook at 07:30 UTC.**
1. Run `dbt source freshness --select source:raw.raw_rankings source:raw.raw_submissions`.
2. Check Fivetran and Dagster for a missed 02:00 sync or failed 06:00 dbt run.
3. If raw data is fresh, run `dbt build --select stg__rankings+ fct__firm_rankings`.
4. If tests fail, inspect schema drift, null firm refs, duplicates, and volume floor failures; quarantine bad records if needed.
5. Rerun `dbt build`, run `edr monitor`, confirm `fct__firm_rankings` refreshed, and notify stakeholders.

**4. Pre-ingestion quality gate.** I would land each Fivetran sync into quarantine tables first, compare columns, types, and row volumes with the previous successful sync, and only then promote the batch into raw. That catches drift or abnormal volume before dbt staging runs. The same idea could be implemented with a streaming or Spark-based contract check if validation needs to happen in transit.

# Task 6 - Incident Diagnosis

**1. Root causes.** The Fivetran log points to an incremental replay, not a normal small sync: `12,847 rows synced (+847)` with cursor `updated_at > 2025-01-10 08:00:00`. The `unique_stg__rankings_ranking_id` failure means those 847 extra rows introduced multiple versions of the same `ranking_id`, and staging was not keeping only the latest record. The `not_null_stg__rankings_firm_ref` failure means 12 replayed records had missing or malformed firm references; those rows should be rejected or quarantined before the staging grain is trusted. The `post_status` warning is from CMS value drift, especially casing such as `Publish` versus `publish`, or other unexpected workflow values that were not normalised before testing.

**2. Restore the 07:00 SLA within 30 minutes.**
1. Pause downstream publication of `fct__firm_rankings` and tell stakeholders rankings are being refreshed.
2. Patch `stg__rankings` to coalesce `ranking_tier` and `tier_rank`, lower-case `post_status`, filter invalid `firm_ref`, and deduplicate with `row_number()` by `ranking_id`, ordered by latest `modified_ts`.
3. Run `dbt build --select stg__rankings+ fct__firm_rankings`.
4. If only non-blocking accepted-value warnings remain, continue; if uniqueness or null failures remain, inspect samples and quarantine bad records.
5. Run `edr monitor`, compare Top Tier Firms counts with yesterday, then re-enable publication.

**3. Self-healing change.** Land Fivetran increments into versioned raw history and expose a current-record view keyed by `ranking_id`. That view keeps the latest record, maps known aliases such as `tier_rank` to `ranking_tier`, normalises status casing, and quarantines invalid firm refs. dbt then reads a stable contract instead of raw replay output.
