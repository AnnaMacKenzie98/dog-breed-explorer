import json
import os
from datetime import datetime, timezone

import dlt
import requests
from dlt.sources.rest_api import rest_api_source
from google.cloud import storage

# Base URL for The Dog API — all endpoints are relative to this
DOG_API_BASE_URL = "https://api.thedogapi.com/v1"
# API key is optional; without it requests are rate-limited to ~10/min
DOG_API_KEY = os.getenv("DOG_API_KEY", "")
# GCS bucket where raw JSON snapshots are archived before loading
GCS_BUCKET = os.getenv("GCS_BUCKET")
# GCP project that owns both the GCS bucket and BigQuery dataset
GCP_PROJECT = os.getenv("GCP_PROJECT")
# BigQuery dataset (the "bronze" layer) where raw data lands
BQ_DATASET = os.getenv("BQ_DATASET", "bronze")
# BigQuery location must match where the dataset was created
BQ_LOCATION = os.getenv("BQ_LOCATION", "EU")

# Fail fast if required environment variables are not set
if not GCS_BUCKET:
    raise ValueError("GCS_BUCKET environment variable is not set")
if not GCP_PROJECT:
    raise ValueError("GCP_PROJECT environment variable is not set")

# Shared headers used by both the dlt source and the direct requests call
API_HEADERS = {"Content-Type": "application/json"}
if DOG_API_KEY:
    API_HEADERS["x-api-key"] = DOG_API_KEY


def upload_raw_json_to_gcs(data, bucket_name):
    # Build a date-partitioned path so each daily run is stored separately
    run_date = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    blob_path = f"dog_api/breeds/{run_date}/breeds.json"

    # Authenticate and get a handle to the target GCS bucket
    client = storage.Client(project=GCP_PROJECT)
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_path)

    # Serialize the Python list to indented JSON and upload it as a string
    blob.upload_from_string(
        json.dumps(data, indent=2),
        content_type="application/json",
    )
    print(f"Uploaded raw JSON to gs://{bucket_name}/{blob_path}")

    # Return the full GCS URI so callers can log or reference the file
    return f"gs://{bucket_name}/{blob_path}"


def create_dlt_pipeline():
    # Declare the REST API source using dlt's declarative config
    source = rest_api_source(
        {
            "client": {
                "base_url": DOG_API_BASE_URL,  # prepended to all endpoint paths
                "headers": API_HEADERS,  # shared headers built at module level
            },
            "resources": [
                {
                    "name": "dog_api_raw",  # becomes the BigQuery table name
                    "endpoint": {
                        "path": "breeds",  # resolves to /v1/breeds
                        "params": {
                            "limit": 200,  # fetch up to 200 breeds per page
                            "page": 0,    # start from the first page
                        },
                    },
                    # "replace" truncates the table on each run instead of appending
                    "write_disposition": "replace",
                },
            ],
        }
    )

    # Create the dlt pipeline that writes to BigQuery
    pipeline = dlt.pipeline(
        pipeline_name="dog_breed_explorer",
        destination=dlt.destinations.bigquery(location=BQ_LOCATION),
        dataset_name=BQ_DATASET,  # writes into the "bronze" dataset
    )

    return pipeline, source


def run():
    print("Fetching breeds from The Dog API...")

    # Make a direct HTTP GET to the breeds endpoint to capture the raw response
    response = requests.get(
        f"{DOG_API_BASE_URL}/breeds",
        headers=API_HEADERS,  # shared headers built at module level
        params={"limit": 200, "page": 0},
        timeout=30,  # abort if the server takes more than 30 seconds to respond
    )
    # Raise an exception immediately if the server returned a 4xx or 5xx status
    response.raise_for_status()
    # Parse the JSON response body into a Python list of breed dicts
    raw_data = response.json()
    print(f"Retrieved {len(raw_data)} breeds")

    # Archive the raw response to GCS before any transformation
    try:
        gcs_path = upload_raw_json_to_gcs(raw_data, GCS_BUCKET)
        print(f"Raw JSON archived at {gcs_path}")
    except Exception as e:
        # GCS archival is best-effort; a failure here doesn't block the BQ load
        print(f"GCS upload failed (non-fatal): {e}")
        print("Continuing with BigQuery load...")

    print("Loading data into BigQuery via dlt...")
    # Build the dlt pipeline and REST source, then run the load
    pipeline, source = create_dlt_pipeline()
    load_info = pipeline.run(source)  # executes the full extract → load cycle

    print("dlt load complete!")
    print(load_info)

    # Quick sanity check: query BigQuery to confirm rows were written
    with pipeline.sql_client() as client:
        result = client.execute_sql("SELECT COUNT(*) FROM dog_api_raw")
        row_count = result[0][0]  # result is a list of tuples; grab the first value
        print(f"Rows in bronze.dog_api_raw: {row_count}")
        # Fail loudly if no rows were loaded — a silent empty load is worse than a clear error
        if row_count == 0:
            raise ValueError("No rows loaded into bronze.dog_api_raw — pipeline may have failed silently")

    return load_info


if __name__ == "__main__":
    # Entry point when the script is run directly (e.g. `python dog_api_pipeline.py`)
    run()
