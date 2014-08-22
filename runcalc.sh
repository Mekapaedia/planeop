#!/bin/bash

OUTFILE=""

CHORDW=0
CLMAXW=0
CMW=0
CDW=0

EXEC=$(grep -c ^processor /proc/cpuinfo)

while [ "$#" -gt "0" ]
do
	case "$1" in
		-c)
			shift
			if [ "$1" -eq "$1" 2>/dev/null ]
			then
				CHORDW=$1
			fi
			shift
			;;
		-l)
			shift
			if [ "$1" -eq "$1" 2>/dev/null ]
			then
				CLMAXW=$1
			fi
			shift
			;;
		-m)
			shift
			if [ "$1" -eq "$1" 2>/dev/null ]
			then
				CMW=$1
			fi
			shift
			;;
		-d)
			shift
			if [ "$1" -eq "$1" 2>/dev/null ]
			then
				CDW=$1
			fi
			shift
			;;
		-o)
			shift
			OUTFILE=$1
			shift
			;;
		*)
			break
			;;
	esac
done

export OUTFILE
export CHORDW
export CLMAXW
export CMW
export CDW


MAXA=20
export MAXA
DIV=4
export DIV
MAX=$(echo "$MAXA * $DIV" | bc -l | awk '{printf("%g\n",$1)}')
export MAX

SAMPLES=3
export SAMPLES

CL=0
export CL
CD=0
export CD
CM=0
export CM
CHORD=0
export CHORD

SCORE=0
export SCORE

rm -rf foils
mkdir -p foils
cd foils
wget -r -np -nH -e robots=off --relative --level=1 --no-directories -A "dat" http://aerospace.illinois.edu/m-selig/ads/coord_updates/
wget -r -np -nH -e robots=off --relative --level=1 --no-directories -A "dat" http://aerospace.illinois.edu/m-selig/ads/coord_seligFmt/
cp ../addfoils/* .
cd ..
for foil in $(ls foils)
do
	
	foilname=$(basename $foil .dat)
	while [ $(jobs | grep "Running" | wc -l) -ge "$EXEC" ]
	do
		sleep .01
	done
	./calc.sh $foil &
done
