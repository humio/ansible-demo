# GCP Instructions

First steps

pip install requests google-auth apache-libcloud


(this is from scratch for now)
Setup, make a service account and get json credentials if you don't have them:
https://developers.google.com/identity/protocols/OAuth2ServiceAccount#creatinganaccount

More directions to come, for now to execute:
terraform plan
terraform apply
GCE_INIT_PATH=<your ini file that points to credentials.json> ansible -i ./gce.py --list