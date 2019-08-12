# Provision Humio on Bare Metal machines

## Prerequisites

Before you begin, make sure your new bare metal Humio host machines
meet the following criteria:

* SSH public key added to the `authorized_keys` file for the user
  you're using to run ansible with (this is `root` by default) on all
  Humio host machines.
* The `python3` package should be installed on all Humio host machines.
* Ansible 2.6 or higher installed on the machine you're running the
  ansible playbook from.

## Update configuration files

###  Modify the inventory.ini file

Edit the `inventory.ini` file so it reflects your bare metal cluster.
The file is annotated to help explain what needs to be changed.

### Modify the group_vars/all.yml file

Update the `humio_network_interface` variable to reflect the name of
your Humio host machine's network interface. To find that, run `ifconfig`
on your remote host. That might look something like this:

```
$ ifconfig
enp0s3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.0.11  netmask 255.255.255.0  broadcast 10.0.0.255
        inet6 fe80::74:f0ff:fec0:9d60  prefixlen 64  scopeid 0x20<link>
        ether 02:74:f0:c0:9d:60  txqueuelen 1000  (Ethernet)
        RX packets 36563  bytes 38437702 (38.4 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 12139  bytes 960165 (960.1 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 186  bytes 19332 (19.3 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 186  bytes 19332 (19.3 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

In the above case, you would set `humio_network_interface` to `enp0s3`.
The actual name of the interface will vary. Just make sure you use the
interface name that's for the IP you're specifying in the `inventory.ini`
file.

## Install the Ansible roles

Before running ansible, the roles defined in the `requirements.yml` file
need to be installed. To do this, run:

```
ansible-galaxy install -r requirements.yml
```

The roles will be installed to `~/.ansible/roles`. These roles will
periodically be updated. To replace the installed roles with updated
ones, run the command above with the `--force` parameter.

## Run the playbook

Finally, run the playbook:

```
ansible-playbook site.yml
```
