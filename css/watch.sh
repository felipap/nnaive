while true
do
	sleep .1
	echo $(date)
	lessc main.less main.css -x
	if [[ $? != 0 ]]
		then beep -f 200 -l 5
		sleep 1
	fi
done
