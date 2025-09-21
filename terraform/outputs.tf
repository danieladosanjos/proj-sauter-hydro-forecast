output "project_id" {
  description = "ID do projeto"
  value       = var.project_id
}

output "raw_data_bucket" {
  description = "Nome do bucket de dados raw"
  value       = google_storage_bucket.raw_data.name
}

output "processed_data_bucket" {
  description = "Nome do bucket de dados processados"
  value       = google_storage_bucket.processed_data.name
}

output "terraform_state_bucket" {
  description = "Nome do bucket do estado Terraform"
  value       = google_storage_bucket.terraform_state.name
}

output "bigquery_dataset" {
  description = "ID do dataset BigQuery"
  value       = google_bigquery_dataset.main_dataset.dataset_id
}

output "cloud_run_sa_email" {
  description = "Email do service account do Cloud Run"
  value       = google_service_account.cloud_run_sa.email
}