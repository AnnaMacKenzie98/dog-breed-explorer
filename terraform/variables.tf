variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "dog-breed-explorer-am"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west1"
}

variable "bq_location" {
  description = "BigQuery dataset location"
  type        = string
  default     = "EU"
}

variable "raw_bucket_name" {
  description = "GCS bucket for raw JSON snapshots"
  type        = string
  default     = "dog-breed-explorer-am-raw"
}
