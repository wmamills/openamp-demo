#!/bin/bash

ME=$0
MY_NAME=$(basename $ME)

UBUNTU_VER=22.04

JOB_NAME1=openamp-docker-build
JOB_DATE=$(date +%Y-%m-%d-%H%M%S)
JOB_NAME=${JOB_NAME1}-${JOB_DATE}

for i in "$@"; do
    VAL=${i#*=}
    case $i in
    VARIANT=*)
        VARIANT=$VAL
        ;;
    esac
done

case $VARIANT in
""|"openamp")
    NAME=openamp-docker
    BRANCH=main
    URL=https://github.com/openamp/openamp-demo.git
    ;;
"wam-wip")
    NAME=openamp-docker
    BRANCH=wam-wip
    URL=https://github.com/wmamills/openamp-demo.git
    ;;
*)
    echo "unknown variant $2"
    exit 2
    ;;
esac

echo "VARIANT=$VARIANT"

admin_setup() {
    apt-get update
    apt-get install -y git git-lfs docker.io make
    if [ -n "$1" ]; then
        adduser $1 docker
    fi
}

prj_build() {
    ORIG_PWD=$PWD
    ARCH=$(uname -m)
    rm -rf out
    mkdir -p out

    rm -rf openamp-demo
    git clone $URL openamp-demo
    cd openamp-demo
    if [ -n "$BRANCH" ]; then
        git checkout $BRANCH
    fi
    if [ -n "$VER" ]; then
        git reset --hard $VER
    fi
    git log -n 1

    cd docker
    make
    echo "save demo-lite image"
    docker image save openamp/demo-lite | gzip >$ORIG_PWD/out/demo-lite-${ARCH}.tar.gz
    echo "save demo image"
    docker image save openamp/demo | gzip >$ORIG_PWD/out/demo-${ARCH}.tar.gz

    cd $ORIG_PWD
}

# multipass and ssh-sudo use two invocations of the remote
# the admin_setup step will add the user to the docket group but it won't be
# active until the next login so we exit the remote and come back in for the
# prj_build
case $1 in
"admin_setup")
    # already root, just do the admin setup
    shift
    admin_setup "$@"
    ;;
"prj_build")
    # admin_setup was done somehow, just run the prj_build
    shift
    prj_build "$@"
    ;;
"here-sudo")
    # local build, use sudo to do admin-setup and then do prj_build
    shift
    sudo $ME admin_setup $USER "$@"
    prj_build
    ;;
"here-sudo-only")
    # local build, use sudo to do admin-setup only
    shift
    sudo $ME admin_setup $USER "$@"
    ;;
"multipass")
    # use multipass on the local machine to get a clean install of the distro
    # is always the same arch as the host
    shift
    multipass launch -n $JOB_NAME -c 10 -d 15G -m 16G $UBUNTU_VER
    multipass transfer $0 $JOB_NAME:.
    multipass exec $JOB_NAME -- ./$MY_NAME here-sudo-only "$@"
    multipass exec $JOB_NAME -- ./$MY_NAME prj_build "$@"
    #echo "Wait for inspection"; read ignore
    # multipass always matches host
    TARGET_ARCH=$(uname -m)
    mkdir -p saved-images/host/$TARGET_ARCH
    multipass transfer $JOB_NAME:$NAME.tar.gz saved-images/host/$TARGET_ARCH/.
    multipass delete --purge $JOB_NAME
    ;;
"ssh-sudo")
    REMOTE_SSH=$2
    shift 2
    scp $ME $REMOTE_SSH:.
    ssh $REMOTE_SSH ./$MY_NAME here-sudo-only "$@"
    ssh $REMOTE_SSH ./$MY_NAME prj_build
    TARGET_ARCH=$(ssh $REMOTE_SSH uname -m)
    mkdir -p saved-images/host/$TARGET_ARCH
    scp "$REMOTE_SSH:out/*" saved-images/host/$TARGET_ARCH/.
    ;;
"ec2-x86_64"|"ec2-x86")
    JOB_NAME=${JOB_NAME1}-x86_64
    shift
    ec2 aws-$JOB_NAME run --inst m7i.2xlarge  --os-disk 15 --distro ubuntu-$UBUNTU_VER
    $ME ssh-sudo aws-$JOB_NAME "$@"
    #echo "Wait for inspection"; read ignore
    ec2 aws-$JOB_NAME destroy
    ;;
"ec2-arm64"|"ec2-arm")
    JOB_NAME=${JOB_NAME1}-aarch64
    shift
    ec2 aws-$JOB_NAME run --inst m7g.2xlarge  --os-disk 15 --distro ubuntu-$UBUNTU_VER
    $ME ssh-sudo aws-$JOB_NAME "$@"
    #echo "Wait for inspection"; read ignore
    ec2 aws-$JOB_NAME destroy
    ;;
*)
    echo "Don't understand argument $1"
    ;;
esac
