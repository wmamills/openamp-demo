FROM ubuntu:20.04

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# preconfigure timezone
RUN echo 'Etc/UTC' > /etc/timezone; ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime

# Install prerequisites
RUN apt-get --quiet=2 update && apt-get install --quiet=2 --assume-yes \
    sudo nano wget python3 python3-pip openssh-client bash-completion tmux socat cpio

# setup a no password required sudo group
RUN addgroup --system sudo_nopwd; echo "%sudo_nopwd ALL=(ALL:ALL) NOPASSWD:ALL" >/etc/sudoers.d/20-sudo_nopwd; chmod 600 /etc/sudoers.d/*

# add the dev user
RUN adduser --gecos "dev" --disabled-password dev; adduser dev sudo_nopwd

ADD user-dev-base.tar.gz /home/dev

COPY login_message /home/dev

RUN su dev /home/dev/demo5/demo5-setup

# default command logs in as dev
CMD su -l dev
