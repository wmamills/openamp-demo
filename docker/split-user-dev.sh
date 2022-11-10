#!/bin/bash

set -e

move-to() {
    WHERE=$ORIG/xxx-temp-$1
    DIR=${PWD#$TOP}
    DIR=${DIR#/}
    shift

    #echo "WHERE=$WHERE DIR=$DIR"
    #echo "TOP=$TOP     PWD=$PWD"
    for f in "$@"; do
        echo "move $PWD/$f to $WHERE/$DIR"
        ff="$WHERE/$DIR/$f"
        d=$(dirname $ff)
        mkdir -p $d
        mv $f $d
    done
}

ORIG=$PWD
rm -rf xxx-temp-base|| true
mkdir xxx-temp-base
rm -rf xxx-temp-extra || true
mkdir xxx-temp-extra
rm -rf xxx-temp-trash || true
mkdir xxx-temp-trash

cd xxx-temp-base
TOP=$PWD

tar xvf $ORIG/user-dev.tar.gz 

cd $TOP/opt/zephyr-sdk-0.15.1
move-to extra arm-zephyr-eabi
move-to extra aarch64-zephyr-elf
cd sysroots/x86_64-pokysdk-linux/usr
move-to extra bin/qemu-*
move-to extra bin/openocd
move-to extra synopsys

cd $TOP

move-to extra opt/qemu-zcu102/stock-sw/xilinx-5.15/petalinux-rootfs.cpio.gz
move-to extra test-sw/openamp/openamp-image-minimal-generic-arm64.cpio.gz

tar czvf $ORIG/demo-lite/user-dev-base.tar.gz .
cd $ORIG/xxx-temp-extra
tar czvf $ORIG/demo/user-dev-extra.tar.gz .
cd $ORIG/xxx-temp-trash
tar czvf $ORIG/user-dev-trash.tar.gz .

cd $ORIG
rm -rf $ORIG/xxx-temp-base
rm -rf $ORIG/xxx-temp-extra
rm -rf $ORIG/xxx-temp-trash
