#!/bin/bash

set -e

XILINX_QEMU_VERSION=v2024.1

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

lfs_expand_tar() {
    # make sure we have the real file
    ls -l $BASE_DIR/$SAVED_IMAGES/$SOURCE
    (cd $BASE_DIR/$SAVED_IMAGES; git lfs pull --include $SOURCE)
    ls -l $BASE_DIR/$SAVED_IMAGES/$SOURCE
    if [ -e $DEST_DIR/$MARKER ]; then
        rm -rf $DEST_DIR
    fi
    mkdir -p $(dirname $DEST_DIR)
    tar xf $BASE_DIR/$SAVED_IMAGES/$SOURCE -C $(dirname $DEST_DIR)
}

do_install_saved_image() {
    # todo: move this to openamp and rename to openamp-images
    URL=https://github.com/wmamills/xen-rt-exp-images.git
    ARCH=$(uname -m)
    BASE_DIR=$HOME
    SAVED_IMAGES=saved-images
    OK=true

    cd $BASE_DIR

    # clone image repo without expanding the LFS files
    GIT_LFS_SKIP_SMUDGE=1 git clone --depth=1 $URL saved-images

    for i in "$@"; do
        case $i in
        xilinx-qemu)
            DEST_DIR=~/opt/qemu/qemu-xilinx-${XILINX_QEMU_VERSION}
            SOURCE=host/$ARCH/qemu-xilinx-${XILINX_QEMU_VERSION}.tar.gz
            MARKER=bin/qemu-system-aarch64
            lfs_expand_tar $DEST_DIR $SOURCE
            ;;
        *)
            echo "Unknown saved image $i"
            OK=false
            ;;
        esac
    done

    if [ -e $BASE_DIR/$SAVED_IMAGES/.gitattributes ]; then
        echo "removing saved-images"
        rm -rf $BASE_DIR/$SAVED_IMAGES
    fi

    if ! $OK; then
        exit 2
    fi
}

# tar archives of sub-dir w/o files considered ignored or untracked
# I did try tar's --exclude-vcs-ignore but I could not make it work correctly
tar_one() {
    NAME=$1
    TARGET=$2
    (cd $TARGET; git clean -ndx |
        sed -e "s:Would remove :$TARGET/:" |
        sed -e "s:/$::" >$SOURCE/$NAME.exclude)
    tar czf $SOURCE/$NAME.tar.gz --exclude-from=$SOURCE/$NAME.exclude $TARGET
}

do_git_archives() {
    cd $SOURCE/..
    echo "make archive of user-dev template"
    (cd docker/user-dev; tar_one user-dev .)

    echo "make archive of qemu-zcu102"
    (tar_one qemu-zcu102 qemu-zcu102)

    echo "make archive of demos"
    (cd demos; tar_one demos .)
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
    mkdir -p opt/zephyr

    echo "copy user-dev template"
    tar xvf $SOURCE/user-dev.tar.gz

    echo "copy in the demos directory"
    tar xvf $SOURCE/demos.tar.gz

    echo "copy in the qemu-zcu102 files"
    tar xvf $SOURCE/qemu-zcu102.tar.gz -C opt

    echo "install zephyr minimal sdk"
    (do_install_zephyr_sdk)
    cp -a $ZEPHYR_SDK_INSTALL_DIR/$ZEPHYR_SDK_SETUP_DIR opt/zephyr

    echo "fixup the symlinks"
    cd opt
    ln -sf ../../../../qemu/qemu-xilinx-${XILINX_QEMU_VERSION}/bin/qemu-system-aarch64 \
        ./qemu-zcu102/sysroot/usr/bin/qemu-system-aarch64
    ln -sf ../../../../qemu/qemu-xilinx-${XILINX_QEMU_VERSION}/bin/qemu-system-microblazeel \
        ./qemu-zcu102/sysroot/usr/bin/qemu-system-microblazeel

    # trim zephyr sdk for our needs
    # 0.16.8 stats
    # before trim 429 MB
    # after trim 228.1 MB
    echo "Trim the zephyr sdk"
    cd $TOP/opt/zephyr/zephyr-sdk-$ZEPHYR_SDK_VERSION
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
"user_dev"|"git_archives"|"inside_container"|"sudo_user_dev")
    shift
    do_$CMD "$@"
    ;;
install_*)
    shift
    do_$CMD "$@"
    ;;
*)
    echo "Unknown sub-command $1"
    exit 2
    ;;
esac
