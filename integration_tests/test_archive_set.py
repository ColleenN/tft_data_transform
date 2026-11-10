"""Runs archive_set against sample datasets in BigQuery:

    pip install -r integration_tests/requirements.txt
    pytest integration_tests
"""

from conftest import LANDING_TABLES, SEED_ROWS, run_archive_set, seed_landing

ALL_LANDED = {17: 2, 18: 1, None: 2}
AFTER_ARCHIVE = {18: 1, None: 2}


def assert_each_table(landing, archive, landing_counts, archive_counts):
    for table in LANDING_TABLES:
        assert landing.counts(table) == landing_counts, table
        assert archive.counts(table) == archive_counts, table


def test_moves_only_the_finished_set(sample_dataset):
    landing = sample_dataset("landing", tables=LANDING_TABLES)
    archive = sample_dataset("archive")
    seed_landing(landing)
    assert run_archive_set(landing, archive, 17)
    assert_each_table(landing, archive, AFTER_ARCHIVE, {17: 2})


def test_rerun_changes_nothing(sample_dataset):
    landing = sample_dataset("landing", tables=LANDING_TABLES)
    archive = sample_dataset("archive")
    seed_landing(landing)
    assert run_archive_set(landing, archive, 17)
    assert run_archive_set(landing, archive, 17)
    assert_each_table(landing, archive, AFTER_ARCHIVE, {17: 2})


def test_resumes_after_an_interrupted_copy(sample_dataset):
    landing = sample_dataset("landing", tables=LANDING_TABLES)
    archive = sample_dataset("archive")
    seed_landing(landing)
    for table in LANDING_TABLES:
        archive.create_table(table, like=landing)
        archive.insert(table, SEED_ROWS[:1])
    assert run_archive_set(landing, archive, 17)
    assert_each_table(landing, archive, AFTER_ARCHIVE, {17: 2})


def test_dry_run_changes_nothing(sample_dataset):
    landing = sample_dataset("landing", tables=LANDING_TABLES)
    archive = sample_dataset("archive")
    seed_landing(landing)
    assert run_archive_set(landing, archive, 17, dry_run=True)
    assert_each_table(landing, archive, ALL_LANDED, None)


def test_refuses_the_current_set(sample_dataset):
    landing = sample_dataset("landing", tables=LANDING_TABLES)
    archive = sample_dataset("archive")
    seed_landing(landing)
    assert not run_archive_set(landing, archive, 17, current_set=17)
    assert_each_table(landing, archive, ALL_LANDED, None)
