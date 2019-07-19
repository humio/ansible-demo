terraform {
  backend "gcs" {
    bucket      = "nyc3-poc-remote-state"
    prefix      = "terraform/state/nyc3-poc"
    credentials = "./service-account.json"
  }
}
