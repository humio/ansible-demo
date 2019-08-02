resource "google_storage_bucket" "humio_saml" {
  name    = "humio-saml"
  project = "${var.gcp_project_id}"
  location = "${var.region}"

  force_destroy = true

  encryption = {
    default_kms_key_name = "${data.google_kms_crypto_key.humio.self_link}"
  }

  versioning {
    enabled = false
  }

  bucket_policy_only = true
}

resource "google_storage_bucket_iam_binding" "binding" {
  bucket = "${google_storage_bucket.humio_saml.name}"
  role   = "roles/storage.objectViewer"

  members = [
    "serviceAccount:${google_service_account.default.email}",
  ]
}

resource "google_storage_bucket_iam_binding" "users" {
  bucket = "${google_storage_bucket.humio_saml.name}"
  role   = "roles/storage.objectAdmin"

  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

output "bucket_name" {
  value = "${google_storage_bucket.humio_saml.name}"
}
