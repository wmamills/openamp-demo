# Makefile for docker images

all: demo-lite/marker demo/marker

demo/marker: demo-lite/marker demo/user-dev-extra.tar.gz demo/Dockerfile
	cd demo; docker build -t openamp/demo .

demo-lite/marker: demo-lite/user-dev-base.tar.gz demo-lite/Dockerfile
	cd demo-lite; docker build -t openamp/demo-lite .

demo-lite/user-dev-base.tar.gz demo/user-dev-extra.tar.gz &: user-dev.tar.gz split-user-dev.sh
	./split-user-dev.sh
