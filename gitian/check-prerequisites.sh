#!/bin/sh

# list the checks here - versions, etc

if [ ! -f /etc/debian_version ];
then
  echo "Gitian is dependent upon the Ubuntu Virtualization Tools."
  echo
  echo "You need to run Ubuntu 12.04 LTS/Debian Wheezy or newer."
  exit 1
fi

DISTRO=`cat /etc/issue | grep -Eo 'Ubuntu|Debian*'`

if [ $DISTRO = "Ubuntu" ];
then
  dpkg -s ruby apache2 git apt-cacher-ng python-vm-builder qemu-kvm virt-what lxc lxctl fakeroot faketime zip unzip subversion torsocks tor 2>/dev/null >/dev/null

  if [ $? -ne 0 ];
  then
    echo "You are missing one or more Gitian build tool dependencies."
    echo
    echo "Please run:"
    echo " sudo apt-get install torsocks tor"
    echo " sudo torsocks apt-get install ruby apache2 git apt-cacher-ng python-vm-builder qemu-kvm virt-what lxc lxctl fakeroot faketime zip unzip subversion"
    exit 1
  fi
elif [ $DISTRO = "Debian" ];
then
  dpkg -s ruby git apt-cacher-ng qemu-kvm virt-what lxc lxctl fakeroot zip unzip torsocks tor python-cheetah debootstrap parted kpartx rsync 2>/dev/null >/dev/null

  if [ $? -ne 0 ];
  then
    echo "You are missing one or more Gitian build tool dependencies."
    echo
    echo "Please run"
    echo " sudo apt-get install torsocks tor"
    echo " sudo torsocks apt-get install ruby git apt-cacher-ng qemu-kvm virt-what lxc lxctl fakeroot zip unzip python-cheetah debootstrap parted kpartx rsync"
    exit 1
  fi

  # python-vm-builder is special as we don't have a Debian package for it.
  vmbuilder --help 2>/dev/null >/dev/null
  if [ $? -ne 0 ];
  then
    echo "The VM tool python-vm-builder is missing."
    echo
    echo "Please run"
    echo 'torsocks wget -U "" http://archive.ubuntu.com/ubuntu/pool/universe/v/vm-builder/vm-builder_0.12.4+bzr489.orig.tar.gz'
    echo 'echo "ec12e0070a007989561bfee5862c89a32c301992dd2771c4d5078ef1b3014f03  vm-builder_0.12.4+bzr489.orig.tar.gz" | sha256sum -c'
    echo "# (verification -- must return OK)"
    echo "tar -zxvf vm-builder_0.12.4+bzr489.orig.tar.gz"
    echo "cd vm-builder-0.12.4+bzr489"
    echo "sudo python setup.py install"
    echo "cd .."
    exit 1
  fi
else
  echo "We need Debian or Ubuntu which seem to be missing. Aborting."
  exit 1
fi

update_responses_pkg="libyaml-perl libfile-slurp-perl libxml-writer-perl libio-captureoutput-perl libfile-which-perl libparallel-forkmanager-perl libxml-libxml-perl libwww-perl"
missing_pkg=''
for pkg in $update_responses_pkg
do
    if ! dpkg -s $pkg 2>/dev/null >/dev/null
    then
        missing_pkg="$missing_pkg $pkg"
    fi
done
if [ -n "$missing_pkg" ]
then
    echo "You are missing one or more dependencies for the update_responses script"
    echo "Please run"
    echo " sudo apt-get install $missing_pkg"
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

if [ $DISTRO = "Debian" ];
then
    kvm_ok=../tools/kvm-ok
else
    kvm_ok=kvm-ok
fi
$kvm_ok > /dev/null
if [ $? -ne 0 -a "z$USE_LXC" != "z1" ];
then
  $kvm_ok
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
  if [ $DISTRO = "Debian" ];
  then
    libvirt_group=libvirt
  else
    libvirt_group=libvirtd
  fi
  groups | grep $libvirt_group > /dev/null
  if [ $? -ne 0 ];
  then
    echo "You need to be in the $libvirt_group group to run Gitian."
    echo
    echo "Please run:"
    echo " sudo adduser $USER $libvirt_group"
    echo " newgrp $libvirt_group"
    exit 1
  fi
  if [ -z "$DISPLAY" ];
  then
    groups | grep kvm > /dev/null
    if [ $? -ne 0 ];
    then
      echo "You need to be in the kvm group to run Gitian on a headless server."
      echo
      echo "Please run:"
      echo " sudo adduser $USER kvm"
      echo " newgrp kvm"
      exit 1
    fi
  fi
fi


exit 0
