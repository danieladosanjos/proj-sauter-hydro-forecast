# Cloud Run service para a API
resource "google_cloud_run_v2_service" "api_service" {
  name     = "ena-api"
  location = var.region
  
  template {
    service_account = google_service_account.cloud_run_sa.email
    
    containers {
      # Placeholder image - alo alo substituir é aqui 
      image = "gcr.io/cloudrun/hello"
      
      ports {
        container_port = 8080
      }
      
      env {
        name  = "PROJECT_ID"
        value = var.project_id
      }
      
      env {
        name  = "DATASET_ID"  
        value = google_bigquery_dataset.main_dataset.dataset_id
      }
      
      resources {
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
      }
    }
  }
  
  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }

  depends_on = [google_project_service.required_apis]
}

# Permitir acesso público ao Cloud Run
resource "google_cloud_run_v2_service_iam_binding" "public_access" {
  name     = google_cloud_run_v2_service.api_service.name
  location = google_cloud_run_v2_service.api_service.location
  role     = "roles/run.invoker"
  members  = ["allUsers"]
}