# LegalRank — Senior Data Engineer Technical Assessment

**Time:** 2–3 hours | **Submission:** GitHub repo link or zip file

---

## About LegalRank

LegalRank is a legal intelligence platform that publishes annual rankings of law firms
across 50+ countries. The data team feeds two consumers:

- **Editorial** — researchers and editors; mart tables must be ready by **07:00 UTC** daily
- **Client products** — a live "Top Tier Firms" widget served via API; any count regression
  is a **P1 incident**

---

## Our Production Stack

| Layer       | Technology                                    |
|-------------|-----------------------------------------------|
| Source      | WordPress CMS + Postgres submissions portal   |
| Ingestion   | Fivetran → Snowflake (raw schema)             |
| Transform   | dbt Core                                      |
| Orchestrate | Dagster Cloud                                 |
| Monitor     | Elementary                                    |
| Alerts      | Slack / Microsoft Teams                       |

---

## What You Have Been Given

Four CSV files in `data/` representing a snapshot of raw Snowflake tables:

| File | Description |
|------|-------------|
| `raw_firms.csv` | Firm master data — clean reference table |
| `raw_practice_areas.csv` | Practice area taxonomy — clean reference table |
| `raw_rankings.csv` | Rankings export from the CMS — contains deliberate issues |
| `raw_submissions.csv` | Submissions portal data — contains deliberate issues |

---

## Environment

Use whatever data warehouse and setup you are comfortable with — Snowflake trial,
Docker + Postgres, DuckDB, or anything else. Load the CSVs into a `raw` schema.

We use **dbt Core**, **Elementary**, and **Slack/Teams webhooks** in production.
We expect to see those (or justified alternatives) in your submission.

---

## What to Submit

```
Your dbt project (runnable: dbt run && dbt test should pass with zero errors)
ANSWERS.md   — written responses to Tasks 5 and 6
README.md    — your assumptions, trade-offs, what you'd add with more time
```


---


# How It Works

This project is a dbt Core assessment project packaged with Docker for repeatable local execution. The container installs Python, Poetry, dbt Snowflake, Elementary, and the dbt packages declared in `legalrank/packages.yml`.

## Runtime Flow

The `Dockerfile` builds an image from Python slim, copies the `legalrank` dbt project into `/app/legalrank`, installs the Poetry dependencies, and runs `dbt deps` so dbt packages are available in the image.

The `Makefile` is a thin wrapper around Docker. It passes environment variables from `.env`, starts the container, changes into `/app/legalrank`, and runs dbt with:

```bash
--profiles-dir . --target prod
```

The dbt profile is project-local at `legalrank/profiles.yml`. Snowflake credentials are read from environment variables.

## Environment Setup

Create a local `.env` file from the sample:

```bash
cp sample_dot_env.txt .env
```

Fill in:

```bash
SNOWFLAKE_ACCOUNT=
SNOWFLAKE_USER=
SNOWFLAKE_DATABASE=
SNOWFLAKE_PASSWORD=
```
Use the sample_dot_env.txt and save it as .env. .env is filtered out of version control via `.gitignore`.
In prod setup, this could be part of CI/CD read from a Vault or Secrects Manager and promote env vars to container.

`SLACK_WEBHOOK_URL` and `SLACK_WEBHOOK_CHANNEL` are optional and only needed if testing alert routing.

## Commands

Build the Docker image:

```bash
make docker-build
```

Check the dbt/Snowflake connection:

```bash
make dbt-debug
```

Run the full project:

```bash
make dbt-build
```

Useful alternatives:

```bash
make dbt-run      # run models
make dbt-test     # run tests
make dbt-deps     # refresh dbt packages
make docker-shell # open a shell in the container
```

## Monitoring

Elementary is installed both as a dbt package and as a Python dependency. The dbt project captures test results through the `on-run-end` hook in `legalrank/dbt_project.yml`. After dbt tests have run, `edr monitor` can read those results from the Elementary schema and produce monitoring output or route alerts.


---

## Assumptions, Trade-offs and Future Work

### Assumptions

- The assessment data is loaded via dbt seeds, but I treated the raw tables as if they were Fivetran-loaded Snowflake tables in production.
- The snapshot does not include a Fivetran ingestion timestamp such as `_fivetran_synced`, so source freshness uses `modified_ts` for rankings and `created_ts` for submissions as the closest available proxy.
- `ranking_id` is the grain for rankings. `stg__rankings`, `int__rankings`, and `fct__firm_rankings` preserve one row per `ranking_id`.
- A valid `firm_ref` is defined as `F` followed by four digits. Rows with missing or malformed firm references are excluded from rankings and submissions staging because they cannot be safely tied back to a firm.
- The Top Tier Firms widget is represented by rows where `is_ranked = true` and `is_top_tier = true`.

### Trade-offs

- I used `LEFT JOIN`s from rankings to firm and practice-area reference data in `int__rankings` to avoid silently dropping ranking records when reference data lags behind. Missing display attributes should be monitored rather than hidden through an inner join.
- Schema drift is checked at the `raw_rankings` source with an Elementary baseline test, not only on `stg__rankings`, because staging output can hide source changes through casting or column selection.
- Invalid source rows are filtered in staging rather than surfaced in separate reject tables. For this assessment that keeps the marts clean; in production I would preserve rejected records for investigation.
- Elementary anomaly tests need historical runs before they become fully useful, so hard row-count tests are also included for immediate protection.

### With More Time

- Add dbt exposures for the Top Tier Firms widget and any dashboards, with owners and alert routing metadata.
- Add reject/quarantine models for invalid `firm_ref`, bad email addresses, and unparseable tier values.
- Add relationships tests from staged firm and practice-area keys to their reference tables where the business rule requires a resolved lookup.
- Use `_fivetran_synced` or another ingestion timestamp for freshness once available.
- Add CI commands that run `dbt parse`, `dbt build`, and `edr monitor` from the Docker image.

#### Production Environment and CI/CD

This assessment uses a single dbt target for simplicity. In production I would separate development and production environments properly:

- separate Snowflake databases/schemas for dev and prod, for example `LEGALRANK_DEV` and `LEGALRANK_PROD`
- separate dbt targets in `profiles.yml`, with credentials and roles managed by CI/CD secrets rather than local `.env` files
- least-privilege Snowflake roles instead of the broad assessment role
- isolated Elementary schemas per environment, so dev test history does not pollute production monitoring
- separate alert routing: dev failures go to an engineering Slack/Teams channel, while production P1 failures can route to PagerDuty

CI/CD would run against both environments with different gates:

- On pull requests: run `dbt parse`, `dbt deps`, targeted `dbt build --select state:modified+`, and unit/data tests against a dev schema.
- On merge to main: deploy to production and run the scheduled production job through the orchestrator.
- Production runs would execute `dbt source freshness`, `dbt build`, and `edr monitor`, with failures routed according to the P1/P2 scheme.
- Secrets such as Snowflake credentials and Slack/Teams/PagerDuty webhooks would come from a vault or CI secret manager, not from checked-in files.
- Artifacts such as `manifest.json`, `run_results.json`, and Elementary test results would be retained so alerts can include lineage and downstream impact.