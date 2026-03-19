import json
import os
from datetime import datetime, timezone

import dlt
from dlt.sources.rest_api import rest_api_source
from google.cloud import storage

DOG_API_BASE_URL = "https://api.thedogapi.com/v1"
DOG_API_KEY = os.getenv("DOG_API_KEY", "")
GCS_BUCKET = os.getenv("GCS_BUCKET", "dog-breed-explorer-am-raw")
GCP_PROJECT = os.getenv("GCP_PROJECT", "dog-breed-explorer-am")
BQ_DATASET = os.getenv("BQ_DATASET", "bronze")


def upload_raw_json_to_gcs(data, bucket_name):
    run_date = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    blob_path = f"dog_api/breeds/{run_date}/breeds.json"
    client = storage.Client(project=GCP_PROJECT)
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_path)
    blob.upload_from_string(
        json.dumps(data, indent=2),
        content_type="application/json",
    )
    print(f"Uploaded raw JSON to gs://{bucket_name}/{blob_path}")
    return f"gs://{bucket_name}/{blob_path}"


def create_dlt_pipeline():
    headers = {"Content-Type": "application/json"}
    if DOG_API_KEY:
        headers["x-api-key"] = DOG_API_KEY

    source = rest_api_source(
        {
            "client": {
                "base_url": DOG_API_BASE_URL,
                "headers": headers,
            },
            "resources": [
                {
                    "name": "dog_api_raw",
                    "endpoint": {
                        "path": "breeds",
                        "params": {
                            "limit": 200,
                            "page": 0,
                        },
                    },
                    "write_disposition": "replace",
                },
            ],
        }
    )

    pipeline = dlt.pipeline(
        pipeline_name="dog_breed_explorer",
        destination="bigquery",
        dataset_name=BQ_DATASET,
    )

    return pipeline, source


def run():
    import requests

    print("Fetching breeds from The Dog API...")
    resp_headers = {"Content-Type": "application/json"}
    if DOG_API_KEY:
        resp_headers["x-api-key"] = DOG_API_KEY

    response = requests.get(
        f"{DOG_API_BASE_URL}/breeds",
        headers=resp_headers,
        params={"limit": 200, "page": 0},
        timeout=30,
    )
    response.raise_for_status()
    raw_data = response.json()
    print(f"Retrieved {len(raw_data)} breeds")

    try:
        gcs_path = upload_raw_json_to_gcs(raw_data, GCS_BUCKET)
        print(f"Raw JSON archived at {gcs_path}")
    except Exception as e:
        print(f"GCS upload failed (non-fatal): {e}")
        print("Continuing with BigQuery load...")

    print("Loading data into BigQuery via dlt...")
    pipeline, source = create_dlt_pipeline()
    load_info = pipeline.run(source)

    print(f"dlt load complete!")
    print(f"{load_info}")

    with pipeline.sql_client() as client:
        result = client.execute_sql("SELECT COUNT(*) FROM dog_api_raw")
        row_count = result[0][0]
        print(f"Rows in bronze.dog_api_raw: {row_count}")

    return load_info


if __name__ == "__main__":
    run()
