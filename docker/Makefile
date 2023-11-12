# Makefile for docker images

.PHONY: all user-dev-marker qemu-zcu102-marker

all: demo-lite/marker demo/marker

demo/marker: demo-lite/marker demo/user-dev-extra.tar.gz demo/Dockerfile
	cd demo; docker build -t openamp/demo .
	touch $@

demo-lite/marker: demo-lite/user-dev-base.tar.gz demo-lite/Dockerfile
	cd demo-lite; docker build -t openamp/demo-lite .
	touch $@

demo-lite/user-dev-base.tar.gz demo/user-dev-extra.tar.gz &: \
	user-dev-marker qemu-zcu102-marker split-user-dev.sh \
	zephyr-sdk-0.15.1-installed.tar.gz demos-marker
	./split-user-dev.sh

user-dev-marker:
	./find-latest-date user-dev $@

demos-marker:
	./find-latest-date ../demos $@

qemu-zcu102-marker:
	./find-latest-date ../qemu-zcu102 $@
