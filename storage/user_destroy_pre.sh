#!/bin/bash

if [ ! "$username" = "" ]; then
	# if redis exists we need to check for a socket
	#ps auxw | grep [r]edis-server | grep unixsocket | grep ^st39062 | awk '{print $2}'
	if [ -x /usr/local/bin/redis-server ]; then
		#there will be only one pid any way
		redispid=`ps auxw | grep [r]edis-server | grep unixsocket | grep ^${username} | awk '{print $2}' | tail -n 1`;
		if [[ $redispid =~ ^[-+]?[0-9]+$ ]]; then
			kill -9 $redispid
			sleep 2;
		fi
	fi
        /usr/sbin/zfs destroy vz/${username} -r
fi

