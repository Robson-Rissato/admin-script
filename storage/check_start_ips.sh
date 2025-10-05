#!/usr/bin/env bash

# directadmin looses start ips in ubuntu after apt update?

function check_ip()
{
        ip=$1;
        if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                return 1;
        else
                return 0;
        fi
}

#directadmin only
if [ ! -d /usr/local/directadmin ]; then
	exit;
fi

# ubuntu only
if [ ! -x /usr/bin/apt ]; then
	exit;
fi


short=`hostname -s`;
if [ "$short" = "" ]; then
        echo 'error got back blank for short hostname';
        exit;
fi

check=`timeout 10 dig +short ${short}b.trouble-free.net`;
check_ip $check
if [ "$?" -eq 1 ]; then
        ipcheck=`ip addr | grep "inet $check"`;
        if [ "$ipcheck" = "" ]; then
                echo 'start ips is bad';
		if [ -x /usr/local/directadmin/scripts/startips ]; then
			/usr/local/directadmin/scripts/startips start
		fi
        else
                echo 'start ips is good';
        fi
else
        echo "$check is not a valid ip";
fi

