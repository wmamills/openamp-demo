#!/bin/bash

LAST=0

for i in qemu-log-*; do
    t=${i%-run-*.txt}
    t=${t#qemu-log-2024-07-19-}
    h=${t:0:2}
    m=${t:2:2}
    s=${t:4:2}
    S=$(( 10#$h * 60 * 60 + 10#$m * 60 + 10#$s ))
    D=$(( $S - $LAST ))
    LAST=$S
    #echo "i=$i t=$t h=$h m=$m s=$s S=$S D=$D"
    printf "%-40s %d\n" "$i" $D
done