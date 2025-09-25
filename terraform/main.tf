
# HABILITAR APIs NECESSÁRIAS


resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "iam.googleapis.com",
    "monitoring.googleapis.com",
    "cloudscheduler.googleapis.com",
    "dataflow.googleapis.com"
  ])
  
  service = each.value
  disable_on_destroy = false
}


# STORAGE BUCKETS


# Bucket para dados raw
resource "google_storage_bucket" "raw_data" {
  name     = "${var.project_id}-raw-data"
  location = var.region
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.required_apis]
}

# Bucket para dados processados
resource "google_storage_bucket" "processed_data" {
  name     = "${var.project_id}-processed-data"
  location = var.region
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }

  depends_on = [google_project_service.required_apis]
}

# Bucket para estado do Terraform
resource "google_storage_bucket" "terraform_state" {
  name     = "${var.project_id}-terraform-state"
  location = var.region
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }

  depends_on = [google_project_service.required_apis]
}


# BIGQUERY


resource "google_bigquery_dataset" "main_dataset" {
  dataset_id = "ena_data"
  location   = var.region
  
  description = "Dataset principal para dados ENA"
  
  delete_contents_on_destroy = false

  depends_on = [google_project_service.required_apis]
}

# Tabela para dados históricos
resource "google_bigquery_table" "historical_data" {
  dataset_id = google_bigquery_dataset.main_dataset.dataset_id
  table_id   = "historical_ena"
  
  deletion_protection = false
  
  schema = jsonencode([
    {
      name = "date"
      type = "DATE"
      mode = "REQUIRED"
    },
    {
      name = "reservoir_id"
      type = "STRING" 
      mode = "REQUIRED"
    },
    {
      name = "volume"
      type = "FLOAT"
      mode = "NULLABLE"
    },
    {
      name = "percentage"
      type = "FLOAT"
      mode = "NULLABLE"
    },
    {
      name = "created_at"
      type = "TIMESTAMP"
      mode = "REQUIRED"
    }
  ])
  
  time_partitioning {
    type  = "DAY"
    field = "date"
  }
}


# SERVICE ACCOUNTS


# Service Account para Cloud Run
resource "google_service_account" "cloud_run_sa" {
  account_id   = "cloud-run-sa"
  display_name = "Cloud Run Service Account"

  depends_on = [google_project_service.required_apis]
}

# Permissões para acessar BigQuery
resource "google_project_iam_member" "cloud_run_bigquery" {
  project = var.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Permissões para acessar Storage
resource "google_project_iam_member" "cloud_run_storage" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}