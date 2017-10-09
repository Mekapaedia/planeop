#!/bin/bash

OUTFILE=""

CHORDW=0
CLMAXW=0
CMW=0
CDW=0
CDMAX=0
REYNOLDS=""

EXEC=$(grep -c ^processor /proc/cpuinfo)

while [ "$#" -gt "0" ]
do
	case "$1" in
		-r)
			shift
			while [ "$1" = "$1" 2> /dev/null -a "$1" -gt "0" ]
			do
				REYNOLDS+="$1"
				REYNOLDS+=" "
				shift
			done
			;;
		-f)
            CDMAX=1
            shift
            ;;
		-t)
			shift
			if [ "$1" -eq "$1" 2>/dev/null ]
			then
				EXEC=$1
			fi
			shift
			;;
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

trap 'kill -9 $(jobs -p); taskkill -F -IM xfoil.exe; exit' SIGINT SIGTERM SIGKILL EXIT

if [ "$REYNOLDS" = "" ]
then
	REYNOLDS=50000
fi

export OUTFILE
export CHORDW
export CLMAXW
export CMW
export CDW
export CDMAX
export REYNOLDS

touch "$OUTFILE"

for i in 99999 99998 99997 99996 99995 99994 99993 99992 99991 99990 99989
do
	if [ -z "`cat "$OUTFILE" | grep $i`" ]
	then
		echo "$i" >> "$OUTFILE"
	fi
done

if [ "$CDMAX" -eq "1" ]
then
	sed -i "/99999/ c 99999 Formula SAE type comparison (no coeff moment)" "$OUTFILE"
else
	sed -i "/99999/ c 99999 Wing comparison" "$OUTFILE"
fi

if [ "$CHORDW" -gt "0" ]
then
	sed -i "/99999/ c 99999 Wing comparison with box fitting weighting" "$OUTFILE"
fi

sed -i "/99998/ c 99998 Weights - Chord size: $CHORDW, Max Cl: $CLMAXW, Cd: $CDW, Cm: $CMW" "$OUTFILE"
sed -i "/99997/ c 99997 Reynolds - $REYNOLDS" "$OUTFILE"
sed -i "/99996/ c 99996 Threads - $EXEC" "$OUTFILE"
sed -i "/99995/ c 99995 Start date - `date`" "$OUTFILE"
sed -i "/99994/ c 99994 Last update - `date`" "$OUTFILE"

MAXA=20
export MAXA
DIV=4
export DIV
MAX=$(echo "$MAXA * $DIV" | bc -l | awk '{printf("%g\n",$1)}')
export MAX

SAMPLES=0
for i in $REYNOLDS
do
	SAMPLES=`expr $SAMPLES + 1`
done
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
echo "Getting aerofoils..."
wget -r -nH -nd -np -e robots=off -A "dat" http://m-selig.ae.illinois.edu/ads/coord_seligFmt >> ../getfoils.out 2>&1 || echo "Error in getting some profiles"
sed -i "/99994/ c 99994 Last update - `date`" "../$OUTFILE"
wget -r -nH -nd -np -e robots=off -A "dat" http://m-selig.ae.illinois.edu/ads/coord_updates >> ../getfoils.out 2>&1 || echo "Error in getting some profiles"
sed -i "/99994/ c 99994 Last update - `date`" "../$OUTFILE"
cp ../addfoils/* . >> getfoils.out || echo "Error in getting some profiles"
sed -i "/99994/ c 99994 Last update - `date`" "../$OUTFILE"
cd ..
echo "Done"
NUMFOILS="`ls foils/ | wc -l`"
echo $NUMFOILS > numfoils
sed -i "/99993/ c 99993 Number of foils to be tested - $NUMFOILS" "$OUTFILE"
sed -i "/99992/ c 99992 Number of foils left - $NUMFOILS" "$OUTFILE"
sed -i "/99991/ c 99991 Estimated time left - " "$OUTFILE"
sed -i "/99990/ c 99990 Time taken - " "$OUTFILE"
sed -i "/99989/ c 99989 In Progress - " "$OUTFILE"

"./watch.sh" "$OUTFILE" &

for foil in $(ls foils)
do
	foilname=$(basename $foil .dat)
	while [ "$(jobs -r | grep calc.sh | wc -l)" -ge "$EXEC" ]
	do
		sleep .01
	done
	./calc.sh $foil >> calc.out 2>&1 || echo "Error occured in calculation" &
	sed -i "/99994/ c 99994 Last update - `date`" "$OUTFILE"
done
