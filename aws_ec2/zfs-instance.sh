#!/bin/bash
set -euxo pipefail

#instance_type = "c5d.4xlarge"
#sudo systemctl daemon-reload


bytes() {
    echo $1 | echo $((`sed 's/[ ]*//g;s/[bB]$//;s/^.*[^0-9gkmt].*$//;s/t$/Xg/;s/g$/Xm/;s/m$/Xk/;s/k$/X/;s/X/*1024/g'`))
}

# Returns a percentage of memory with jitter.
# examples:
#   HALF=$(mem .5) will be half the physical memory in bytes
#   AROUND_HALF=$(mem .5 .1) will be half the physical memory in bytes with a 1% variation (aka "jitter")
mem() {
    SEED=$RANDOM
    PCT=0
    JITTER=0
    OVERHEAD=0
    if [ $# -gt 0 ]; then
        PCT=${1:=0}
        if [ $# -eq 2 ]; then
            JITTER=$2
	    if [ $# -eq 3 ]; then
		OVERHEAD=$3
	    fi
        fi
    else
        echo 0
    fi
    echo $(bytes $(cat /proc/meminfo | awk -v pct=$PCT -v seed=$SEED -v jitter=$JITTER -v overhead=$OVERHEAD 'BEGIN{ srand(seed) } /MemTotal/{ p = sprintf("%.0f", (($2 - overhead) * pct) / 1024 ) } END{ if (jitter > 0) { printf("%.0f\n", p - rand() % jitter * p) } else { printf("%.0f\n", p ) } }')m)
}

blk() {
    BYTES=0
    for d in $@; do BYTES=$(($BYTES + $(blockdev --getsize64 /dev/$d))); done
    echo $BYTES
}


# Install ZFS
apt-get -qqy install zfsutils-linux
modprobe zfs

# Combine the EBS drives into a pool of storage.
POOL=tank
EBS_DEVS="xvda xvdc xvdd xvde xvdf"
EPH_DEVS="nvme0n1 nvme1n1"
SPARE_DEVS="xvdg"
zpool create ${POOL} raidz2 -f \
    -o ashift=16 \
    -o autoexpand=on \
    -o autoreplace=on \
    -o exec=off \
    -O logbias=throughput \
    -O atime=off \
    -O compression=lz4 \
    -O xattr=off \
    ${EBS_DEVS} \
    cache ${EPH_DEVS}

if [ "${SPARE_DEVS}x" -ne "x" ]; then
    for d in ${SPARE_DEVS}; do zpool add ${POOL} spare $d; done
fi

# Remove default systemd ZFS-related services, they don't handle host migration.
for f in $(find /lib/systemd/ | grep zfs); do rm -f $f; done
for f in $(find /etc/systemd/ | grep zfs); do rm -f $f; done
rm -f /etc/systemd/system/zed.service
rm -f /lib/systemd/system/zed.service
rm -f /lib/systemd/system/zfs-import.service
rm -f /lib/systemd/system/ephemeral-disk-warning.service

# Use 85% of the RAM available after taking into account the 1GiB for Kafka and 32GiB for Humio.
ARC_MAX=$(mem .85 0 $(bytes $((1 + 32))g))
# Use at most 1/4th of the available RAM in ARC for metadata.
ARC_META_LIMIT=$(($ARC_MAX *.25))
# L2ARC is the combined block size of all the available ephemeral drives.
L2ARC_SIZE=$(blk $EPH_DEVS)

cat > /lib/systemd/system/zfs.service <<EOF
[Unit]
DefaultDependencies=no
Before=local-fs.target

[Service]
Type=simple
ExecStartPre=/sbin/modprobe zfs
ExecStartPre=-/sbin/zpool import -a
ExecStartPre=/sbin/zfs mount -a
ExecStartPre=-/sbin/zpool remove $POOL} ${EPH_DEVS}
ExecStartPre=/sbin/zpool add ${POOL} cache ${EPH_DEVS} -f
ExecStart=/usr/bin/zed -F
Restart=always
EOF

cat > /etc/modprobe.d/zfs.conf <<EOF
# Determines the maximum size of the ZFS Adjustable Replacement Cache (ARC)
options zfs zfs_arc_max=${ARC_MAX}
options zfs zfs_arc_meta_limit=${ARC_META_LIMIT}
# This tunable limits the maximum writing speed onto l2arc. The default is 8MB/s. So depending on the type of cache drives that the system used, it is desirable to increase this limit several times. But remember not to crank it too high to impact reading from the cache drives.
# 2^29 or 512MiB
options zfs l2arc_write_max=536870912
#  This tunable increases the above writing speed limit after system boot and before ARC has filled up. The default is also 8MB/s. During the above period, there should be no read request on L2ARC. This should also be increased depending on the system.
# 2^27 or 128MiB
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
