// Configure the Google Cloud provider
provider "google" {
 credentials = "${file(var.gcp_credentials)}"
 project     = "${var.gcp_project_id}"
 region      = "${var.region}"
}







