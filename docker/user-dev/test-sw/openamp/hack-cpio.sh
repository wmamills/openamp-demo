#!/bin/bash

ME=$0
DIR=$PWD

do_hack() {
	rm -rf rootfs
	mkdir -p rootfs
	echo "Extracting"
	case $1 in
	*.tar.gz)
	    tar xvf $1 -C rootfs
	    ;;
	*.cpio.gz)
	    zcat $1 | (cd rootfs; cpio -iV)
	    ;;
	*)
	    echo "don't know how to handle $1"
	    exit 2
	    ;;
	esac

	echo
	echo "Hacking"
	rm -rf rootfs/boot/*
	rm -rf rootfs/lib/firmware/*
	rm -rf rootfs/lib/modules/*/drivers/gpu
	#rm -rf rootfs/etc/rc*/*avahi*
	ln -sf sbin/init rootfs/init
	echo "PS0:12345:respawn:/bin/start_getty 115200 ttyPS0 vt102" >>rootfs/etc/inittab
	chmod u+w rootfs/etc/securetty
	echo "ttyPS0" >>rootfs/etc/securetty
	chmod -w rootfs/etc/securetty

	echo "Re-archiving"
	(cd rootfs; find . | cpio -V -H newc -o | gzip >../hacked.cpio.gz)
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
