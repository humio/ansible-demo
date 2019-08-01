data "google_storage_project_service_account" "gcs_account" {}

resource "google_kms_key_ring" "humio" {
  name     = "humio-key-ring"
  location = "${var.region}"
}

resource "google_kms_crypto_key" "humio" {
  name            = "humio-key"
  key_ring        = "${google_kms_key_ring.humio.self_link}"
  rotation_period = "100000s"

  lifecycle {
    prevent_destroy = false # Change to true to prevent accidental destruction of KMS key
  }
}

resource "google_kms_crypto_key_iam_binding" "encrypter_decrypter" {
  crypto_key_id = "${google_kms_crypto_key.humio.self_link}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

resource "google_kms_crypto_key_iam_binding" "read" {
  crypto_key_id = "${google_kms_crypto_key.humio.self_link}"
  role          = "roles/viewer"

  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}
