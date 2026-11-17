# Image for scheduled dbt operations such as archive_finished_sets. The job
# mounts profiles.yml and points DBT_PROFILES_DIR at it.
FROM python:3.12-slim

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DO_NOT_TRACK=1

RUN pip install "dbt-bigquery~=1.10"

WORKDIR /dbt
COPY . .
# dbt_utils is a git package, so deps needs git; it's removed again in the
# same layer since nothing needs it at run time.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && dbt deps \
    && apt-get purge -y git \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# The project directory belongs to root, so dbt writes elsewhere at run time.
ENV DBT_TARGET_PATH=/tmp/dbt/target \
    DBT_LOG_PATH=/tmp/dbt/logs

USER nobody

ENTRYPOINT ["dbt"]
