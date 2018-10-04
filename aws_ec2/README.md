# Provision Humio on Amazon Webservices EC2

Requirements
* [Amazon Webservices](https://aws.amazon.com) account, including
  * Your AWS [access key](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html)
* [Terraform](https://www.terraform.io/intro/getting-started/install.html)
* [Ansible](https://docs.ansible.com/ansible/2.5/installation_guide/intro_installation.html)

## Getting started

## Spinning up a new environment

We are still working on script for spinning up a machines with Terraform, so for now this is a manual process.

A quick walkthrough for creating machines

1. Create the number of EC2 Ubuntu machines you prefer. Recommended is at least 3 nodes. Make sure you have SSH access to the machines.
2. Add a `cluster_index` tag with a consecutive number starting from 1 as the value to each machine.
3. Create the following three security groups:
  * zookeepers, allowing incoming traffic on port 2181/TCP, 2888/TCP, and 3888/TCP from private IPs
  * kafkas, allowing incoming traffic on port 9092/TCP from private IPs
  * humios, alkowing incoming traffic on port 8080/TCP from private IPs
4. Add the first three machines to the _zookeepers_ security group.
5. Add all machines to the _kafkas_ and _humios_ security groups.

## Provisioning Humio

First, make sure you have the required Ansible Galaxy roles installed and [Boto3](https://github.com/boto/boto3).

```bash
ansible-galaxy install --role-file=requirements.yml
pip install boto3 --user
```

Second, the two required environment variables for `ec2.py` dynamic inventory script should be configured with your access key
```bash
export AWS_ACCESS_KEY_ID='AK123'
export AWS_SECRET_ACCESS_KEY='abc123'
``` 

Finally, the cluster can be provisioned with the `site.yml` playbook

```bash
ansible-playbook site.yml
```

Once the cluster is up and running, the Humio web interface should be available on TCP port 8080 of any of the hosts in the `tag_humios` group,

```bash
open http://$(./ec2.py | jq -r '.security_group_humios[0]'):8080
```