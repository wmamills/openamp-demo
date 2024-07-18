FROM openamp/demo-lite

# Install build tools and "nice to haves"
RUN apt-get --quiet=2 update && apt-get install --quiet=2 --assume-yes \
    build-essential git \
    mc ncdu tig \
    vim

# install Yocto/OE requirements
# some of these are already covered but be complete
RUN apt-get install --quiet=2 --assume-yes \
    gawk wget git-core diffstat unzip texinfo \
    build-essential chrpath socat cpio python3 python3-pip \
    python3-pexpect xz-utils debianutils iputils-ping curl git \
    zstd libssl-dev lz4

# install kas
RUN pip3 install kas==4.4

# install Zephyr requirements
# again some of these should already be covered but be complete
RUN apt-get install --quiet=2 --assume-yes --no-install-recommends \
    git ninja-build gperf \
    ccache dfu-util device-tree-compiler wget \
    python3-dev python3-pip python3-setuptools python3-tk python3-wheel xz-utils file \
    make gcc gcc-multilib g++-multilib libsdl2-dev libmagic1

# install west and Zephyr compatible cmake
RUN pip3 install west==0.14.0 cmake==3.24.3

# add just the stuff we took out of the base
ADD user-dev-extra.tar.gz /home/dev

COPY login_message /home/dev
COPY Makefile      /home/dev
