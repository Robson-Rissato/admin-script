#!/bin/bash

# 0 debug off 1 debug on
DEBUG=0;

if [ "$DEBUG" = "0" ]; then

        echo() { :; }
fi

if [ ! -d /root/cpaneldirect ]; then
	exit;
fi

if [ -e /usr/local/lsws ]; then
        lscheck=$(ps auxw | grep [l]itespeed | grep ^root);
        if [ "$lscheck" = "" ]; then
                echo 'Litespeed not running';
                /usr/local/lsws/bin/lswsctrl restart
        else
                echo 'Litespeed is running';
		# restart detached php hourly for now
		if [ -d /usr/local/lsws/admin/tmp ]; then
			# litespeed should have removed this file automatically if not we remove it we will restart detached the next hour
			if [ -f /usr/local/lsws/admin/tmp/.lsphp_restart.txt ]; then
				/bin/rm /usr/local/lsws/admin/tmp/.lsphp_restart.txt
			else
				touch /usr/local/lsws/admin/tmp/.lsphp_restart.txt
			fi
		fi
        fi
        apcheck=$(ps auxw | grep "[u]sr/sbin/httpd -k start" | grep ^root);
        if [ ! "$apcheck" = "" ]; then
                echo 'Apache is running, but should not be.';
                killall -9 httpd
                /usr/local/lsws/bin/lswsctrl restart
        else
                echo 'Apache not running';
        fi
else
        echo 'Litespeed not installed';
fi
