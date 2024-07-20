FROM openamp/demo-base

ADD user-dev-base.tar.gz /home/dev

# add zephyr toolchains
COPY split-user-dev.sh /home/dev
RUN su dev /home/dev/split-user-dev.sh install_saved_image xilinx-qemu
RUN rm /home/dev/split-user-dev.sh

COPY login_message /home/dev

RUN su dev /home/dev/demo5/demo5-setup
