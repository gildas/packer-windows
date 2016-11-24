#!/bin/bash -euxo pipefail

HOME_DIR="${HOME_DIR:-/home/vagrant}"

case "$PACKER_BUILDER_TYPE" in
  parallels-iso|parallels-pvm)
    mount -o loop "$HOME_DIR/prl-tools-lin.iso" /mnt
    VER="$(cat /mnt/parallels/version)"
    echo "Installing Parallels Desktop Tools version $VER"

    /mnt/parallels/install --install-unatttended-with-deps \
      || (status="$?" ; \
          echo "Parallels Desktop Tools installation failed. Error: $status" ; \
          cat /var/log/parallels-tools-install.log ; \
          exit $status)
    umount /mnt
    rm -rf "$HOME_DIR/prl-tools-lin.iso"
  ;;
  virtualbox-iso|virtualbox-ovf)
    mount -o loop "$HOME_DIR/VBoxGuestAdditions.iso" /mnt
    VER="$(cat $HOME_DIR/.vbox_version)"
    echo "Installing Virtualbox Tools version $VER"

    sh /mnt/VBoxLinuxAdditions.run \
      || (status="$?" ; \
          echo "Virtualbox Tools installation failed. Error: $status" ; \
          exit $status)
    umount /mnt
    rm -rf "$HOME_DIR/VBoxGuestAdditions.iso"
    ;;
  vmware-iso|vmware-vmx)
    mount -o loop $HOME_DIR/linux.iso /mnt;
    mkdir -p /tmp/vmware;

    TOOLS_PATH="$(ls /mnt/VMwareTools-*.tar.gz)";
    VER="$(echo "${TOOLS_PATH}" | cut -f2 -d'-')";
    MAJ_VER="$(echo ${VER} | cut -d '.' -f 1)";

    echo "VMware Tools installation version $VER";

    tar xzf ${TOOLS_PATH} -C /tmp/vmware;
    if [ "${MAJ_VER}" -lt "10" ]; then
        /tmp/vmware/vmware-tools-distrib/vmware-install.pl --default;
    else
        /tmp/vmware/vmware-tools-distrib/vmware-install.pl --force-install;
    fi
    yum install -y open-vm-tools;
    mkdir /mnt/hgfs;
    umount /mnt;
    rm -rf /tmp/vmware;
    rm -f $HOME_DIR/linux.iso;
    ;;
esac
