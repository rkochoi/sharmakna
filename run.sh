#!/bin/bash

DT=$(date +"%Y-%m-%d")
DT2=$(date +"%Y-%m-%d %H:%M:%S")


CHK=$(ps aux | grep run | grep basecheck | grep -v grep | grep -v log | wc -l)
if [ $CHK -gt 2 ];then 
	echo "$DT2  Basecheck program already running.. exiting" >> /var/log/basecheck/run.log
	exit 0
fi


RES=$(mysql -uroot -Ne "select pause from basecheck_active limit 1;" crm)
if [ $RES -eq 1 ]; then
		exit 0
fi

RES=$(mysql -uroot -Ne "select completed from basecheck_active limit 1;" crm)
if [ $RES -eq 1 ]; then

	BASE=$(mysql -uroot -Ne "select basename from basecheck_active limit 1;" crm)
	RES1=$(mysql -uroot -Ne "select step1 from basecheck_active limit 1;" crm)
	RES2=$(mysql -uroot -Ne "select step2 from basecheck_active limit 1;" crm)
	RES3=$(mysql -uroot -Ne "select step3 from basecheck_active limit 1;" crm)
	for i in 1 2 3
	do
		
		if (( "$RES1" == "1" ))
		then
			cmd="/usr/bin/perl /etc/asterisk/basecheck/logic.pl 0 $BASE > /dev/null 2>&1"
			eval $cmd
		fi
			
		if (( "$RES2" == "1" ))
		then
			cmd="/usr/bin/perl /etc/asterisk/basecheck/logic.pl 1 $BASE > /dev/null 2>&1"
			eval $cmd
		fi	

		if (( "$RES3" == "1" ))
		then
			cmd="/usr/bin/perl /etc/asterisk/basecheck/logic.pl 2 $BASE > /dev/null 2>&1"
			eval $cmd
		fi
		if [ $i -lt 3 ]
		then
			sleep 8
		fi
	done
else
	exit 0				
fi
