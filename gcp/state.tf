terraform {
  backend "gcs" {
    bucket      = "${gcp_project_id}-remote-state"
    prefix      = "terraform/state/${gcp_project_id}"
    credentials = "${var.credentials_file}"
  }
}
