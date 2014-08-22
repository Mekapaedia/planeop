#!/bin/bash

nofile=1

while [ "$nofile" -ne "0" ]
do
	ls . | grep -q "$1"
	nofile=$?
	sleep 10
done
watch -n 1 cat fusescores
