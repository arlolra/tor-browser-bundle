#!/bin/sh

# list the checks here - versions, etc

if [ ! -f /etc/debian_version ];
then
  echo "Gitian is dependent upon the Ubuntu Virtualization Tools."
  echo
  echo "You need to run Ubuntu 12.04 LTS or newer."
  exit 1
fi

dpkg -s ruby apache2 git apt-cacher-ng python-vm-builder qemu-kvm virt-what lxc lxctl fakeroot faketime zip unzip subversion torsocks tor 2>/dev/null >/dev/null

if [ $? -ne 0 ]; then
  echo "You are missing one or more Gitian build tool dependencies."
  echo
  echo "Please run:"
  echo " sudo apt-get install torsocks tor"
  echo " sudo torsocks apt-get install ruby apache2 git apt-cacher-ng python-vm-builder qemu-kvm virt-what lxc lxctl fakeroot faketime zip unzip subversion"
  exit 1
fi

if [ ! -f ../../gitian-builder/bin/gbuild ];
then
  echo "Gitian not found. You need a Gitian checkout in ../../gitian-builder"
  echo
  echo "Please run:"
  echo " cd ../../ "
  echo " torsocks git clone -b tor-browser-builder-3 https://git.torproject.org/builders/gitian-builder.git"
  echo " cd -"
  exit 1
fi

kvm-ok > /dev/null
if [ $? -ne 0 -a "z$USE_LXC" != "z1" ];
then
  kvm-ok
  echo
  echo "Most likely, this means you will need to use LXC."
  echo
  echo "Please run this in your shell before each build: "
  echo " export USE_LXC=1"
  echo
  echo "Note that LXC requires a sudo invocation for each Gitian command. "
  echo "If you require LXC, you may wish to increase your sudo timeout, "
  echo "or simply run the build directly from a root shell. "
  exit 1
fi

if [ "z$USE_LXC" != "z1" ];
then 
  groups | grep libvirtd > /dev/null
  if [ $? -ne 0 ];
  then
    echo "You need to be in the libvirtd group to run Gitian."
    echo
    echo "Please run:"
    echo " sudo adduser $USER libvirtd"
    echo " newgrp libvirtd"
    exit 1
  fi
fi


exit 0
