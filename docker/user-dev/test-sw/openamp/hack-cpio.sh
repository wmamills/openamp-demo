#!/bin/bash

ME=$0
DIR=$PWD

do_hack() {
	rm -rf xxx-temp-rootfs
	mkdir -p xxx-temp-rootfs
	echo "Extracting"
	case $1 in
	*.tar.gz)
	    tar xvf $1 -C xxx-temp-rootfs
	    ;;
	*.cpio.gz)
	    zcat $1 | (cd xxx-temp-rootfs; cpio -iV)
	    ;;
	*)
	    echo "don't know how to handle $1"
	    exit 2
	    ;;
	esac

	echo
	echo "Hacking"
	rm -rf xxx-temp-rootfs/boot/*
	rm -rf xxx-temp-rootfs/lib/firmware/*
	rm -rf xxx-temp-rootfs/lib/modules/*/drivers/gpu
	#rm -rf xxx-temp-rootfs/etc/rc*/*avahi*
	ln -sf sbin/init xxx-temp-rootfs/init
	echo "PS0:12345:respawn:/bin/start_getty 115200 ttyPS0 vt102" >>xxx-temp-rootfs/etc/inittab
	chmod u+w xxx-temp-rootfs/etc/securetty
	echo "ttyPS0" >>xxx-temp-rootfs/etc/securetty
	chmod -w xxx-temp-rootfs/etc/securetty

	echo "Re-archiving"
	(cd xxx-temp-rootfs; find . | cpio -V -H newc -o | gzip >../hacked.cpio.gz)
}

case $1 in
"")
	echo "need an input file"
	exit 2
	;;
"in-fakeroot")
	CMD=$2; shift 2
	do_${CMD} "$@"
	;;
*)
	fakeroot $ME in-fakeroot hack "$@"
	;;
esac
