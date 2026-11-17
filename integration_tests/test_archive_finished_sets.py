"""Runs archive_finished_sets against sample datasets in BigQuery:

    pip install -r integration_tests/requirements.txt
    pytest integration_tests
"""

import json
from datetime import datetime, timedelta, timezone

from dbt.cli.main import dbtRunner

from test_archive_set import LANDING_TABLES, PROJECT_DIR

AS_OF = datetime(2026, 8, 1, tzinfo=timezone.utc)
UNITS_SCHEMA = "(channel STRING, set_number INT64, captured_at TIMESTAMP)"


def match(match_id, set_num):
    return {"metadata": {"match_id": match_id}, "info": {"tft_set_number": set_num}}


def reference_with(sample_dataset, captures):
    """captures: (channel, set_number, days_before) for each unit row."""
    reference = sample_dataset("reference", tables=["units"], schema=UNITS_SCHEMA)
    values = ", ".join(
        f"('{channel}', {set_number}, TIMESTAMP('{(AS_OF - timedelta(days=days)).isoformat()}'))"
        for channel, set_number, days in captures
    )
    reference.query(f"INSERT INTO {reference.table('units')} VALUES {values}")
    return reference


def run(landing, reference, archive, current_set=18, **kwargs):
    args = {
        "landing_dataset": landing.name,
        "reference_dataset": reference.name,
        "archive_dataset": archive.name,
        "as_of": AS_OF.isoformat(),
        **kwargs,
    }
    result = dbtRunner().invoke([
        "run-operation", "archive_finished_sets",
        "--args", json.dumps(args),
        "--vars", json.dumps({"current_set": current_set}),
        "--project-dir", str(PROJECT_DIR),
    ])
    return result.success


def landing_with(sample_dataset, rows):
    return sample_dataset("landing", tables=LANDING_TABLES, rows=list(zip(rows, range(1, len(rows) + 1))))


def assert_each_table(landing, archive, landing_counts, archive_counts):
    for table in LANDING_TABLES:
        assert landing.counts(table) == landing_counts, table
        assert archive.counts(table) == archive_counts, table


def test_waits_out_the_grace_period(sample_dataset):
    landing = landing_with(sample_dataset, [match("NA1_1", 17), match("NA1_2", 18)])
    reference = reference_with(sample_dataset, [("live", 17, 90), ("live", 18, 13), ("live", 18, 1)])
    archive = sample_dataset("archive")
    assert run(landing, reference, archive)
    assert_each_table(landing, archive, {17: 1, 18: 1}, None)


def test_archives_older_sets_once_the_new_set_is_old_enough_in_live_data(sample_dataset):
    landing = landing_with(sample_dataset, [
        match("NA1_1", 16),
        match("NA1_2", 17),
        match("NA1_3", 17),
        match("NA1_4", 18),
    ])
    reference = reference_with(sample_dataset, [("live", 17, 90), ("live", 18, 15), ("live", 18, 2)])
    archive = sample_dataset("archive")
    assert run(landing, reference, archive)
    assert_each_table(landing, archive, {18: 1}, {16: 1, 17: 2})


def test_pbe_reference_data_doesnt_count_as_a_release(sample_dataset):
    landing = landing_with(sample_dataset, [match("NA1_1", 17), match("PBE1_2", 18)])
    reference = reference_with(sample_dataset, [("live", 17, 90), ("pbe", 18, 60)])
    archive = sample_dataset("archive")
    assert run(landing, reference, archive)
    assert_each_table(landing, archive, {17: 1, 18: 1}, None)


def test_matches_without_reference_data_dont_count_as_a_release(sample_dataset):
    landing = landing_with(sample_dataset, [match("NA1_1", 17), match("NA1_2", 18)])
    reference = reference_with(sample_dataset, [("live", 17, 90)])
    archive = sample_dataset("archive")
    assert run(landing, reference, archive)
    assert_each_table(landing, archive, {17: 1, 18: 1}, None)


def test_fails_while_current_set_is_behind(sample_dataset):
    landing = landing_with(sample_dataset, [match("NA1_1", 17), match("NA1_2", 18)])
    reference = reference_with(sample_dataset, [("live", 18, 60)])
    archive = sample_dataset("archive")
    assert not run(landing, reference, archive, current_set=17)
    assert landing.counts(LANDING_TABLES[0]) == {17: 1, 18: 1}


def test_dry_run_changes_nothing(sample_dataset):
    landing = landing_with(sample_dataset, [match("NA1_1", 17), match("NA1_2", 18)])
    reference = reference_with(sample_dataset, [("live", 18, 60)])
    archive = sample_dataset("archive")
    assert run(landing, reference, archive, dry_run=True)
    assert_each_table(landing, archive, {17: 1, 18: 1}, None)
