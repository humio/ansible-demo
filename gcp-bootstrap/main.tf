provider "google" {
  credentials = "${file("${var.credentials_file}")}"
  project     = "${var.gcp_project_id}"
}

resource "google_storage_bucket" "bucket" {
  name = "${var.gcp_project_id}-remote-state"

  versioning {
    enabled = true
  }
}

output "bucket_name" {
  value = "${google_storage_bucket.bucket.name}"
}
