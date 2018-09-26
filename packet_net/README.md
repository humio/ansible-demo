# Provision Humio on packet.net

Requirements
* [packet.net](https://packet.net) account, including
  * Your packet.net [API key](https://www.packet.net/developers/api/)
* [Terraform](https://www.terraform.io/intro/getting-started/install.html)
* [Ansible](https://docs.ansible.com/ansible/2.5/installation_guide/intro_installation.html)

## Getting started

Start by exporting your packet.net API KEY, as the following environment variables, i.e.

```bash
export PACKET_API_TOKEN=Bfse9F24SFtfs423Gsd3ifGsd43sSdfs
export TF_VAR_packet_auth_token=${PACKET_API_TOKEN}
```

Initialise the workspace

```bash
terraform init
```

Verify that the Terraform is able to communicate with packet

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
After a while (usually around 5 minutes) you will have a new project in packet.net named Humio.

## Provisioning Humio

First, make sure you have the required Ansible Galay roles installed

```bash
ansible-galaxy install --role-file=requirements.yml
```



```bash
ansible-playbook site.yml
```