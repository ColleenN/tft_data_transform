"""Runs archive_set against scratch datasets in BigQuery:

    pip install -r integration_tests/requirements.txt
    pytest integration_tests
"""

from conftest import LANDING_TABLES, PROJECT, SEED_ROWS

ALL_LANDED = {17: 2, 18: 1, None: 2}
AFTER_ARCHIVE = {18: 1, None: 2}


def assert_each_table(scratch, landing, archive):
    for table in LANDING_TABLES:
        assert scratch.counts(scratch.landing, table) == landing, table
        assert scratch.counts(scratch.archive, table) == archive, table


def test_moves_only_the_finished_set(scratch):
    scratch.seed()
    assert scratch.archive_set(17)
    assert_each_table(scratch, landing=AFTER_ARCHIVE, archive={17: 2})


def test_rerun_changes_nothing(scratch):
    scratch.seed()
    assert scratch.archive_set(17)
    assert scratch.archive_set(17)
    assert_each_table(scratch, landing=AFTER_ARCHIVE, archive={17: 2})


def test_resumes_after_an_interrupted_copy(scratch):
    scratch.seed()
    for table in LANDING_TABLES:
        scratch.query(
            f"CREATE TABLE `{PROJECT}.{scratch.archive}.{table}` LIKE `{PROJECT}.{scratch.landing}.{table}`"
        )
        scratch.insert(scratch.archive, table, SEED_ROWS[:1])
    assert scratch.archive_set(17)
    assert_each_table(scratch, landing=AFTER_ARCHIVE, archive={17: 2})


def test_dry_run_changes_nothing(scratch):
    scratch.seed()
    assert scratch.archive_set(17, dry_run=True)
    assert_each_table(scratch, landing=ALL_LANDED, archive=None)


def test_refuses_the_current_set(scratch):
    scratch.seed()
    assert not scratch.archive_set(17, current_set=17)
    assert_each_table(scratch, landing=ALL_LANDED, archive=None)
