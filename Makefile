DOCKER_IMAGE ?= legalrank-assessment
DOCKERFILE ?= ./Dockerfile
DBT_TARGET ?= prod

ENV_FILE ?= $(CURDIR)/.env

DOCKER_RUN ?= docker run --rm --env-file $(ENV_FILE) $(DOCKER_IMAGE)

DBT_DIR ?= /app/legalrank
POETRY ?= /root/.local/bin/poetry
DBT ?= cd $(DBT_DIR) && $(POETRY) run dbt
DBT_FLAGS ?= --profiles-dir . --target $(DBT_TARGET)

docker-build:
	docker build -f $(DOCKERFILE) -t $(DOCKER_IMAGE) .

docker-shell:
	docker run --rm --env-file $(ENV_FILE) -it $(DOCKER_IMAGE) bash

docker-env:
	$(DOCKER_RUN) printenv | sort

dbt-debug:
	$(DOCKER_RUN) bash -c "$(DBT) debug $(DBT_FLAGS)"

dbt-deps:
	$(DOCKER_RUN) bash -c "$(DBT) deps --profiles-dir ."

dbt-run:
	$(DOCKER_RUN) bash -c "$(DBT) run $(DBT_FLAGS)"

dbt-test:
	$(DOCKER_RUN) bash -c "$(DBT) test $(DBT_FLAGS)"

dbt-build:
	$(DOCKER_RUN) bash -c "$(DBT) build $(DBT_FLAGS)"
