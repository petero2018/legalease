# Help — Elementary Setup

This file covers the infrastructure side of getting Elementary running.
**It does not cover the monitoring tasks themselves** — what to monitor, which tests
to write, and how to configure thresholds are all part of the assessment.

---

## What Elementary is

Elementary is a data observability package that plugs into dbt. It has two parts:

- **dbt package** — installs alongside your other dbt packages, adds test types
  (`schema_changes`, `volume_anomalies`, `freshness_anomalies`, etc.), and writes
  all test results to its own tables in your warehouse after every `dbt test` run
- **`edr` CLI** — reads those result tables and sends alerts (Slack, Teams, email, etc.)

---

## Step 1 — Install

```bash
pip install elementary-data[postgres]   # if using Docker + Postgres
pip install elementary-data[snowflake]  # if using Snowflake
```

Add to your `packages.yml`:

```yaml
packages:
  - package: elementary-data/elementary
    version: [">=0.14.0", "<1.0.0"]
```

Then:

```bash
cd your-dbt-project
dbt deps
```

---

## Step 2 — Add the results hook to dbt_project.yml

Elementary needs to capture test results after every `dbt test` run:

```yaml
on-run-end:
  - "{{ elementary.handle_tests_results() if execute }}"
```

---

## Step 3 — Set up the Elementary profile

Elementary needs its own profile entry in `~/.dbt/profiles.yml` pointing to a
schema where it can write its own tables:

```yaml
elementary:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      port: 5432
      user: legalrank
      password: <your-password>
      dbname: legalrank
      schema: elementary
      threads: 4
```

---

## Step 4 — Bootstrap (run once)

This creates Elementary's internal tables in the `elementary` schema:

```bash
dbt run --select elementary
```

---

## Step 5 — Run your models and tests as normal

```bash
dbt run
dbt test
```

Elementary silently captures all results in the background via the `on-run-end` hook.

---

## Step 6 — Run the monitor

```bash
# Terminal report only (no external alerting needed)
edr monitor

# With Slack alerts
edr monitor --slack-webhook https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# With Microsoft Teams alerts
edr monitor --teams-webhook https://your-org.webhook.office.com/...

# Specify profiles directory if not using ~/.dbt
edr monitor --profiles-dir . --profile elementary
```

---

## Slack webhook (if you want to test alerting end-to-end)

1. Go to your Slack workspace → **Apps** → search **Incoming Webhooks**
2. Click **Add to Slack**, choose a channel, copy the webhook URL
3. Pass it to `edr monitor --slack-webhook <url>`

For Teams: create an **Incoming Webhook** connector in any Teams channel and use
`--teams-webhook <url>`.

Neither is required to pass the assessment — a terminal report is sufficient evidence
that your monitoring config runs.

---

## Docker + Postgres note

If you spun up Postgres via Docker, make sure the container is running before you
run `dbt` or `edr`:

```bash
docker ps   # confirm the container is up
```

Elementary writes to a separate schema (`elementary`) in the same Postgres database —
you do not need a second container.

---

## Useful edr commands

```bash
edr monitor                  # run monitor and print report
edr report                   # generate a local HTML report (opens in browser)
edr send-report              # send the HTML report to Slack/Teams
edr debug                    # check your connection and config
```
