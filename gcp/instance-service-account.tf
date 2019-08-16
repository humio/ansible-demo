resource "google_service_account" "default" {
  account_id   = "${var.gcp_project_id}-instance-account"
  display_name = "Instance Service Account"
}

resource "google_service_account_key" "default" {
  service_account_id = "${google_service_account.default.name}"
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "google_project_iam_member" "default" {
  project = "${var.gcp_project_id}"
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.default.email}"
}

resource "google_project_iam_member" "bucket" {
  project = "${var.gcp_project_id}"
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.default.email}"
}
