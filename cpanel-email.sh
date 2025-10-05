#!/bin/sh

/admin/mkdirs.sh

dir="/admin/.info/backup_config/cpanel-email";
today="$(/bin/date +%m-%d-%y)";

for user in $(ls /var/cpanel/users/); do
	i="$(grep ^$user /etc/passwd | cut -d: -f6)"; 
	if [ ! "$i" = "" -a ! "$user" = "" ]; then
		if [ -e $i/etc ]; then 
			echo "Working on $user";
			tar -zcf $dir/$user-$today.tgz $i/etc/
		fi
	fi 
done
