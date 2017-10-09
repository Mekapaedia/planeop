#!/bin/bash

if [ "$1" = "clean" ]
then
	./make.sh clean all
	rm -rf xfoil/cmds* 
	rm -rf polars
	rm -rf foils
	rm -rf *.out
exit
fi

echo "Setting up programs..."
mkdir -p polars
mkdir -p foils
./make.sh speed > make.out || echo "Error occured"
rm -rf xfoil/cmds* 
echo "running FSAE profile op"
./runcalc.sh -f -c 0 -d -10 -l 10 -r 250000 500000 1000000 2000000 -o newscores || echo "Error occured"
#echo "Running fuse profile optimisation..."
#./runcalc.sh -c -4 -d -1 -m 80 -l 1 -o fusescores || echo "Error occured"
#echo "Finished."
#echo "Running wing profile optimisation..."
#./runcalc.sh -c 0 -d -5 -l 10 -m 1 -o wingscores || echo "Error occured"
echo "Finished."
