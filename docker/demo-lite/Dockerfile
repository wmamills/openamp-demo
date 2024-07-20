FROM openamp/demo-base

ADD user-dev-base.tar.gz /home/dev

# add zephyr toolchains
COPY install-helper.sh /home/dev
RUN su dev /home/dev/install-helper.sh install_saved_image xilinx-qemu
RUN rm /home/dev/install-helper.sh

COPY login_message /home/dev

RUN su dev /home/dev/demo5/demo5-setup
