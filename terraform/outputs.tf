output "pipeline_service_account" {
  description = "Service account email used by the pipeline"
  value       = google_service_account.pipeline_sa.email
}

output "raw_bucket_url" {
  description = "GCS bucket for raw JSON snapshots"
  value       = "gs://${google_storage_bucket.raw.name}"
}

output "bigquery_datasets" {
  description = "BigQuery dataset IDs"
  value = {
    bronze = google_bigquery_dataset.bronze.dataset_id
    silver = google_bigquery_dataset.silver.dataset_id
    gold   = google_bigquery_dataset.gold.dataset_id
  }
}
