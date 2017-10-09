#!/bin/bash

trap 'kill -9 $(jobs -p); exit' SIGINT SIGTERM SIGKILL EXIT

foil=$1
foilname=$(basename $foil .dat)

echo "$OUTFILE:$foilname:$REYNOLDS"
 
out=$(cat $OUTFILE | cut -d " " -f 2 | grep -Fxq $foilname; echo "${PIPESTATUS[2]}")

if [ "$out" -eq "0" ]
then
	while [ -f $OUTFILE.lock ]
	do
		sleep .01
	done
	touch $OUTFILE.lock
	NUMFOILS=`cat numfoils`
	NUMFOILS=`expr $NUMFOILS - 1`
	echo $NUMFOILS > numfoils
	sed -i "/99992/ c 99992 Number of foils left - $NUMFOILS" "$OUTFILE"
	sed -i "/99994/ c 99994 Last update - `date`" "$OUTFILE"
	sed -i "/99991/ c `./timeest.sh`" "$OUTFILE"
	sed -i "/99990/ c `./timeest.sh taken`" "$OUTFILE"
	echo "$foilname already done"
	rm $OUTFILE.lock
	exit 0
fi

./parse.sh foils/$foil
if [ "$CHORDW" -ne "0" ]
then
	CHORD=$(fuseop/fuseop foils/$foil -q)
fi

cd xfoil
for i in $REYNOLDS
do
	echo "PLOP" >> cmds-$i-$foilname.txt
	echo "G" >> cmds-$i-$foilname.txt
	echo ""  >> cmds-$i-$foilname.txt
	echo "LOAD ../foils/$foil" >> cmds-$i-$foilname.txt
	echo "MDES" >> cmds-$i-$foilname.txt
	echo "FILT" >> cmds-$i-$foilname.txt
	echo "EXEC" >> cmds-$i-$foilname.txt
	echo "" >> cmds-$i-$foilname.txt
	echo "PANE" >> cmds-$i-$foilname.txt
	echo "OPER" >> cmds-$i-$foilname.txt
	echo "ITER 70" >> cmds-$i-$foilname.txt
	echo "RE $i" >> cmds-$i-$foilname.txt
	echo "VISC $i" >> cmds-$i-$foilname.txt
	echo "PACC" >> cmds-$i-$foilname.txt
	echo "../polars/$foilname-$i.pol" >> cmds-$i-$foilname.txt
	echo "" >> cmds-$i-$foilname.txt
	for j in $(seq 0 $MAX)
	do
		alpha=$(echo "$j/$DIV" | bc -l | awk '{printf("%g\n",$1)}') 
		echo "ALFA $alpha" >> cmds-$i-$foilname.txt
		echo "ALFA $alpha" >> cmds-$i-$foilname.txt
		echo "ALFA $alpha" >> cmds-$i-$foilname.txt
		echo "INIT" >> cmds-$i-$foilname.txt
	done
	echo "PACC" >> cmds-$i-$foilname.txt
	echo "VISC" >> cmds-$i-$foilname.txt
	echo "" >> cmds-$i-$foilname.txt
	echo "QUIT" >> cmds-$i-$foilname.txt
done

for i in $REYNOLDS
do
	timeout -k 11m 10m ./xfoil < cmds-$i-$foilname.txt || timeout -k 11m 10m ./xfoil < cmds-$i-$foilname.txt || timeout -k 11m 10m ./xfoil < cmds-$i-$foilname.txt
done

for i in $REYNOLDS
do
	rm -f cmds-$i-$foilname.txt
done

cd ..

cd polars
for re in $REYNOLDS
do
	START=0
	INITREAD=0
	PREVCL=0
	CL1=0
	CLH=0
	CD1=0
	CDH=0
	CM1=0
	while read line
	do
		if [ "$START" -eq "1" ]
		then
			if [ "$INITREAD" -eq "0" ]
			then
				CD1=$(echo $line | cut -d " " -f 3)
				CM1=$(echo $line | cut -d " " -f 5)
				INITREAD=1
			fi
			CL1=$(echo $line | cut -d " " -f 2)
			if [ "$CDMAX" -eq "1" ]
			then
				CD1=$(echo $line | cut -d " " -f 3)
			fi
			ret=$(echo "$CL1 > $CLH" | bc)
			if [ "$ret" -eq "1" ]
			then
				CLH=$CL1
				CDH=$CD1
			fi
		fi 
	
		if [[ $line == *------* ]]
		then
			START=1
		fi

	done < "$foilname-$re.pol"
	CL=$(echo "$CLH + $CL" | bc -l | awk '{printf("%g\n",$1)}')
	CM=$(echo "$CM1 + $CM" | bc -l | awk '{printf("%g\n",$1)}')
	CD=$(echo "$CDH + $CD" | bc -l | awk '{printf("%g\n",$1)}')
done

CL=$(echo "$CL/$SAMPLES" | bc -l | awk '{printf("%g\n",$1)}')
CM=$(echo "$CM/$SAMPLES" | bc -l | awk '{printf("%g\n",$1)}')
CD=$(echo "$CD/$SAMPLES" | bc -l | awk '{printf("%g\n",$1)}')

cd ..

SCORE=$(echo "($CHORDW * $CHORD) + ($CLMAXW * $CL) + ($CMW * $CM) + ($CDW * $CD)" | bc -l | awk '{printf("%g\n",$1)}')

while [ -f $OUTFILE.lock ]
do
	sleep .01
done

touch $OUTFILE.lock

echo -n "$SCORE $foilname " >> $OUTFILE
if [ "$CHORDW" -ne "0" ]
then
	echo -n "minimum chord: $CHORD " >> $OUTFILE
fi
echo -n "clmax: $CL " >> $OUTFILE

if [ "$CDMAX" -eq "1" ]
then
	echo "cdmax: $CD" >> $OUTFILE
else
	echo "cm0: $CM cd0: $CD" >> $OUTFILE
fi

NUMFOILS=`cat numfoils`
NUMFOILS=`expr $NUMFOILS - 1`
echo $NUMFOILS > numfoils
sed -i "/99992/ c 99992 Number of foils left - $NUMFOILS" "$OUTFILE"
sed -i "/99994/ c 99994 Last update - `date`" "$OUTFILE"
sed -i "/99991/ c `./timeest.sh`" "$OUTFILE"
sed -i "/99990/ c `./timeest.sh taken`" "$OUTFILE"

sorted=$(sort -gr $OUTFILE | uniq)

echo "$sorted" > $OUTFILE

rm $OUTFILE.lock
