#!/bin/bash

for f in $(find . -name "*.script"); do
	echo "add U-boot header to $f"
	mkimage -c none -A arm64 -T script -d $f ${f%.script}.scr
done

