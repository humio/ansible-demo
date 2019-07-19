# GCP Instructions

First steps, ubuntu
Install terraform binary (per terraform docs)
sudo apt-get install python-pip
sudo pip install requests google-auth apache-libcloud
Install ansible (https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#latest-releases-via-apt-ubuntu)
cd <ansible-demo/gcp/location> ansible-galaxy install --role-file=requirements.yml


Setup, make a service account and get json credentials if you don't have them:
https://developers.google.com/identity/protocols/OAuth2ServiceAccount#creatinganaccount

Many required variables are only in the override until the rest is documented, example provided.

More directions to come, for now to execute:
terraform apply

GCE_INIT_PATH=<your ini file pointing to the service account role.json> ansible-playbook -i ./gce.py site.yml
