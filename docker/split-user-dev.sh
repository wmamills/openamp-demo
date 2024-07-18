#!/bin/bash

set -e

ZEPHYR_SDK_VERSION=0.16.8
ZEPHYR_TOOLCHAINS_COMMON=" \
    aarch64-zephyr-elf \
    arm-zephyr-eabi \
    microblazeel-zephyr-elf \
    riscv64-zephyr-elf \
    x86_64-zephyr-elf \
"
ZEPHYR_TOOLCHAINS_MIN=" \
    aarch64-zephyr-elf \
    arm-zephyr-eabi \
"

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

set_zephyr_vars() {
    ARCH=$(uname -m)
    ZEPHYR_SDK_INSTALL_DIR=~/opt/zephyr
    ZEPHYR_SDK_DOWNLOAD_FOLDER=https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v$ZEPHYR_SDK_VERSION
    ZEPHYR_SDK_SETUP_DIR=zephyr-sdk-$ZEPHYR_SDK_VERSION
    ZEPHYR_SDK_SETUP_TAR=${ZEPHYR_SDK_SETUP_DIR}_linux-${ARCH}_minimal.tar.xz
    ZEPHYR_SDK_DOWNLOAD_URL=$ZEPHYR_SDK_DOWNLOAD_FOLDER/$ZEPHYR_SDK_SETUP_TAR
}

do_install_zephyr_sdk() {
    set_zephyr_vars
    mkdir -p ~/setup
    mkdir -p ~/opt/zephyr
    cd ~/setup

    if false; then
        python3 -m venv .venv
        . .venv/bin/activate
        pip3 install cmake==3.24.3
        pip3 list
        which cmake
        read
    fi

    rm -rf $ZEPHYR_SDK_INSTALL_DIR/$ZEPHYR_SDK_SETUP_DIR
    rm -f $ZEPHYR_SDK_SETUP_TAR
    wget $ZEPHYR_SDK_DOWNLOAD_URL
    tar xvf $ZEPHYR_SDK_SETUP_TAR -C $ZEPHYR_SDK_INSTALL_DIR
    rm -rf ~/setup
    cd $ZEPHYR_SDK_INSTALL_DIR/$ZEPHYR_SDK_SETUP_DIR
    ./setup.sh -h
}

do_install_zephyr_toolchains() {
    local TOOLCHAINS
    set_zephyr_vars

    # 0.16.8 stats
    # 1.4 GB min    arm aarch64 only 
    # 2.9 GB common arm aarch64 riscv64 microblazeel x86_64
    # 7.6 GB all
    case $1 in
    min)
        TOOLCHAINS="$ZEPHYR_TOOLCHAINS_MIN"
        ;;
    common|"")
        TOOLCHAINS="$ZEPHYR_TOOLCHAINS_COMMON"
        ;;
    all)
        TOOLCHAINS="all"
        ;;
    *)
        TOOLCHAINS="$1"
    esac

    cd $ZEPHYR_SDK_INSTALL_DIR/$ZEPHYR_SDK_SETUP_DIR
    ./setup.sh -c
    for T in $TOOLCHAINS; do
        ./setup.sh -t $T
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
    set_zephyr_vars

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

    echo "install zephyr minimal sdk"
    (do_install_zephyr_sdk)
    cp -a $ZEPHYR_SDK_INSTALL_DIR/$ZEPHYR_SDK_SETUP_DIR opt

    echo "fixup the symlinks"
    cd opt
    ln -sf ../../../../zephyr/zephyr-sdk-$ZEPHYR_SDK_VERSION/sysroots/${ARCH}-pokysdk-linux/usr/xilinx/bin/qemu-system-aarch64 \
        ./qemu-zcu102/sysroot/usr/bin/qemu-system-aarch64
    ln -sf ../../../../zephyr/zephyr-sdk-$ZEPHYR_SDK_VERSION/sysroots/${ARCH}-pokysdk-linux/usr/xilinx/bin/qemu-system-microblazeel \
        ./qemu-zcu102/sysroot/usr/bin/qemu-system-microblazeel

    # trim zephyr sdk for our needs
    # 0.16.8 stats
    # before trim 429 MB
    # after trim 228.1 MB
    echo "Trim the zephyr sdk"
    cd $TOP/opt/zephyr-sdk-$ZEPHYR_SDK_VERSION
    move-to trash zephyr-sdk-*-hosttools-standalone-*.sh
    cd sysroots/$ARCH-pokysdk-linux
    move-to extra usr/bin/qemu-system-{xtensa,i386,mips,mipsel,sparc,nios2}
    move-to extra usr/{bin,share}/openocd
    move-to extra usr/synopsys

    echo "Trim the demos"
    cd $TOP
    move-to extra test-sw/openamp-ci-*/modules-*.tgz

    # tar up everything left
    tar czvf $OUT/user-dev-base.tar.gz .

    # and the stuff saved for later
    cd $ORIG/xxx-temp-extra
    tar czvf $OUT/user-dev-extra.tar.gz .

    # and the stuff we are getting rid of
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
"user_dev"|"git_archives"|"inside_container"|"sudo_user_dev"|"install_zephyr_sdk")
    shift
    do_$CMD "$@"
    ;;
install_zephyr*)
    shift
    do_$CMD "$@"
    ;;
*)
    echo "Unknown sub-command $1"
    exit 2
    ;;
esac
