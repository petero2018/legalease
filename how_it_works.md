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
