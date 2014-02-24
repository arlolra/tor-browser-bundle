#!/bin/bash

. ./versions

WRAPPER_DIR=$PWD
GITIAN_DIR=$PWD/../../gitian-builder
DESCRIPTOR_DIR=$PWD/descriptors/

if [ ! -f $GITIAN_DIR/bin/gbuild ];
then
  echo "Gitian not found. You need a Gitian checkout in $GITIAN_DIR"
  exit 1
fi

if [ -z "$NUM_PROCS" ];
then
  export NUM_PROCS=2
fi

cd $GITIAN_DIR
export PATH=$PATH:$PWD/libexec

build_and_test_vm() {
  local dist="$1"; shift
  local arch="$1"; shift
  local bits="$1"; shift

  if [ ! -f ./base-$dist-$arch.qcow2 ];
  then
    if [ "z$USE_LXC" = "z1" ];
    then
      export LXC_SUITE=$dist
      export LXC_ARCH=$arch
      ./bin/make-base-vm --suite $dist --lxc --arch $arch
    else
      ./bin/make-base-vm --suite $dist --arch $arch
    fi

    make-clean-vm --suite $dist --arch $arch
    if [ $? -ne 0 ];
    then
        echo "$arch $dist VM creation failed"
        exit 1
    fi

    stop-target $bits $dist
    start-target $bits $dist-$arch &
    for i in 1 2 3
    do
      sleep 2
      on-target /bin/true && break
    done
    return $?
  fi

  return 0
}

while ! build_and_test_vm lucid i386 32
do
  stop-target 32 lucid
  rm ./base-lucid-i386*
  echo
  echo "Lucid i386 VM build failed... Trying again"
  echo
done

while ! build_and_test_vm lucid amd64 64
do
  stop-target 64 lucid
  rm ./base-lucid-amd64*
  echo
  echo "Lucid amd64 VM build failed... Trying again"
  echo
done

while ! build_and_test_vm precise i386 32
do
  stop-target 32 precise
  rm ./base-precise-i386*
  echo
  echo "Lucid amd64 VM build failed... Trying again"
  echo
done

while ! build_and_test_vm precise amd64 64
do
  stop-target 64 precise
  rm ./base-precise-amd64*
  echo
  echo "Lucid amd64 VM build failed... Trying again"
  echo
done

