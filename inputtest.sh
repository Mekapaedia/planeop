REYNOLDS=""

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
		*)
			break
			;;
	esac
done


for i in $REYNOLDS
do
	echo $i
done
