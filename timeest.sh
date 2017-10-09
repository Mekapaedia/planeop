#!/bin/bash

now="`date +%s`"
startdate="$(date +%s -d "`grep 99995 $OUTFILE | cut -d "-" -f 2`")"

if [ "$1" = "taken" ]
then
	timetaken="`echo "($now - $startdate)" | bc`"
	days="`date -d@$timetaken -u +"%-j"`"
	days="`expr $days - 1`"
	echo "99990 Time taken - $days days `date -d@$timetaken -u +"%H hours %M minutes %S seconds"`"
else
	totfoils="`grep 99993 $OUTFILE | cut -d " " -f 9`"
	leftfoils="`grep 99992 $OUTFILE | cut -d " " -f 7`"
	lastdate="$(date +%s -d "`cat $OUTFILE | grep 99994 | cut -d "-" -f 2`")"
	speed="`echo "{scale=8;($totfoils-$leftfoils)/(($lastdate)-$startdate)}" | bc`"
	lefttime="0"
	if [ "$speed" != "0" ]
	then
		lefttime="`echo "{scale=0;($leftfoils/$speed) - (($now) - $lastdate)}" | bc`"
	fi
	days="`date -d@$lefttime -u +"%-j"`"
	days="`expr $days - 1`"
	echo "99991 Estimated time left - $days days `date -d@$lefttime -u +"%H hours %M minutes %S seconds"`"
fi
