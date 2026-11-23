#!/bin/sh
# Prefixes this build's tables with part of its build ID (see
# macros/generate_alias_name.sql).
set -e
DBT_CI_TABLE_PREFIX="b$(printf '%s' "$CI_BUILD_ID" | tr -d '-' | cut -c1-12)_"
export DBT_CI_TABLE_PREFIX
exec /workspace/.venv/bin/dbt "$@"
