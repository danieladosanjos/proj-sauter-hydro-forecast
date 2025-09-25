terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
<<<<<<< HEAD
  project = "affable-elf-472819-k2"
  region  = "us-central1"
  zone    = "us-central1-a"
=======
  project = "project-sauter-hydro-forecast"
  region  = "us-central1"
  zone    = "us-central1-a"
}

data "google_project" "project" {
  project_id = "project-sauter-hydro-forecast"
>>>>>>> repo-origin/main
}