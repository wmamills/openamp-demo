# Makefile for docker images

.PHONY: all check-dates split

all: demo-lite/marker demo/marker

demo/marker: demo-lite/marker demo/user-dev-extra.tar.gz \
	demo/Dockerfile demo/login_message demo/Makefile
	cp install-helper.sh demo
	cd demo; docker build -t openamp/demo .
	rm demo/install-helper.sh
	touch $@

demo-lite/marker: demo-base/marker demo-lite/user-dev-base.tar.gz \
	demo-lite/Dockerfile demo-lite/login_message
	cp install-helper.sh demo-lite
	cd demo-lite; docker build -t openamp/demo-lite .
	rm demo-lite/install-helper.sh
	touch $@

demo-base/marker: demo-base/Dockerfile demo-base/login_message
	cd demo-base; docker build -t openamp/demo-base .
	touch $@

demo-lite/user-dev-base.tar.gz demo/user-dev-extra.tar.gz &: \
	user-dev-marker qemu-zcu102-marker demos-marker \
	install-helper.sh
	./install-helper.sh git_archives
	docker run --rm -v${PWD}/..:/prj openamp/demo-base \
		/prj/docker/install-helper.sh inside_container

split: demo-lite/user-dev-base.tar.gz

user-dev-marker: check-dates

demos-marker: check-dates

qemu-zcu102-marker: check-dates

check-dates:
	./find-latest-date user-dev        user-dev-marker
	./find-latest-date ../demos        demos-marker
	./find-latest-date ../qemu-zcu102  qemu-zcu102-marker
