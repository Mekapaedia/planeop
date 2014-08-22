#!/bin/bash

OCFLAGS="-c"
OLDFLAGS=
OLIBS=

DFLAGS="-ggdb3 -pg -O0 -Wall -Wextra -pedantic -Wdeclaration-after-statement \
-Wshadow -Wpointer-arith -Wcast-qual -Wstrict-prototypes -Wmissing-prototypes \
-Wno-missing-braces -Wno-missing-field-initializers -Wformat=2 \
-Wswitch-default -Wswitch-enum -Wcast-align -Wpointer-arith \
-Wbad-function-cast -Wstrict-overflow=5 -Wstrict-prototypes -Winline \
-Wundef -Wnested-externs -Wcast-qual -Wunreachable-code \
-Wlogical-op -Wfloat-equal -Wstrict-aliasing=2 -Wredundant-decls \
-Wold-style-definition -Wwrite-strings \
-fno-omit-frame-pointer -ffloat-store -fno-common -fstrict-aliasing \
-fprofile-arcs -ftest-coverage"

DCFLAGS="$DFLAGS $OCFLAGS"
DLDFLAGS="$DFLAGS $OLDFLAGS"
DADDLIBS="$OLIBS -lgcov"

SFLAGS="-O3 -march=native -fomit-frame-pointer"

SCFLAGS="$SFLAGS $OCFLAGS"
SLDFALGS="$SFLAGS $OLDFLAGS"
SADDLIBS="$OLIBS"

XFOILDIR=xfoil

if [ `uname -o` = "Cygwin" ]
then
	XFOILURL="http://web.mit.edu/drela/Public/web/xfoil/XFOIL6.99.zip"
	XFOIL=xfoil.exe
	XFOILFILES="xfoil.exe pxplot.exe pplot.exe Xfoil699src.zip"
	XFOILARC="XFOIL6.99.zip"
	ARCCOM="unzip -o"
#FIXME
#Support for Linux is NOT complete.
elif [ `uname -o` = "GNU/Linux" ]
then
	XFOILURL="http://web.mit.edu/drela/Public/web/xfoil/xfoil6.99.tgz"
	XFOIL=xfoil
	XFOILARC="xfoil6.99.tgz"
	ARCCOM="tar xvf"
fi

if [ "$1" = "clean" ]
then
	make -C fuseop/ clean
	rm -rf gmon.out
	if [ "$2" = "all" ]
	then
		cd $XFOILDIR
		rm -rf $XFOILFILES $XFOILARC
		cd -
	fi
else
	mkdir -p $XFOILDIR	
	cd $XFOILDIR
	for file in $XFOILFILES
	do 
		if [ ! -f $file ]
		then
			if [ ! -f $XFOILARC ]
			then
				wget $XFOILURL
			fi
			$ARCCOM $XFOILARC
		fi
	done
	cd -	
	if [ "$1" = "speed" ]
	then
		make -C fuseop/ "CFLAGS=$SCFLAGS" "LDFLAGS=$SLDFLAGS" "ADDLIBS=$SADDLIBS"
	else
		make -C fuseop/ "CFLAGS=$DCFLAGS" "LDFLAGS=$DLDFLAGS" "ADDLIBS=$DADDLIBS"
	fi
fi
