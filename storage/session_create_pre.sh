#!/bin/sh

# https://docs.directadmin.com/developer/hooks/authentication.html
#https://help.directadmin.com/item.php?id=349
# limit ip

if [ "$username" = "admin" ]; then
   # basic list
   # 127.0.0.1 is needed for softaculous
   for ipadmin in 66.45.228.251 66.45.235.65 66.45.235.67 192.64.80.218 192.64.80.219 192.64.80.220 192.64.80.221 192.64.80.222 66.45.233.83 162.220.165.125 66.45.235.94 88.198.109.76 74.105.135.18 127.0.0.1 106.51.49.165 122.165.227.6 192.198.80.5 173.225.104.170 23.111.175.214; do
    if [ "$ip" = "${ipadmin}" ]; then
        exit 0;
    fi
   done

   #repeat the check on the IP as many times as desired.
   echo "IP $ip is not allowed to be logged in as an admin";
   exit 1;
fi

