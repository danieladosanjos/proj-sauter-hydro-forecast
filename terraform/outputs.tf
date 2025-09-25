output "project_id" {
  description = "ID do projeto"
<<<<<<< HEAD
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

output "workload_identity_provider" {
  description = "Workload Identity Provider"
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

output "terraform_sa_email" {
  description = "Email do service account do Terraform"
  value       = google_service_account.terraform_sa.email
}
output "api_service_url" {
  description = "URL da API no Cloud Run"
  value       = google_cloud_run_v2_service.api_service.uri
=======
  value       = data.google_project.project.project_id
}

output "project_number" {
  description = "Número do projeto"
  value       = data.google_project.project.number
}

output "workload_identity_provider" {
  description = "Provider para GitHub"
  value       = "projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_pool.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.github_provider.workload_identity_pool_provider_id}"
}

output "github_service_account_email" {
  description = "Email da SA do GitHub"
  value       = google_service_account.github_actions_sa.email
>>>>>>> repo-origin/main
}