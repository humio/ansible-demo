resource "google_service_account" "default" {
  account_id   = "${var.gcp_project_id}-instance-account"
  display_name = "Instance Service Account"
}

data "google_iam_policy" "default" {
  binding {
    role = "Compute Viewer"

    members = [
      "serviceAccount:${google_service_account.default.email}",
    ]
  }
}

resource "google_service_account_key" "default" {
  service_account_id = "${google_service_account.default.name}"
  public_key_type    = "TYPE_X509_PEM_FILE"
}
