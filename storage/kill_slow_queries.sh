#!/usr/bin/env bash

# directadmin
check=`which mysqladmin`;

if [ ! -x $check ]; then
        echo 'Missing mysqladmin';
	exit;
fi

if [ ! -d /usr/local/directadmin ]; then
        echo 'Tested only on directadmin';
        exit;
fi
#191737:opinyati_opinyat:21
# added egrep ^ as we must start with a number (Pid)
# and egrep $ as we must end with a number (sleep time)
for data in `mysqladmin processlist | egrep "SELECT|Sleep" | egrep -v "da_admin|root" | awk '{print $2 ":" $4 ":" $12 }' | egrep "^[1-9]" | egrep "[0-9]$"`; do
        time=`echo $data | cut -d: -f3`;
        if [ "$time" -gt "60" ]; then
                pid=`echo $data | cut -d: -f1`;
                db=`echo $data | cut -d: -f2`;
                echo "Killing $pid for $db as query is at $time";
                mysqladmin kill $pid
        fi
done

