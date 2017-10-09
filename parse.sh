#!/bin/bash
while read line
do
	echo $line | sed -e 's/\s/ /g' >> $1.parsed
done < $1

if [ -s $1.parsed ]
then
	mv $1.parsed $1
fi
