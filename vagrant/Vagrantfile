# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false
  config.vm.box = "bento/centos-7.5"

  config.vm.provider "vmware_desktop" do |v|
    v.vmx["memsize"] = "4096"
    v.vmx["numvcpus"] = "1"
  end

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "cluster.yml"
    ansible.groups = {
        "zookeepers" => ["default"],
        "kafkas" => ["default"],
        "humios" => ["default"]
    }
    ansible.host_vars = {
        "default" => { "zookeeper_id" => 0, "kafka_broker_id" => 0 }
    }
  end
end