variable "gcp_project_id" {
  default = "nyc3-poc"
}

# creds.json file
variable "credentials_file" {}

variable "region" {
  type = "string"
  default = "us-central1"
}
