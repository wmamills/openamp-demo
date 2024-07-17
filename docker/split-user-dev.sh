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

do_git_archives() {
cd $SOURCE/..
echo "make archive of user-dev template"
(cd docker/user-dev; git archive -o $SOURCE/user-dev.tar.gz HEAD -- .)

echo "make archive of qemu-zcu102"
git archive -o $SOURCE/qemu-zcu102.tar.gz HEAD -- qemu-zcu102

echo "make archive of demos"
(cd demos; git archive -o $SOURCE/demos.tar.gz HEAD -- *)
}

user_dev_inner() {
cd $ORIG
rm -rf xxx-temp-base|| true
mkdir xxx-temp-base
rm -rf xxx-temp-extra || true
mkdir xxx-temp-extra
rm -rf xxx-temp-trash || true
mkdir xxx-temp-trash
rm -rf xxx-temp-out || true
mkdir xxx-temp-out
OUT=$ORIG/xxx-temp-out

cd $ORIG/xxx-temp-base
TOP=$PWD
mkdir -p opt

echo "copy user-dev template"
tar xvf $SOURCE/user-dev.tar.gz

echo "copy in the demos directory"
tar xvf $SOURCE/demos.tar.gz

echo "copy in the qemu-zcu102 files"
tar xvf $SOURCE/qemu-zcu102.tar.gz -C opt

echo "copy in the pre-installed image of the zephyr-sdk"
tar xvf $SOURCE/zephyr-sdk-0.15.1-installed.tar.gz -C opt

echo "fixup the symlinks"
cd opt
ln -sf ../../../../zephyr-sdk-0.15.1/sysroots/x86_64-pokysdk-linux/usr/xilinx/bin/qemu-system-aarch64 \
    ./qemu-zcu102/sysroot/usr/bin/qemu-system-aarch64
ln -sf ../../../../zephyr-sdk-0.15.1/sysroots/x86_64-pokysdk-linux/usr/xilinx/bin/qemu-system-microblazeel \
    ./qemu-zcu102/sysroot/usr/bin/qemu-system-microblazeel

echo "Start the splitting operation"
cd $TOP/opt/zephyr-sdk-0.15.1
move-to extra arm-zephyr-eabi
move-to extra aarch64-zephyr-elf
cd sysroots/x86_64-pokysdk-linux/usr
move-to extra bin/qemu-*
move-to extra bin/openocd
move-to extra synopsys

cd $TOP

move-to extra test-sw/openamp-ci-*/modules-*.tgz

tar czvf $OUT/user-dev-base.tar.gz .
cd $ORIG/xxx-temp-extra
tar czvf $OUT/user-dev-extra.tar.gz .
cd $ORIG/xxx-temp-trash
tar czvf $OUT/user-dev-trash.tar.gz .

cd $ORIG
rm -rf $ORIG/xxx-temp-base
rm -rf $ORIG/xxx-temp-extra
rm -rf $ORIG/xxx-temp-trash
}

do_user_dev() {
    user_dev_inner
    user_dev_outer
}

# we are inside the container but we are root
user_dev_outer() {
    OUT=$ORIG/xxx-temp-out

    # now copy the archives to the correct place
    HOST_UID=$(stat -c %u $ME)
    HOST_GID=$(stat -c %g $ME)
    chown $HOST_UID:$HOST_GID $OUT/user-dev-*.tar.gz
    cp -p $OUT/user-dev-base.tar.gz $SOURCE/demo-lite/.
    cp -p $OUT/user-dev-extra.tar.gz $SOURCE/demo/.
    cp -p $OUT/user-dev-trash.tar.gz $SOURCE/.

    rm -rf $ORIG/xxx-temp-out
}

do_sudo_user_dev() {
    ORIG=$HOME
    SOURCE=/prj/docker
    DEST=$HOME
    user_dev_inner
}

# we are inside the container but we are root
do_inside_container() {
    # do the bulk of the work as the "dev" user
    sudo -Hu dev $ME sudo_user_dev

    ORIG=/home/dev
    SOURCE=/prj/docker
    DEST=$ORIG
    user_dev_outer
}

ME=$0
cd $(dirname $0)
ORIG=$PWD
SOURCE=$PWD
CMD=$1
case $CMD in
"user_dev"|"git_archives"|"inside_container"|"sudo_user_dev")
    shift
    do_$CMD
    ;;
*)
    echo "Unknown sub-command $1"
    exit 2
    ;;
esac
