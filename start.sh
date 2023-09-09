#!/bin/bash

DT=$(date +"%Y-%m-%d")
H=$(date +"%H")
H=`echo $H|sed 's/^0*//'`

H1="9"
H2="14"
H3="19"

RES=$(mysql -uroot -Ne "select triggertime from basecheck_active limit 1;" crm)

if (( "$RES" == "$DT" ))
then
	if (( "$H" == "$H1" ))
	then
		RES=$(mysql -uroot -Ne "update basecheck_active set step1=1, completed=1;" crm)
	elif (( "$H" == "$H2" ))
	then	
		RES=$(mysql -uroot -Ne "update basecheck_active set step2=1;" crm)	
	elif (( "$H" == "$H3" ))
	then
		RES=$(mysql -uroot -Ne "update basecheck_active set step3=1;" crm)
	fi	
fi	