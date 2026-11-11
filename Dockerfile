# Image for scheduled dbt operations such as archive_finished_sets. The job
# mounts profiles.yml and points DBT_PROFILES_DIR at it.
FROM python:3.12-slim

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DO_NOT_TRACK=1

RUN pip install "dbt-bigquery~=1.10"

WORKDIR /dbt
COPY . .
RUN dbt deps

# The project directory belongs to root, so dbt writes elsewhere at run time.
ENV DBT_TARGET_PATH=/tmp/dbt/target \
    DBT_LOG_PATH=/tmp/dbt/logs

USER nobody

ENTRYPOINT ["dbt"]
