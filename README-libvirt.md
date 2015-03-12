KVM (libvirt) support for Linux
===============================

Here are some notes to install and run VMs on KVM and Mint.  

First to build the packer stuff, we need to install these packes:

```sh
$ sudo apt-get install qemu-system qemu-utils libvirt-bin virt-manager python-spice-client-gtk virt-viewer
```

Make and load the boxes you want (note that rake load will build the boxes as needed):
```sh
$ rake build:kvm:all
$ rake load:kvm:all
```

Then, make sure to run the latest vagrant, at least 1.7.2, and install the necessary plugin:

```sh
$ vagrant plugin install vagrant-libvirt
```

you will need the following packages to use synced folders:

```sh
$ sudo apt-get install nfs-kernel-server
```

Test your new VMs:

```sh
$ rake up:kvm:windows-2012R2-full-standard-eval
```
or
```sh
$ cd spec && BOX=windows-2012R2-full-standard-eval vagrant up --provider=libvirt
```

And you are good to go!
