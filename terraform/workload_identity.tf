# Workload Identity Pool
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Pool"
  description               = "Pool para GitHub Actions"

  depends_on = [google_project_service.required_apis]
}

# Workload Identity Provider
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"
  
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == 'danieladosanjos/proj-sauter-hydro-forecast'"
  
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Service Account para Terraform
resource "google_service_account" "terraform_sa" {
  account_id   = "terraform-sa"
  display_name = "Terraform Service Account"

  depends_on = [google_project_service.required_apis]
}

# Permissões para o Service Account do Terraform
resource "google_project_iam_member" "terraform_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.terraform_sa.email}"
}

# Bind do Workload Identity
resource "google_service_account_iam_binding" "workload_identity" {
  service_account_id = google_service_account.terraform_sa.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/danieladosanjos/proj-sauter-hydro-forecast"
  ]
}