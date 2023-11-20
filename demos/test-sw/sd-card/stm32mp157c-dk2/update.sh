#!/bin/bash

for f in $(find . -name "*.script"); do
	echo "add U-boot header to $f"
	mkimage -c none -A arm -T script -d $f ${f%.script}.scr
done

