#!/bin/bash

foil=$1
foilname=$(basename $foil .dat)

echo "$OUTFILE:$foilname"
 
out=$(cat $OUTFILE | cut -d " " -f 2 | grep -Fxq $foilname; echo "${PIPESTATUS[2]}")

if [ "$out" -eq "0" ]
then
	echo "Exiting"
	exit
fi

./parse.sh foils/$foil
if [ "$CHORDW" -ne "0" ]
then
	CHORD=$(fuseop/fuseop foils/$foil -q)
fi

cd xfoil
if [ ! -f "../polars/$foilname-50000.pol" -o ! -f "../polars/$foilname-100000.pol" -o ! -f "../polars/$foilname-200000.pol" ]
then
echo "PLOP" | tee cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
echo "G" | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
echo ""  | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
echo "LOAD ../foils/$foil" | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
echo "MDES" | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
echo "FILT" | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
echo "EXEC" | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
echo "" | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
echo "PANE" | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
echo "OPER" | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
echo "ITER 70" | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
echo "RE 50000" >> cmds1-$foilname.txt
echo "VISC 50000" >> cmds1-$foilname.txt
echo "RE 100000" >> cmds2-$foilname.txt
echo "VISC 100000" >> cmds2-$foilname.txt
echo "RE 200000" >> cmds3-$foilname.txt
echo "VISC 200000" >> cmds3-$foilname.txt
echo "PACC" | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
echo "../polars/$foilname-50000.pol" >> cmds1-$foilname.txt
echo "../polars/$foilname-100000.pol" >> cmds2-$foilname.txt
echo "../polars/$foilname-200000.pol" >> cmds3-$foilname.txt
echo "" | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
for i in $(seq 0 $MAX)
do
	alpha=$(echo "$i/$DIV" | bc -l | awk '{printf("%g\n",$1)}') 
	echo "ALFA $alpha" | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
	echo "ALFA $alpha" | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
	echo "ALFA $alpha" | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
	echo "INIT" | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
done
echo "PACC" | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
echo "VISC" | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
echo "" | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
echo "QUIT" | tee -a cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt
fi

if [ ! -f "../polars/$foilname-50000.pol" ]
then
	timeout 10m ./xfoil < cmds1-$foilname.txt || timeout 10m ./xfoil < cmds1-$foilname.txt || timeout 10m ./xfoil < cmds1-$foilname.txt	
fi

if [ ! -f "../polars/$foilname-100000.pol" ]
then
	timeout 10m ./xfoil < cmds2-$foilname.txt || timeout 10m ./xfoil < cmds2-$foilname.txt || timeout 10m ./xfoil < cmds2-$foilname.txt
fi

if [ ! -f "../polars/$foilname-200000.pol" ]
then
	timeout 10m ./xfoil < cmds3-$foilname.txt || timeout 10m ./xfoil < cmds3-$foilname.txt || timeout 10m ./xfoil < cmds3-$foilname.txt
fi

rm -f cmds1-$foilname.txt cmds2-$foilname.txt cmds3-$foilname.txt

cd ..

cd polars
for re in 50000 100000 200000
do
	START=0
	INITREAD=0
	PREVCL=0
	CL1=0
	CLH=0
	CD1=0
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
			ret=$(echo "$CL1 > $CLH" | bc)
			if [ "$ret" -eq "1" ]
			then
				CLH=$CL1
			fi
		fi 
	
		if [[ $line == *------* ]]
		then
			START=1
		fi

	done < "$foilname-$re.pol"
	CL=$(echo "$CLH + $CL" | bc -l | awk '{printf("%g\n",$1)}')
	CM=$(echo "$CM1 + $CM" | bc -l | awk '{printf("%g\n",$1)}')
	CD=$(echo "$CD1 + $CD" | bc -l | awk '{printf("%g\n",$1)}')
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
echo "clmax: $CL cm0: $CM cd0: $CD" >> $OUTFILE

sorted=$(sort -gr $OUTFILE)

echo "$sorted" > $OUTFILE

rm $OUTFILE.lock
