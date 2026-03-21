@"
# Dog Breed Explorer

An end-to-end data pipeline on GCP that ingests dog breed data from The Dog API, models it with dbt, and serves analytics through Looker Studio.

![CI/CD](https://github.com/AnnaMacKenzie98/dog-breed-explorer/actions/workflows/ci.yml/badge.svg)

## Architecture

Dog API -> dlt (Cloud Run) -> GCS (raw JSON) -> BigQuery (bronze) -> dbt (silver/gold) -> Looker Studio

## Dashboard

[View the live dashboard](https://lookerstudio.google.com/u/0/reporting/494020bd-53f5-4f87-853c-2fb15184c4bc/page/aShsF)

## Tech Stack

| Layer | Tool |
|-------|------|
| Ingestion | dlt (Data Load Tool) on Cloud Run |
| Storage | Cloud Storage (raw JSON) + BigQuery |
| Orchestration | Cloud Scheduler (daily 02:00 UTC) |
| Transformation | dbt Core targeting BigQuery |
| CI/CD | GitHub Actions |
| Visualisation | Looker Studio |

## Data Model (Medallion Architecture)

| Layer | Table | Description |
|-------|-------|-------------|
| Bronze | bronze.dog_api_raw | Raw JSON from API, loaded by dlt |
| Silver | silver.stg_dog_breeds | Typed, cleaned, NULLs handled |
| Gold | gold.dim_breed | Breed dimension with size class |
| Gold | gold.fact_weight_life_span | Numeric metrics for analysis |

## Data Quality

10 automated dbt tests:
- unique + not_null on breed_id across all layers
- not_null on breed_name
- accepted_values on size_class (Small, Medium, Large, Giant, Unknown)
- Custom singular test: assert_life_span_positive

## Findings (300 words)

Our analysis of 169 dog breeds reveals that weight is the strongest predictor of life span. Small breeds live approximately 3.4 years longer than giant breeds on average (13.5 vs 10.1 years). Toy and Terrier groups dominate the longevity charts, with several breeds exceeding 15-year average spans.

The most popular family-friendly temperaments (Loyal, Friendly) correlate with shorter life spans, but this is a size confound — the friendliest breeds (Labrador, Golden Retriever, German Shepherd) tend to be large, and large breeds live shorter lives. This is not causation.

Weight is more predictive than breed group alone. A pet insurance company could use this curated layer to price policies by weight class rather than breed name, identify long-lived small breeds for targeted marketing, and flag data quality gaps to prioritise which breeds need manual enrichment.

67% of breeds lack complete weight, height, and life span data, suggesting the free API tier has significant gaps that would need enrichment for production use. Our has_complete_metrics flag in the fact table makes this transparent to downstream consumers.

These findings are based on the free tier of The Dog API. Production use should validate against veterinary databases such as OFA or AKC registration data.

## Trade-offs

| Decision | Trade-off | Future |
|----------|-----------|--------|
| Cloud Run Job vs Cloud Function | More setup, but better for Docker flexibility | Could simplify to Cloud Function |
| dbt Core vs dbt Cloud | Free, full control; no GUI | Evaluate dbt Cloud for team use |
| replace write disposition | Re-loads all data each run | Switch to merge if API supports incremental |
| OAuth for dbt, SA key for dlt | Two auth methods | Unify with Workload Identity Federation |

## Running Locally
``````
git clone https://github.com/AnnaMacKenzie98/dog-breed-explorer.git
cd dog-breed-explorer
python -m venv venv
source venv/bin/activate  # or .\venv\Scripts\Activate on Windows
pip install -r ingestion/requirements.txt
pip install dbt-bigquery>=1.7.0
export GOOGLE_APPLICATION_CREDENTIALS=credentials.json
python ingestion/dog_api_pipeline.py
cd dbt_project && dbt deps && dbt run && dbt test
``````
"@ | Out-File -Encoding utf8 README.md