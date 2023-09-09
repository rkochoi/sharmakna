#!/bin/bash


ID=$1
NUM=$2
DB=$3
NAME=$4

if [ -z "$NUM" ];then

	exit 1

else

	mysql -uroot -e"insert into failed set number='$NUM', basename='$DB',calldate=now(),name='$NAME'" bases

fi

 
