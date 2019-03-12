# Provision Humio on DigitalOcean

Requirements
* [DigitalOcean](https://digitalocean.com) account, including
  * Your DigitalOcean [access token](https://www.digitalocean.com/docs/api/create-personal-access-token/)
* [Terraform](https://www.terraform.io/intro/getting-started/install.html)
* [Ansible](https://docs.ansible.com/ansible/2.5/installation_guide/intro_installation.html)

## Getting started

Start by exporting your DigitelOcean access token, as the following environment variables, i.e.

```bash
export DIGITALOCEAN_TOKEN=EXAMPLEKEY
export DO_API_TOKEN=${DIGITALOCEAN_TOKEN}
```

Initialise the workspace

```bash
terraform init
```

Verify that the Terraform is able to communicate with DigitalOcean

```bash
terraform validate
terraform refresh
```

## Spinning up a new environment

The default configuration will spin up three nodes, all with
* Zookeeper
* Kafka
* Humio

To set up the environment run the following command

```bash
terraform apply
```

Verify the configuration and type `yes` into the console.
After a while (usually around 5 minutes) you will have 8 Droplets available in DigitalOcean running Humio.

## Provisioning Humio

First, make sure you have the required Ansible Galaxy roles installed

```bash
ansible-galaxy install --role-file=requirements.yml
```

Finally, the cluster can be provisioned with the `site.yml` playbook

```bash
ansible-playbook site.yml
```

Once the cluster is up and running, the Humio web interface should be available on through the load balancer.
