terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ── BigQuery datasets (medallion layers) ────────────────────────────────────

resource "google_bigquery_dataset" "bronze" {
  dataset_id = "bronze"
  location   = var.bq_location
  description = "Raw API payloads loaded by dlt"
}

resource "google_bigquery_dataset" "silver" {
  dataset_id = "silver"
  location   = var.bq_location
  description = "Cleaned and typed staging models"
}

resource "google_bigquery_dataset" "gold" {
  dataset_id = "gold"
  location   = var.bq_location
  description = "Mart models ready for reporting"
}

# ── Cloud Storage bucket for raw JSON snapshots ──────────────────────────────

resource "google_storage_bucket" "raw" {
  name          = var.raw_bucket_name
  location      = var.bq_location
  force_destroy = false

  uniform_bucket_level_access = true
}

# ── Service account for the pipeline ────────────────────────────────────────

resource "google_service_account" "pipeline_sa" {
  account_id   = "dog-pipeline-sa"
  display_name = "Dog Pipeline Service Account"
}

locals {
  pipeline_roles = [
    "roles/bigquery.dataEditor",
    "roles/storage.objectAdmin",
    "roles/run.invoker",
    "roles/run.developer",
    "roles/iam.serviceAccountUser",
    "roles/serviceusage.serviceUsageConsumer",
    "roles/artifactregistry.writer",
  ]
}

resource "google_project_iam_member" "pipeline_sa_roles" {
  for_each = toset(local.pipeline_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.pipeline_sa.email}"
}

# ── Cloud Scheduler job (daily 02:00 UTC) ───────────────────────────────────

resource "google_cloud_scheduler_job" "daily_ingest" {
  name      = "dog-breed-daily-ingest"
  region    = var.region
  schedule  = "0 2 * * *"
  time_zone = "UTC"

  http_target {
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/dog-breed-ingest:run"
    http_method = "POST"

    oauth_token {
      service_account_email = google_service_account.pipeline_sa.email
    }
  }
}
