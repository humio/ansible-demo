# GCP Instructions

# Requirements

 * Install terraform binary (per terraform docs)
 * Setup, make a service account and get json credentials if you don't have them: https://developers.google.com/identity/protocols/OAuth2ServiceAccount#creatinganaccount

Many required variables are only in the override until the rest is documented, example provided.

# Installation

Run terraform apply to provision the cluster.

```
terraform apply
```

Once the cluster is provisioned, you will need to configure saml settings. See https://docs.humio.com/configuration/authentication/ for instructions. Once the right IDs and Secrets are collected, they will need to be added to the cluster via environment variables. To make this easier, we load these environment variables from an encrypted gcs bucket. Here are the steps:

1) Save the environment variables to a file named `saml-config.txt`. If configuring `SAML_IDP_CERTIFICATE`, set the
value to `/etc/ansible/saml/saml-cert.pem`.
2) Upload the `saml-config.txt` file to the bucket created by terraform, called `<project name>-saml`
3) Save the saml IDP certificate as a file named `saml-cert.pem`
4) Upload the `saml-cert.pem` file to the same bucket.
5) Restart the humio nodes:
```
for i in {01..12}; do terraform-11 taint google_compute_instance_from_template.humio${i}; done
terraform apply
```
