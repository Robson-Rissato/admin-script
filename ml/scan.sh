#!/bin/bash

#version=1.06.30.2017;

# quick check makes sense for size or very high load
# but not for other cases. We still need to get a sha256sum
# the only change is we do not curl post the file to the remote
# server which is questionable which has more load sha256sum or curl

# by default no quick check
quickcheck=0;

# the page we load
ENDPOINT=s;

# log file
log=/tmp/scanner.log

# this is available over https
SERVER='http://scanner.interserver.net';

# load av trigger
TRIGGER=30;

# don't change below
FILE=$1;

if [ "$1" = "" ]; then
        echo '1 no file to scan';
        exit;
fi

# for the log
date=$(date);

# if the file does not exist bail
if [ ! -f "${FILE}" ]; then
        echo '1 file ${FILE} does not exist';
        exit;
fi

# connecting ip
if [ ! "$HTTP_CF_CONNECTING_IP" = "" ]; then
        userip=$HTTP_CF_CONNECTING_IP;
else
        userip=$REMOTE_ADDR;
fi

# rbldnsd is updated so we could do ipv6 now
#ipv6 not supported for now until rbldns updated
if [[ ! $userip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        userip='failedregex';
fi

LOADAV=$(cat /proc/loadavg | awk -F \. '{print $1}');
if [[ "$LOADAV" -gt "$TRIGGER" ]]; then
	quickcheck=1;
	echo "INFO $date quickchecked ${FILE} due to load av $LOADAV $DOCUMENT_ROOT $SCRIPT_NAME $userip" >> $log
else
	# skip files too large to improve speed
	if [ -x /usr/bin/stat ]; then
        	size=$(stat -c%s $FILE);
		# 3mb limit for speed
        	if [ ! "$size" -lt "3000000" ]; then
                	echo "INFO $date quickchecked ${FILE} due to size $size $DOCUMENT_ROOT $SCRIPT_NAME $userip" >> $log
			quickcheck=1;
        	fi
	fi
fi

# add ip validation
if [ "$quickcheck" = "1" ]; then
        hash=$(sha256sum ${FILE} | awk '{print $1}');
        if [[ "$hash" =~ [A-Fa-f0-9]{64} ]]; then
                scanfile=$(curl --silent --connect-timeout 10 -X POST --form "submit=quickcheck" --form "hash=${hash}" ${SERVER}/${ENDPOINT});
        else
                echo "INFO $date error on ${FILE} has ${hash} failed validation on quickcheck" >> $log
        fi
else
	scanfile=$(curl --silent --connect-timeout 10 -X POST --form "submit=apache" --form "ipaddr=$userip" --form "fileToUpload=@$FILE" ${SERVER}/${ENDPOINT});
fi

# some error checking
if [ "${scanfile}" = "" ]; then
        echo "1 filescan of ${FILE} to ${SERVER} timed out";
        echo "INFO $date scanned ${FILE} and timed out to ${SERVER}" >> $log
else
        echo "${scanfile}";
fi

date=$(date);
# user ip must be last
echo "$date scanned ${FILE} and returned ${scanfile} ${DOCUMENT_ROOT}/${SCRIPT_NAME} $userip" >> $log

# can be used for debugging
#echo >> $log
#printenv >> $log
#echo >> $log
