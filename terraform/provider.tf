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
  project = "affable-elf-472819-k2"
  region  = "us-central1"
  zone    = "us-central1-a"
}