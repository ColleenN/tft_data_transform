"""Sample BigQuery datasets for integration tests.

Tests create datasets through the sample_dataset factory, which drops
them when the test ends.
dbt runs with your normal profile, whose target project must be
TFT_TEST_PROJECT, and needs permission to create and drop datasets.
"""

import json
import os
import uuid

import pytest
from google.api_core.exceptions import NotFound
from google.cloud import bigquery

PROJECT = os.environ.get("TFT_TEST_PROJECT", "tft-data-463022")
LOCATION = os.environ.get("TFT_TEST_LOCATION", "us-central1")
LANDING_SCHEMA = "(data JSON, _sdc_sequence INT64, _sdc_batched_at TIMESTAMP)"


class SampleDataset:
    """A temporary BigQuery dataset holding sample rows."""

    def __init__(self, client, name):
        self.client = client
        self.name = name

    def create(self):
        dataset = bigquery.Dataset(f"{PROJECT}.{self.name}")
        dataset.location = LOCATION
        dataset.default_table_expiration_ms = 24 * 60 * 60 * 1000
        self.client.create_dataset(dataset)

    def drop(self):
        self.client.delete_dataset(f"{PROJECT}.{self.name}", delete_contents=True, not_found_ok=True)

    def table(self, table):
        return f"`{PROJECT}.{self.name}.{table}`"

    def query(self, sql):
        return list(self.client.query(sql).result())

    def create_table(self, table, schema=LANDING_SCHEMA):
        self.query(f"CREATE TABLE {self.table(table)} {schema}")

    def insert(self, table, rows):
        """Loads (data, _sdc_sequence) rows with DML; streamed rows couldn't be deleted yet."""
        values = ", ".join(
            f"({'NULL' if data is None else 'PARSE_JSON(' + repr(json.dumps(data)) + ')'}, {seq}, CURRENT_TIMESTAMP())"
            for data, seq in rows
        )
        self.query(f"INSERT INTO {self.table(table)} (data, _sdc_sequence, _sdc_batched_at) VALUES {values}")

    def counts(self, table):
        """Rows per set number (None for unreadable), or None if the table doesn't exist."""
        try:
            rows = self.query(
                f"SELECT SAFE_CAST(JSON_VALUE(data, '$.info.tft_set_number') AS INT64) AS set_num, COUNT(*) AS n "
                f"FROM {self.table(table)} GROUP BY 1"
            )
        except NotFound:
            return None
        return {row.set_num: row.n for row in rows}


@pytest.fixture(scope="session")
def client():
    os.environ.setdefault("DO_NOT_TRACK", "1")
    return bigquery.Client(project=PROJECT, location=LOCATION)


@pytest.fixture
def sample_dataset(client):
    """Factory for SampleDatasets that are dropped when the test ends.

    sample_dataset("landing", tables=[...], rows=[...]) creates a dataset
    named sample_<id>_landing, with those tables each holding those rows.
    Datasets made in the same test share the <id>.
    """
    prefix = f"sample_{uuid.uuid4().hex[:8]}"
    created = []

    def make(name, tables=(), rows=(), schema=LANDING_SCHEMA):
        dataset = SampleDataset(client, f"{prefix}_{name}")
        dataset.create()
        created.append(dataset)
        for table in tables:
            dataset.create_table(table, schema=schema)
            if rows:
                dataset.insert(table, rows)
        return dataset

    try:
        yield make
    finally:
        for dataset in created:
            dataset.drop()
