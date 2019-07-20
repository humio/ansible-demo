#!/usr/bin/env bash

set -eu

declare -r ssh_dir=$HOME/.ssh
declare -r authorized_keys=${AUTHORIZED_KEYS_FILE:-/tmp/authorized_keys}
declare -r ssh_key=$ssh_dir/id_rsa
declare -r playbook=/etc/ansible/site.yml
declare -r ip_address=$(python -c 'import requests; print(requests.get("http://metadata.google.internal/computeMetadata/v1beta1/instance/network-interfaces/0/ip", timeout=5).content.decode("utf-8"))')

generate_ssh_key () {
  ssh-keygen -f $ssh_key -N '' -q
}

copy_public_ssh_key_to_authorized_keys () {
  cat ${ssh_key}.pub >> $authorized_keys
}

run_ansible () {
  ansible-playbook $playbook -l $ip_address -vvv
}

register_eth0 () {
  ip addr show eth0 | grep "inet " | cut -d / -f1 | awk '{ print $2 }'
}

generate_ssh_key
copy_public_ssh_key_to_authorized_keys
run_ansible
