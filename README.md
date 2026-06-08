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
