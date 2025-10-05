#!/bin/bash

for cpanel_user in $(ps axo user:20,args:50 | grep /usr/bin/perl | grep -v ^root | awk '{print $1}' | sort | uniq); do
        user_home=$(grep ${cpanel_user} /etc/passwd | cut -d: -f6);
        if [ -e ${user_home}/.cagefs/tmp ]; then
                echo "Scanning ${cpanel_user}";
                cd ${user_home}/.cagefs/tmp
                /admin/clamscan justdb q
                if [ "$?" = "1" ]; then
                        echo "  Malware found running pkill -9 -u ${cpanel_user} perl";
                        pkill -9 -u ${cpanel_user} perl
                fi
        fi
done

