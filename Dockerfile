FROM ubuntu:18.04

RUN apt-get -y update && apt-get -y install ansible openssh-client git iproute2

COPY ./gcp /etc/ansible

RUN ansible-galaxy install -r /etc/ansible/requirements.yml

ENTRYPOINT ["/etc/ansible/entrypoint.sh"]
