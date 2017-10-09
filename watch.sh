#!/bin/bash

FILE="$1"

while [ true ]
do
	SCORES="`cat $FILE`" 
	foils=`ls xfoil/ | grep cmds | cut -d "-" -f 3 | cut -d "." -f 1 | sort -u | uniq -u | tr "\n" " "`
	while [ -f $FILE.lock ]
	do
		sleep .01
	done
	touch $FILE.lock
	sed -i "/99991/ c `./timeest.sh`" "$FILE"
	sed -i "/99990/ c `./timeest.sh taken`" "$FILE"
	sed -i "/99989/ c 99989 In Progress - $foils" "$FILE"
	sorted=$(sort -gr $OUTFILE | uniq)
	echo "$sorted" > $OUTFILE
	rm $FILE.lock
	date
	echo ""
	echo "$SCORES"
	echo ""
	echo ""
	if [ -f "./upload.sh" ]
	then
		export SCORES
		./upload.sh
	fi
	sleep 5
done
