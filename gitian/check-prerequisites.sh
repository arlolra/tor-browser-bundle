#!/bin/sh

# list the checks here - versions, etc

if [ ! -f /etc/debian_version ];
then
  echo "Gitian is dependent upon the Ubuntu Virtualization Tools."
  echo
  echo "You need to run Ubuntu 12.04 LTS or newer."
  exit 1
fi

dpkg -s ruby apache2 git apt-cacher-ng python-vm-builder qemu-kvm virt-what lxc lxctl 2>/dev/null >/dev/null

if [ $? -ne 0 ]; then
  echo "You are missing one or more virtualization tool dependencies."
  echo
  echo "Please run:"
  echo " sudo apt-get install ruby apache2 git apt-cacher-ng python-vm-builder qemu-kvm virt-what lxc lxctl"
  exit 1
fi

if [ ! -f ../../gitian-builder/bin/gbuild ];
then
  echo "Gitian not found. You need a Gitian checkout in ../../gitian-builder"
  echo
  echo "Please run:"
  echo " cd ../../ "
  echo " git clone https://git.torproject.org/user/mikeperry/gitian-builder.git"
  echo " cd gitian-builder"
  echo " git checkout tor-browser-builder"
  exit 1
fi

fakeroot virt-what
if [ $? -ne 0 -a "z$USE_LXC" != "z1" ];
then
  echo "You appear to be running in a virtual machine."
  echo "It is recommended you use LXC instead of KVM."
  echo
  echo "Please run: "
  echo " export USE_LXC=1"
  exit 1
fi

exit 0
