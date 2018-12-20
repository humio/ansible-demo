#!/bin/bash

bytes() {
    echo $1 | echo $((`sed 's/[ ]*//g;s/[bB]$//;s/^.*[^0-9gkmt].*$//;s/t$/Xg/;s/g$/Xm/;s/m$/Xk/;s/k$/X/;s/X/*1024/g'`))
}

# Returns a percentage of memory with jitter.
# examples:
#   HALF=$(mem .5) will be half the physical memory in bytes
#   AROUND_HALF=$(mem .5 .1) will be half the physical memory in bytes with a 1% variation (aka "jitter")
mem() {
    SEED=$RANDOM
    PCT=0
    JITTER=0
    OVERHEAD=0
    if [ $# -gt 0 ]; then
        PCT=${1:=0}
        if [ $# -eq 2 ]; then
            JITTER=$2
	    if [ $# -eq 3 ]; then
		OVERHEAD=$3
	    fi
        fi
    else
        echo 0
    fi
    echo $(bytes $(cat /proc/meminfo | awk -v pct=$PCT -v seed=$SEED -v jitter=$JITTER -v overhead=$OVERHEAD 'BEGIN{ srand(seed) } /MemTotal/{ p = sprintf("%.0f", (($2 - overhead) * pct) / 1024 ) } END{ if (jitter > 0) { printf("%.0f\n", p - rand() % jitter * p) } else { printf("%.0f\n", p ) } }')m)
}

blk() {
    BYTES=0
    for d in $@; do BYTES=$(($BYTES + $(blockdev --getsize64 /dev/$d))); done
    echo $BYTES
}

FOO=$(mem .1)
BAR=$(mem .5)
BAZ=$(mem .5 .1)
BIF=$(mem .5 0 $(bytes $((1 + 32))g))
echo $FOO
echo $BAR
echo $BAZ
echo $BIF

DEVS="nvme0n1 nvme1n1"
B=$(blk $DEVS)
echo $B
