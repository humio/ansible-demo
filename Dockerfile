FROM ubuntu:19.10

RUN apt -y update && apt-get -y install python python3 openssh-client git iproute2 python3-pip curl
RUN pip3 install ansible==2.8.2 requests apache-libcloud

# Install Google Cloud SDK
RUN CLOUDSDK_PYTHON=/usr/local/bin/python curl https://sdk.cloud.google.com | bash

RUN mkdir -p /etc/ansible

COPY ./gcp/ansible.cfg ./gcp/entrypoint.sh gcp/gce.py gcp/requirements.yml /etc/ansible/
COPY ./gcp/group_vars /etc/ansible/group_vars

RUN chmod 755 /etc/ansible/gce.py
RUN rm /usr/bin/python && ln -s /usr/bin/python3.7 /usr/bin/python

RUN ansible-galaxy install -r /etc/ansible/requirements.yml

ENV PYTHON_PATH /usr/local/lib/python3.7/dist-packages

COPY ./gcp/site.yml /etc/ansible/

ENTRYPOINT ["/etc/ansible/entrypoint.sh"]
