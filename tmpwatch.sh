#!/bin/bash

if [ ! -e /etc/redhat-release ]; then
	echo 'Requires REDHAT';
	exit;
fi

if [ ! -x /usr/sbin/tmpwatch ]; then
	echo 'Requires TMPWATCH';
	exit;
fi

chmod 1777 /tmp
chown root:root /tmp

/usr/sbin/tmpwatch -v -c 8 /tmp
/admin/mysqlsymlink

if [ -e /var/cache/eaccelerator ]; then
	/usr/sbin/tmpwatch -v -c 24 /var/cache/eaccelerator
fi

#modsec check
folder=`date +%Y%m%d`;
if [ -d /tmp/$folder ]; then
	echo "Found /tmp/$folder for mod_security";
	# don't run if somehow we are blank
	if [ ! "$folder" = "" ]; then
		/usr/sbin/tmpwatch -v -c 2 /tmp/$folder
	fi
fi
