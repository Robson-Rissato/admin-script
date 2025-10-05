#!/bin/sh

enabled=`cat /var/cpanel/cpanel.config  | grep ^apache_port= | cut -d: -f2`;
if [ ! "$enabled" = "81" ]; then
        echo "nginx not enabled";
        exit;
fi

if [ -d /var/www/nginx ]; then
        cd /var/www
        mv nginx nginx.remove
        killall -HUP nginx
        rm -rf nginx.remove
else
        echo "No nginx cache folder";
fi
