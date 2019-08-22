# Provision Humio on Microsoft Azure

Requirements
* [Microsoft Azure](https://portal.azure.com) account, including
  * [Microsoft Azure CLI](https://github.com/Azure/azure-cli)
* [Terraform](https://www.terraform.io/intro/getting-started/install.html)
* [Ansible](https://docs.ansible.com/ansible/2.8/installation_guide/intro_installation.html)

## Getting started

Make sure you have logged in using the Azure CLI and the path to your SSH public key:

```bash
az login
az account set --subscription "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export TF_VAR_ssh_key_data=$(< ~/.ssh/id_rsa.pub)
export TF_VAR_azure_resource_group=humio-ansible-demo
```

Initialise the workspace

```bash
terraform init
```

With that, Terraform is ready to spin up a new environment

```bash
terraform apply
```

In this demo we will configure the following parts
* Virtual network
* Two subnets
  * `frontend` for frontend IP of application gateway
  * `internal` for virtual machines
* Public IP's
  * `ui` for frontend IP of application gateway
  * `main`, one per virtual machine for providing SSH access everywhere
* Virtual machines
  * 3 primary nodes with Zookeeper, Kafka and Humio
  * (optional) 3 secondary nodes with Kafka and Humio
* Network security group
  * Assigned to all VM NIC's to only allow Kafka/Zookeeper traffic within the virtual network
* Application gateway
  * Exposes port 80 using round-robin load balancing with stickyness for accessing the UI.
  * Exposes port 8080 and 9200 using round-robin load balancing for data ingest

## Provisioning Humio

First, make sure you have the required Ansible Galaxy roles installed and the Azure SDK modules.

```bash
ansible-galaxy install --role-file=requirements.yml
pip install "ansible[azure]" azure-cli --user
```

Finally, the cluster can be provisioned with the `site.yml` playbook

```bash
ansible-playbook site.yml
```

Once the cluster is up and running, the Humio web interface should be available using the ui load balancer directly or the public IP's dedicated to each machine. Bare in mind it can take a few minutes before the nodes are deemed healthy by the probe defined on the application gateway.

```bash
open $(terraform output "humio_ui")
```
