# Makefile for docker images

all: demo-lite/marker demo/marker

demo/marker: demo-lite/marker demo/user-dev-extra.tar.gz demo/Dockerfile
	cd demo; docker build -t openamp/demo .
	touch $@

demo-lite/marker: demo-lite/user-dev-base.tar.gz demo-lite/Dockerfile
	cd demo-lite; docker build -t openamp/demo-lite .
	touch $@

demo-lite/user-dev-base.tar.gz demo/user-dev-extra.tar.gz &: \
	user-dev-marker qemu-zcu102-marker split-user-dev.sh zephyr-sdk-0.15.1-installed.tar.gz
	./split-user-dev.sh

# Don't you love stack exchange
# find magic is based on answer by Trevor Boyd Smity for
# https://stackoverflow.com/questions/1015678/get-most-recent-file-in-a-directory-on-linux
# the bit about the marker files in mine
user-dev-marker:
	echo $(find user-dev -printf "%T@ %p\n" | sort -n | cut -d' ' -f 2- | tail -n 1) >$@
	touch -r $(cat $@) $@

qemu-zcu102-marker:
	echo $(find ../qemu-zcu102 -printf "%T@ %p\n" | sort -n | cut -d' ' -f 2- | tail -n 1) >$@
	touch -r $(cat $@) $@
