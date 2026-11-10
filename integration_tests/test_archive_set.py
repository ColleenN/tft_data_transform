"""Runs archive_set against sample datasets in BigQuery:

    pip install -r integration_tests/requirements.txt
    pytest integration_tests
"""

import json
from pathlib import Path

from dbt.cli.main import dbtRunner

PROJECT_DIR = Path(__file__).resolve().parent.parent
LANDING_TABLES = (
    "tft_player_match_detail",
    "apex_ranked_ladder_match_detail",
    "normal_ranked_ladder_match_detail",
)


def match(match_id, set_num):
    return {"metadata": {"match_id": match_id}, "info": {"tft_set_number": set_num}}


# (data, _sdc_sequence) rows loaded into every landing table.
# The last two have no readable set number and must never move.
LANDED_ROWS = [
    (match("NA1_1", 17), 1),
    (match("NA1_2", 17), 2),
    (match("NA1_3", 18), 3),
    ({"metadata": {"match_id": "NA1_4"}}, 4),
    (None, 5),
]
ALL_LANDED = {17: 2, 18: 1, None: 2}
AFTER_ARCHIVE = {18: 1, None: 2}


def run_archive_set(landing, archive, set_num, current_set=18, **kwargs):
    args = {"set_num": set_num, "landing_dataset": landing.name, "archive_dataset": archive.name, **kwargs}
    result = dbtRunner().invoke([
        "run-operation", "archive_set",
        "--args", json.dumps(args),
        "--vars", json.dumps({"current_set": current_set}),
        "--project-dir", str(PROJECT_DIR),
    ])
    return result.success


def assert_each_table(landing, archive, landing_counts, archive_counts):
    for table in LANDING_TABLES:
        assert landing.counts(table) == landing_counts, table
        assert archive.counts(table) == archive_counts, table


def test_moves_only_the_finished_set(sample_dataset):
    landing = sample_dataset("landing", tables=LANDING_TABLES, rows=LANDED_ROWS)
    archive = sample_dataset("archive")
    assert run_archive_set(landing, archive, 17)
    assert_each_table(landing, archive, AFTER_ARCHIVE, {17: 2})


def test_rerun_changes_nothing(sample_dataset):
    landing = sample_dataset("landing", tables=LANDING_TABLES, rows=LANDED_ROWS)
    archive = sample_dataset("archive")
    assert run_archive_set(landing, archive, 17)
    assert run_archive_set(landing, archive, 17)
    assert_each_table(landing, archive, AFTER_ARCHIVE, {17: 2})


def test_resumes_after_an_interrupted_copy(sample_dataset):
    landing = sample_dataset("landing", tables=LANDING_TABLES, rows=LANDED_ROWS)
    archive = sample_dataset("archive", tables=LANDING_TABLES, rows=LANDED_ROWS[:1])
    assert run_archive_set(landing, archive, 17)
    assert_each_table(landing, archive, AFTER_ARCHIVE, {17: 2})


def test_dry_run_changes_nothing(sample_dataset):
    landing = sample_dataset("landing", tables=LANDING_TABLES, rows=LANDED_ROWS)
    archive = sample_dataset("archive")
    assert run_archive_set(landing, archive, 17, dry_run=True)
    assert_each_table(landing, archive, ALL_LANDED, None)


def test_refuses_the_current_set(sample_dataset):
    landing = sample_dataset("landing", tables=LANDING_TABLES, rows=LANDED_ROWS)
    archive = sample_dataset("archive")
    assert not run_archive_set(landing, archive, 17, current_set=17)
    assert_each_table(landing, archive, ALL_LANDED, None)
