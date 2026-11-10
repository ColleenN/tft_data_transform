{# Exists only so unit tests can exercise the macro; enable with --vars '{macro_harnesses: true}'. #}
{{ config(enabled=var('macro_harnesses', false), materialized='view') }}

{{ latest_raw_match_detail(set_num=17, env=var('harness_env', 'live')) }}
