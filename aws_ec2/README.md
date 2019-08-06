# Provision Humio on Amazon Webservices EC2

Requirements
* [Amazon Webservices](https://aws.amazon.com) account, including
  * Your AWS [access key](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html)
* [Terraform](https://www.terraform.io/intro/getting-started/install.html)
* [Ansible](https://docs.ansible.com/ansible/2.5/installation_guide/intro_installation.html)

## Getting started

Make sure you have your AWS access keys, default region and the name of your key pair configured, i.e.

```bash
export AWS_ACCESS_KEY_ID="AK123"
export AWS_SECRET_ACCESS_KEY="abc123"
export AWS_DEFAULT_REGION="<aws region>"
export TF_VAR_aws_key_name="<aws key pair name>"
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
* VPC with an Internet Gateway
* A primary and secondary subnets
* Security groups
  * `main`, for providing SSH access everywhere
  * `zookeepers`, `kafkas`, `humios`, for internal communications and Ansible grouping
  * `ui-public`, `ingest-public` for UI and Ingest load balancers
* Application Load Balancers
  * `ui`, exposes port 80 round-robin load balancing with stickyness
  * `ingest`, exposes port 80 and 9200 round-robin load balancing
* Target groups
* Instances
  * 3 primary nodes with Zookeeper, Kafka and Humio
  * (optional) 5 secondary nodes with Kafka and Humio

## Provisioning Humio

First, make sure you have the required Ansible Galaxy roles installed and [Boto3](https://github.com/boto/boto3).

```bash
ansible-galaxy install --role-file=requirements.yml
pip install boto3 --user
```

Finally, the cluster can be provisioned with the `site.yml` playbook

```bash
ansible-playbook site.yml
```

Once the cluster is up and running, the Humio web interface should be on the ui load balancer. Bare in mind it can take up to 2 minutes before the nodes are deemed healthy by the Target Group

```bash
open $(terraform output "humio_ui")
```

## Selecting Operating System

The operating system can be controlled with the `aws_ami_filter` Terraform variable, which will select an image on the AWS AMI name.

### RedHat Enterprise Linux
```bash
export TF_VAR_aws_ami_filter="RHEL-7.5_HVM_GA-*-x86_64-1-Hourly2-GP2"
terraform apply
ansible-playbook -u ec2-user site.yml
```

### CentOS Linux

Bare in mind that for this particular AMI, you'll need to Accept Terms and Conditions

```bash
export TF_VAR_aws_ami_filter="CentOS Linux 7 x86_64 HVM EBS ENA 1805_01*"
terraform apply
# open the url printed in output and accept the T&Cs if you haven't already
terraform apply
ansible-playbook -u centos site.yml
```
