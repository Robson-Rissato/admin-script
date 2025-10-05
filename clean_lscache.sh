#!/usr/bin/env bash

if [ ! -x /usr/local/lsws/admin/misc/cleancache.sh ]; then
        echo 'Missing /usr/local/lsws/admin/misc/cleancache.sh';
        exit;
fi

if [ ! -d /home ]; then
	echo 'Missing /home';
	exit;
fi

if [ ! "$1" = "run" ] ; then
	echo 'Not running live. Add ./clean_lscache.sh run - to make the changes';
	sleep 2s;
fi

for i in `find /home -maxdepth 1 -type d | grep ^/home`; do
        #if lscache/priv exists we are using lscache
        if [ -d $i/lscache/priv ]; then
                echo "$i has lscache dir";
                cd $i/lscache
                # lets confirm
                pwcheck=`pwd`;
                if [ "$pwcheck" = "$i/lscache" ]; then
			if [ "$1" = "run" ]; then
                        	bash -x /usr/local/lsws/admin/misc/cleancache.sh $i/lscache
			else
				echo /usr/local/lsws/admin/misc/cleancache.sh $i/lscache	
			fi
                else
                        echo "Error: could not enter $i/lscache";
                fi
        fi
done

