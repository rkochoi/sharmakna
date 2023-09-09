#!/bin/bash


#---Autodial script, creates .call file in spool/outgoing, based on free operators logic---
#---Uses input parameters from logic script---

DT=$(date +"%Y-%m-%d %H:%M:%S")

DST=$1
BASE=$2
ID=$3
TRY=$4
NAME=$5

OP=1111
if [ $TRY -eq 0]
then
	CLID=74992132296
elif [ $TRY -eq 1 ]
then
	CLID=74992132314
elif [ $TRY -eq 2 ]
then
	CLID=74992132342
fi

DSTNUM=${DST}

#Channel: SIP/main_trunk1/$DSTNUM

read -r -d '' CALL << EOF
Channel: Local/2222@basecheck
CallerID: "$NAME" <$CLID>
Account: $NAME
WaitTime: 45
Set: basename=$BASE
Set: number=$DSTNUM
Set: id=$ID
Set: name=$NAME
Context: basecheck
Extension: $OP
Priority: 1
MaxRetries: 0
EOF

TMPPATH="/etc/asterisk/basecheck/tmpcalls/"
FILE="SIP-BASECHEK-$OP-$DSTNUM-`date +"%H%M%S"`.call"

echo "$CALL" > $TMPPATH$FILE && chown asterisk:asterisk $TMPPATH$FILE && mv $TMPPATH$FILE /var/spool/asterisk/outgoing/$FILE
echo "$DT  Passed $FILE for callout..." >> /var/log/basecheck/dial.log
