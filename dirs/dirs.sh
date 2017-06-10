#!/bin/bash

DIR0="/tmp/dir#0"

mkdir $DIR0

for i in $(seq 1 5); do
    mkdir -p "$DIR0/dir#$i"
    for j in $(seq 1 20); do
	    > "$DIR0/dir#$i/file#$j"
    done
done
 
