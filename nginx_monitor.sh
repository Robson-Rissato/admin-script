#!/bin/sh

enabled=`cat /var/cpanel/cpanel.config  | grep ^apache_port= | cut -d: -f2`;
if [ ! "$enabled" = "81" ]; then
        echo "nginx not enabled";
        exit;
fi

check=`ps auxw | grep nginx | grep master`;
if [ "$check" = "" ]; then
        killall nginx
        /usr/local/nginx/sbin/nginx
        echo "restarted nginx"
else
        echo "Nginx running";
fi
