# Dog Breed Explorer

An end-to-end GCP data pipeline that ingests dog breed data from [The Dog API](https://thedogapi.com), models it with dbt, and serves analytics through Looker Studio.

![CI/CD](https://github.com/AnnaMacKenzie98/dog-breed-explorer/actions/workflows/ci.yml/badge.svg)

**[dbt Docs →](https://annamackenzie98.github.io/dog-breed-explorer/)**

---

## Architecture

```
┌──────────────┐     ┌───────────────────┐     ┌──────────────────┐
│  Dog API     │────▶│  dlt Pipeline     │────▶│  Cloud Storage   │
│  /v1/breeds  │     │  (Cloud Run Job)  │     │  (raw JSON)      │
└──────────────┘     └───────┬───────────┘     └──────────────────┘
                             │
                             ▼
                     ┌───────────────────┐
                     │  BigQuery         │
                     │  bronze.dog_api_raw│
                     └───────┬───────────┘
                             │  dbt
                     ┌───────┴───────────┐
                     │                   │
              ┌──────▼──────┐    ┌───────▼──────────────┐
              │  Silver     │    │  Gold                 │
              │  stg_dog_   │───▶│  dim_breed            │
              │  breeds     │    │  fact_weight_life_span│
              └─────────────┘    └───────┬──────────────┘
                                         │
                                  ┌──────▼──────┐
                                  │ Looker      │
                                  │ Studio      │
                                  └─────────────┘

Orchestration: Cloud Scheduler (daily 02:00 UTC) → Cloud Run Job
CI/CD: GitHub Actions (lint → dbt test → deploy on merge to main)
IaC: Terraform (BigQuery datasets, GCS bucket, service account, Scheduler)
```

---

## Dashboard

[View the live dashboard](https://lookerstudio.google.com/u/0/reporting/494020bd-53f5-4f87-853c-2fb15184c4bc/page/aShsF)

The dashboard lets users explore 169+ dog breeds by size class, temperament, and lifespan — with interactive filters to narrow breeds by lifestyle fit.
---

## GCP Project

| Item | Value |
|------|-------|
| **Project ID** | `dog-breed-explorer-am` |
| **Region** | `europe-west1` |
| **Raw storage bucket** | `dog-breed-explorer-am-raw` |
| **BigQuery location** | `EU` |

### Service Accounts

| Account | Role | Purpose |
|---------|------|---------|
| `dog-pipeline-sa@dog-breed-explorer-am.iam.gserviceaccount.com` | BigQuery Data Editor, Storage Object Admin, Cloud Run Invoker | Pipeline execution (least-privilege) |

### APIs Enabled

- BigQuery API
- Cloud Storage API
- Cloud Run API
- Cloud Scheduler API
- Cloud Build API
- Container Registry API

---

## Tech Stack

| Layer | Tool |
|-------|------|
| Ingestion | dlt (Data Load Tool) on Cloud Run |
| Storage | Cloud Storage (raw JSON) + BigQuery |
| Orchestration | Cloud Scheduler (daily 02:00 UTC) |
| Transformation | dbt Core targeting BigQuery |
| IaC | Terraform |
| CI/CD | GitHub Actions |
| Visualisation | Looker Studio |

---

## Bootstrap Steps

### 1. Provision Infrastructure with Terraform

All GCP resources (BigQuery datasets, GCS bucket, service account, Cloud Scheduler job) are defined in `terraform/`.

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars if your project ID or region differ from the defaults
terraform init
terraform plan
terraform apply
```

### 2. Enable GCP APIs

Terraform does not enable APIs — run this once manually:

```bash
gcloud config set project dog-breed-explorer-am
gcloud services enable \
  bigquery.googleapis.com \
  storage.googleapis.com \
  run.googleapis.com \
  cloudscheduler.googleapis.com \
  cloudbuild.googleapis.com \
  containerregistry.googleapis.com
```

### 3. Local Development

```bash
git clone https://github.com/AnnaMacKenzie98/dog-breed-explorer.git
cd dog-breed-explorer
python -m venv venv
source venv/bin/activate  # or .\venv\Scripts\Activate on Windows
pip install -r ingestion/requirements.txt
pip install dbt-bigquery>=1.7.0

# Configure dlt secrets
cp .dlt/secrets.toml.example .dlt/secrets.toml
# Edit .dlt/secrets.toml with your GCP credentials and API key

export GOOGLE_APPLICATION_CREDENTIALS=credentials.json
python ingestion/dog_api_pipeline.py
cd dbt_project && dbt deps && dbt run && dbt test
```

### 4. Deploy to Cloud Run

```bash
gcloud builds submit ingestion/ \
  --tag gcr.io/dog-breed-explorer-am/dog-pipeline:latest

gcloud run jobs create dog-breed-ingest \
  --image gcr.io/dog-breed-explorer-am/dog-pipeline:latest \
  --region europe-west1 \
  --set-env-vars DOG_API_KEY=$DOG_API_KEY \
  --service-account dog-pipeline-sa@dog-breed-explorer-am.iam.gserviceaccount.com
```

---

## Cloud Scheduler (Daily 02:00 UTC)

Provisioned by Terraform. See `scheduler/cloud_scheduler.yaml` for the declarative config.

```bash
# To create manually if not using Terraform:
gcloud scheduler jobs create http dog-breed-daily-ingest \
  --location=europe-west1 \
  --schedule="0 2 * * *" \
  --uri="https://europe-west1-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/dog-breed-explorer-am/jobs/dog-breed-ingest:run" \
  --http-method=POST \
  --oauth-service-account-email=dog-pipeline-sa@dog-breed-explorer-am.iam.gserviceaccount.com
```

---

## Data Model (Medallion Architecture)

| Layer | Table | Materialization | Description |
|-------|-------|-----------------|-------------|
| **Bronze** | `bronze.dog_api_raw` | Table (dlt managed) | Raw JSON payload from Dog API |
| **Silver** | `silver.stg_dog_breeds` | View | Typed, cleaned, null-handled records |
| **Gold** | `gold.dim_breed` | Table | Breed dimension with size class, temperament array |
| **Gold** | `gold.fact_weight_life_span` | Table | Numeric metrics: weight, height, life span ranges |

### Key Transformations

- **`stg_dog_breeds`**: Casts IDs to INT64, parses range strings (e.g. `"10 - 15"`) into min/max floats using a custom `parse_range` macro, fills nulls with defaults.
- **`dim_breed`**: Computes `avg_life_span_years`, `avg_weight_kg`, `avg_height_cm`, splits temperament into an array, classifies breeds by size (Small ≤10kg, Medium ≤25kg, Large ≤45kg, Giant >45kg).
- **`fact_weight_life_span`**: Computes averages, range spreads, and a `has_complete_metrics` boolean flag. Sources from staging independently of `dim_breed`. Filters to breeds with at least one metric.

### dbt Docs

```bash
cd dbt_project
dbt docs generate
dbt docs serve
```

---

## Data Quality

15 automated dbt tests:

| Test | Model | Type |
|------|-------|------|
| `unique` + `not_null` on `breed_id` | stg_dog_breeds | Schema |
| `not_null` on `breed_name` | stg_dog_breeds | Schema |
| `unique` + `not_null` on `breed_id` | dim_breed | Schema |
| `not_null` on `breed_name` | dim_breed | Schema |
| `accepted_values` on `size_class` | dim_breed | Schema |
| `unique` + `not_null` on `breed_id` | fact_weight_life_span | Schema |
| `not_null` on `avg_life_span_years` (conditional) | fact_weight_life_span | Schema |
| `accepted_values` on `has_complete_metrics` | fact_weight_life_span | Schema |
| `assert_life_span_positive` | fact_weight_life_span | Custom |
| `assert_minimum_breed_count` (≥100 rows) | stg_dog_breeds | Custom |
| `assert_weight_in_valid_range` (0.5–120 kg) | fact_weight_life_span | Custom |
| `assert_life_span_in_valid_range` (3–25 yrs) | fact_weight_life_span | Custom |

Source freshness monitoring is configured on `bronze.dog_api_raw` — warns after 48 hours, errors after 72 hours.

---

## CI/CD Pipeline

**Workflow:** `.github/workflows/ci.yml`

| Trigger | Job | Actions |
|---------|-----|---------|
| PR to `main` | `lint-and-test` | Lint Python with ruff, `dbt run --target dev`, `dbt test --target dev` |
| Push to `main` | `deploy-prod` | Build Docker image → push to GCR → update Cloud Run Job → `dbt run --target prod` → `dbt test --target prod` |

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `GCP_PROJECT` | GCP project ID |
| `GCP_SA_KEY` | Service account JSON key |
| `DOG_API_KEY` | The Dog API key |

---

## Findings (≤300 words)

Our analysis of 169 dog breeds reveals that weight is the strongest predictor of life span. Small breeds live approximately 3.4 years longer than giant breeds on average (13.5 vs 10.1 years). Toy and Terrier groups dominate the longevity charts, with several breeds exceeding 15-year average spans.

The most popular family-friendly temperaments (Loyal, Friendly) correlate with shorter life spans, but this is a size confound — the friendliest breeds (Labrador, Golden Retriever, German Shepherd) tend to be large, and large breeds live shorter lives. This is not causation.

Weight is more predictive than breed group alone. A pet insurance company could use this curated layer to price policies by weight class rather than breed name, identify long-lived small breeds for targeted marketing, and flag data quality gaps to prioritise which breeds need manual enrichment.

67% of breeds lack complete weight, height, and life span data, suggesting the free API tier has significant gaps that would need enrichment for production use. Our `has_complete_metrics` flag in the fact table makes this transparent to downstream consumers.

**Business applications:**

- **Pet insurance pricing:** Insurers could use weight class as a primary rating factor rather than breed names, simplifying underwriting while maintaining actuarial accuracy. A Small-breed policy could be priced 15–20% lower than a Giant-breed policy.
- **Breed recommendation engines:** Pet adoption platforms could match families with breeds that fit their lifestyle and longevity expectations.
- **Veterinary planning:** Clinics can personalise wellness programmes — earlier screening for large/giant breeds, extended preventive care for smaller breeds expected to live 13+ years.

These findings are based on the free tier of The Dog API. Production use should validate against veterinary databases such as OFA or AKC registration data.

---

## Trade-offs

| Decision | Trade-off | Future |
|----------|-----------|--------|
| Cloud Run Job vs Cloud Function | More setup, but better for Docker flexibility | Could simplify to Cloud Function |
| dbt Core vs dbt Cloud | Free, full control; no GUI | Evaluate dbt Cloud for team use |
| replace write disposition | Re-loads all data each run | Switch to merge if API supports incremental |
| OAuth for dbt, SA key for dlt | Two auth methods | Unify with Workload Identity Federation |
| Terraform for core IaC | Cloud Run Job not in Terraform (requires image to exist first) | Add Cloud Run job resource after first image push |
