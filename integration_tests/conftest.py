"""Scratch BigQuery datasets for testing the archive_set macro.

Each test gets its own landing and archive datasets, dropped afterwards.
dbt runs with your normal profile, whose target project must be
TFT_TEST_PROJECT, and needs permission to create and drop datasets.
"""

import json
import os
import uuid
from pathlib import Path

import pytest
from dbt.cli.main import dbtRunner
from google.api_core.exceptions import NotFound
from google.cloud import bigquery

PROJECT = os.environ.get("TFT_TEST_PROJECT", "tft-data-463022")
LOCATION = os.environ.get("TFT_TEST_LOCATION", "us-central1")
PROJECT_DIR = Path(__file__).resolve().parent.parent
LANDING_TABLES = (
    "tft_player_match_detail",
    "apex_ranked_ladder_match_detail",
    "normal_ranked_ladder_match_detail",
)


def match(match_id, set_num):
    return {"metadata": {"match_id": match_id}, "info": {"tft_set_number": set_num}}


# (data, _sdc_sequence) rows loaded into every landing table by seed().
# The last two have no readable set number and must never move.
SEED_ROWS = [
    (match("NA1_1", 17), 1),
    (match("NA1_2", 17), 2),
    (match("NA1_3", 18), 3),
    ({"metadata": {"match_id": "NA1_4"}}, 4),
    (None, 5),
]


class Scratch:
    def __init__(self, client, prefix):
        self.client = client
        self.landing = f"{prefix}_landing"
        self.archive = f"{prefix}_archive"

    def query(self, sql):
        return list(self.client.query(sql).result())

    def insert(self, dataset, table, rows):
        values = ", ".join(
            f"({'NULL' if data is None else 'PARSE_JSON(' + repr(json.dumps(data)) + ')'}, {seq}, CURRENT_TIMESTAMP())"
            for data, seq in rows
        )
        self.query(f"INSERT INTO `{PROJECT}.{dataset}.{table}` (data, _sdc_sequence, _sdc_batched_at) VALUES {values}")

    def seed(self):
        for table in LANDING_TABLES:
            self.insert(self.landing, table, SEED_ROWS)

    def counts(self, dataset, table):
        """Rows per set number (None for unreadable), or None if the table doesn't exist."""
        try:
            rows = self.query(
                f"SELECT SAFE_CAST(JSON_VALUE(data, '$.info.tft_set_number') AS INT64) AS set_num, COUNT(*) AS n "
                f"FROM `{PROJECT}.{dataset}.{table}` GROUP BY 1"
            )
        except NotFound:
            return None
        return {row.set_num: row.n for row in rows}

    def archive_set(self, set_num, current_set=18, **kwargs):
        args = {"set_num": set_num, "archive_dataset": self.archive, "landing_dataset": self.landing, **kwargs}
        result = dbtRunner().invoke([
            "run-operation", "archive_set",
            "--args", json.dumps(args),
            "--vars", json.dumps({"current_set": current_set}),
            "--project-dir", str(PROJECT_DIR),
        ])
        return result.success


@pytest.fixture(scope="session")
def client():
    os.environ.setdefault("DO_NOT_TRACK", "1")
    return bigquery.Client(project=PROJECT, location=LOCATION)


@pytest.fixture
def scratch(client):
    s = Scratch(client, f"archive_test_{uuid.uuid4().hex[:8]}")
    for name in (s.landing, s.archive):
        dataset = bigquery.Dataset(f"{PROJECT}.{name}")
        dataset.location = LOCATION
        dataset.default_table_expiration_ms = 24 * 60 * 60 * 1000
        client.create_dataset(dataset)
    for table in LANDING_TABLES:
        s.query(
            f"CREATE TABLE `{PROJECT}.{s.landing}.{table}` "
            "(data JSON, _sdc_sequence INT64, _sdc_batched_at TIMESTAMP)"
        )
    try:
        yield s
    finally:
        for name in (s.landing, s.archive):
            client.delete_dataset(f"{PROJECT}.{name}", delete_contents=True, not_found_ok=True)
