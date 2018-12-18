#!/bin/bash
set -euxo pipefail

  instance_type = "i3.4xlarge"

# Install ZFS
apt-get -qqy install zfsutils-linux
modprobe zfs

# Combine the EBS drives into a pool of storage.
POOL=tank
EBS_DEVS="xvdc xvdd xvde xvdg"
EPH_DEVS="nvme0n1 nvme1n1"
zpool create ${POOL} -f \
    -o ashift=12 \
    -O atime=off \
    -O compression=lz4 \
    -O redundant_metadata=most \
    -O normalization=formD \
    -O recordsize=1M \
    -O xattr=off \
    ${EBS_DEVS} \
    cache ${EPH_DEVS}

# Remove default systemd ZFS-related services, they don't handle host migration.
for f in $(find /lib/systemd/ | grep zfs); do rm -f $f; done
for f in $(find /etc/systemd/ | grep zfs); do rm -f $f; done
rm -f /etc/systemd/system/zed.service
rm -f /lib/systemd/system/zed.service
rm -f /lib/systemd/system/zfs-import.service
rm -f /lib/systemd/system/ephemeral-disk-warning.service

cat > /lib/systemd/system/zfs.service <<EOF
[Unit]
DefaultDependencies=no
Before=local-fs.target

[Service]
Type=simple
ExecStartPre=/sbin/modprobe zfs
ExecStartPre=-/sbin/zpool import -a
ExecStartPre=/sbin/zfs mount -a
ExecStartPre=-/sbin/zpool remove tank nvme0n1 nvme1n1
ExecStartPre=/sbin/zpool add data cache  nvme0n1 nvme1n1 -f
ExecStart=/usr/bin/zed -F
Restart=always
EOF

cat > /etc/modprobe.d/zfs.conf <<EOF
options zfs zfs_arc_max=23061876736
options zfs zfs_arc_meta_limit=838860800
options zfs l2arc_write_max=536870912
options zfs l2arc_write_boost=134217728
options zfs l2arc_headroom=4
options zfs l2arc_headroom_boost=16
options zfs l2arc_norw=0
options zfs l2arc_feed_again=1
options zfs l2arc_feed_min_ms=5
options zfs l2arc_noprefetch=0
#options zfs zfs_dirty_data_max=5368709120
#options zfs zfs_dirty_data_sync=134217728
options zfs zfs_vdev_async_read_max_active=30 #was 3
options zfs zfs_vdev_async_write_max_active=100 #was 10
options zfs zfs_vdev_sync_read_max_active=100 #was 10
options zfs zfs_vdev_sync_write_max_active=100 #was 10
options zfs zfs_vdev_max_active=4000 #was 1000
EOF

sudo zfs create -o canmount=off -o setuid=off -o exec=off tank/var
sudo zfs create -o com.sun:auto-snapshot=false -o setuid=off -o mountpoint=/var/humio tank/var/humio
sudo zfs create -o com.sun:auto-snapshot=false -o setuid=off -o mountpoint=/var/kafka tank/var/kafka
sudo zfs create -o com.sun:auto-snapshot=false -o setuid=off -o mountpoint=/var/lib/zookeeper tank/var/zookeeper

# resource "aws_instance" "zk-kafka-humios" {
#  provisioner "local-exec" {
#    command = <<USERDATA
#USERDATA
#  }

# /var/humio
# /var/kafka
# /var/lib/zookeeper
