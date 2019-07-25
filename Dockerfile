FROM ubuntu:19.10

RUN apt -y update && apt-get -y install python3 openssh-client git iproute2 python3-pip
RUN pip3 install ansible==2.8.2 requests apache-libcloud

RUN mkdir -p /etc/ansible

COPY ./gcp/ansible.cfg ./gcp/entrypoint.sh gcp/gce.py gcp/group_vars gcp/requirements.yml /etc/ansible/

RUN chmod 755 /etc/ansible/gce.py
RUN ln -s /usr/bin/python3.7 /usr/bin/python

RUN ansible-galaxy install -r /etc/ansible/requirements.yml

ENV PYTHON_PATH /usr/local/lib/python3.7/dist-packages

COPY ./gcp/site.yml /etc/ansible/

ENTRYPOINT ["/etc/ansible/entrypoint.sh"]
