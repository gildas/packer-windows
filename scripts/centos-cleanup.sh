#!/bin/bash -euxo pipefail

# Get the distro ('redhat', 'centos', 'roaclelinux')
distro=$(rpm -qf --queryformat '%{NAME}' /etc/redhat-release | cut -f 1 -d '-')
# Remove Linux headers
yum -y remove gcc kernel-devel kernel-headers perl cpp
[[ $distro != 'redhat' ]] && yum -y clean all

# Remove Virtualbox specific files
rm -rf /usr/src/vboxguest* /usr/src/virtualbox-ose-guest*
rm -rf *.iso *.iso.? /tmp/vbox /home/vagrant/.vbox_version

# Cleanup log files
find /var/log -type f | while read f; do echo -ne '' > $f; done;

# remove under tmp directory
rm -rf /tmp/*

# remove interface persistent
rm -f /etc/udev/rules.d/70-persistent-net.rules

for ifcfg in $(ls /etc/sysconfig/network-scripts/ifcfg-*)
do
    if [ "$(basename ${ifcfg})" != "ifcfg-lo" ]
    then
        sed -i '/^UUID/d'   /etc/sysconfig/network-scripts/ifcfg-enp0s3
        sed -i '/^HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-enp0s3
    fi
done

# Whiteout root
dd if=/dev/zero of=/EMPTY bs=1M
rm -rf /EMPTY

# Whiteout /boot
dd if=/dev/zero of=/boot/EMPTY bs=1M
rm -rf /boot/EMPTY

# Whiteout swap
set +e
swapuuid="$(/sbin/blkid -o value -l -s UUID -t type=SWAP)"
case "$?" in
  2|0) ;;
  *)   exit 1 ;;
esac
set -e

if [[ -n $swapuuid ]]; then
  swappart="$(readlink -f /dev/disk/by-uuid/$swapuuid)"
  if [[ -n $swappart ]]; then
    /sbin/swapoff "$swappart"
    dd if=/dev/zero of="$swappart" bs=1M
    /sbin/mkswap -U "$swapuuid" "$swappart"
  fi
fi

sync
