terraform {
  backend "gcs" {
    bucket = "test-terraform001-bucket"
    prefix = "terraform/state"
  }
}



resource "google_cloud_run_service" "default" {
  name     = var.service_name
  location = var.region

  template {
    spec {
      containers {
        image = var.container_image

        ports {
          container_port = 5000
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service_iam_member" "noauth" {
  location = google_cloud_run_service.default.location
  project  = var.project_id
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers" # Public access. Change to IAM principal for private.
}

# Grant Artifact Registry Reader to Cloud Run default service account
# resource "google_project_iam_member" "artifact_registry_access" {
#   project = var.project_id
#   role    = "roles/artifactregistry.admin"
#   member  = "serviceAccount:${var.project_id}-compute@developer.gserviceaccount.com"
# }
