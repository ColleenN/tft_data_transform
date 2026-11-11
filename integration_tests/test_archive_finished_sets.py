"""Runs archive_finished_sets against sample datasets in BigQuery:

    pip install -r integration_tests/requirements.txt
    pytest integration_tests
"""

import json
from datetime import datetime, timedelta, timezone

from dbt.cli.main import dbtRunner

from test_archive_set import LANDING_TABLES, PROJECT_DIR

AS_OF = datetime(2026, 8, 1, tzinfo=timezone.utc)
RANKED, PBE_NORMAL, REVIVAL = "1100", "1090", "6000"


def match(match_id, set_num, days_before, queue_id=RANKED):
    started = AS_OF - timedelta(days=days_before)
    return {
        "metadata": {"match_id": match_id},
        "info": {
            "tft_set_number": set_num,
            "gameCreation": int(started.timestamp() * 1000),
            "queue_id": int(queue_id),
        },
    }


def run(landing, archive, current_set=18, **kwargs):
    args = {
        "landing_dataset": landing.name,
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
    landing = landing_with(sample_dataset, [match("NA1_1", 17, 90), match("PBE1_2", 18, 27, PBE_NORMAL)])
    archive = sample_dataset("archive")
    assert run(landing, archive)
    assert_each_table(landing, archive, {17: 1, 18: 1}, None)


def test_archives_older_sets_once_a_pbe_match_is_old_enough(sample_dataset):
    landing = landing_with(sample_dataset, [
        match("NA1_1", 16, 200),
        match("NA1_2", 17, 90),
        match("NA1_3", 17, 1),
        match("PBE1_4", 18, 29, PBE_NORMAL),
    ])
    archive = sample_dataset("archive")
    assert run(landing, archive)
    assert_each_table(landing, archive, {18: 1}, {16: 1, 17: 2})


def test_other_queues_dont_count_as_a_release(sample_dataset):
    landing = landing_with(sample_dataset, [
        match("NA1_1", 17, 90),
        match("NA1_2", 18, 60, REVIVAL),
        match("NA1_3", 18, 1),
    ])
    archive = sample_dataset("archive")
    assert run(landing, archive)
    assert_each_table(landing, archive, {17: 1, 18: 2}, None)


def test_older_set_numbers_from_other_queues_are_archived(sample_dataset):
    landing = landing_with(sample_dataset, [match("NA1_1", 10, 5, REVIVAL), match("NA1_2", 18, 60)])
    archive = sample_dataset("archive")
    assert run(landing, archive)
    assert_each_table(landing, archive, {18: 1}, {10: 1})


def test_fails_while_current_set_is_behind(sample_dataset):
    landing = landing_with(sample_dataset, [match("NA1_1", 17, 90), match("NA1_2", 18, 60)])
    archive = sample_dataset("archive")
    assert not run(landing, archive, current_set=17)
    assert landing.counts(LANDING_TABLES[0]) == {17: 1, 18: 1}


def test_dry_run_changes_nothing(sample_dataset):
    landing = landing_with(sample_dataset, [match("NA1_1", 17, 90), match("NA1_2", 18, 60)])
    archive = sample_dataset("archive")
    assert run(landing, archive, dry_run=True)
    assert_each_table(landing, archive, {17: 1, 18: 1}, None)
