ARG DOCKER_REPOSITORY=python
ARG PYTHON_VERSION=3.13.7
ARG PYTHON_FLAVOUR=slim

FROM ${DOCKER_REPOSITORY}:${PYTHON_VERSION}-${PYTHON_FLAVOUR}
LABEL org.opencontainers.image.authors="oszi <osztodipeter@gmail.com>"

ARG POETRY_VERSION=2.2.1
ENV PIP_DISABLE_PIP_VERSION_CHECK=on \
    PYTHONUNBUFFERED=1 \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_CREATE=false \
    PATH="$PATH:/root/.local/bin"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        build-essential \
        curl \
        git \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        make \
        wget \
        zlib1g-dev \
    && curl -sSL https://install.python-poetry.org | python3 - --version ${POETRY_VERSION} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY ./legalrank ./legalrank

RUN cd ./legalrank && poetry install --no-root
RUN cd ./legalrank && poetry run dbt deps --profiles-dir .

CMD ["bash"]
