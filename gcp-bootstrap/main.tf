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

# During initial provision, the kms key must be a resource. After that it is a datasource. Unfortunately,
# google doesn't allow the deletion of kms keys or key-rings, so we must do this (or delete and recreate the project
# completely).

resource "google_kms_key_ring" "humio" {
  name     = "humio-key-ring"
  location = "${var.region}"
}

resource "google_kms_crypto_key" "humio" {
  name            = "humio-key"
  key_ring        = "${data.google_kms_key_ring.humio.self_link}"
  rotation_period = "100000s"
}

output "bucket_name" {
  value = "${google_storage_bucket.bucket.name}"
}
