"""Runs archive_before against sample datasets in BigQuery (see test_archive_set)."""

import json

from dbt.cli.main import dbtRunner

from test_archive_set import LANDING_TABLES, PROJECT_DIR, assert_each_table

CUTOFF = "2026-11-18 01:35:37+00"
BEFORE_MS = 1794960000000  # 2026-11-18 00:00 UTC
AFTER_MS = 1794970000000  # 2026-11-18 02:46 UTC


def match(match_id, set_num, game_creation):
    return {"metadata": {"match_id": match_id}, "info": {"tft_set_number": set_num, "gameCreation": game_creation}}


# Old games from both sets move; the new game and the rows without a
# gameCreation stay.
LANDED_ROWS = [
    (match("NA1_1", 18, BEFORE_MS), 1),
    (match("NA1_2", 19, BEFORE_MS), 2),
    (match("NA1_3", 19, AFTER_MS), 3),
    ({"metadata": {"match_id": "NA1_4"}, "info": {"tft_set_number": 19}}, 4),
    (None, 5),
]
ALL_LANDED = {18: 1, 19: 3, None: 1}
AFTER_ARCHIVE = {19: 2, None: 1}
ARCHIVED = {18: 1, 19: 1}


def run_archive_before(landing, archive, **kwargs):
    args = {"cutoff": CUTOFF, "landing_dataset": landing.name, "archive_dataset": archive.name, **kwargs}
    result = dbtRunner().invoke([
        "run-operation", "archive_before",
        "--args", json.dumps(args),
        "--project-dir", str(PROJECT_DIR),
    ])
    return result.success


def test_moves_only_games_before_the_cutoff(sample_dataset):
    landing = sample_dataset("landing", tables=LANDING_TABLES, rows=LANDED_ROWS)
    archive = sample_dataset("archive")
    assert run_archive_before(landing, archive)
    assert_each_table(landing, archive, AFTER_ARCHIVE, ARCHIVED)


def test_rerun_changes_nothing(sample_dataset):
    landing = sample_dataset("landing", tables=LANDING_TABLES, rows=LANDED_ROWS)
    archive = sample_dataset("archive")
    assert run_archive_before(landing, archive)
    assert run_archive_before(landing, archive)
    assert_each_table(landing, archive, AFTER_ARCHIVE, ARCHIVED)


def test_dry_run_changes_nothing(sample_dataset):
    landing = sample_dataset("landing", tables=LANDING_TABLES, rows=LANDED_ROWS)
    archive = sample_dataset("archive")
    assert run_archive_before(landing, archive, dry_run=True)
    assert_each_table(landing, archive, ALL_LANDED, None)
