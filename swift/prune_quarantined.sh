#!/bin/bash

# John Quaglieri
# john@interserver.net
# 6.5.2018
# for swift data nodes
# clean out quarantined

# only run on swift nodes
if [ ! -e /etc/swift/swift.conf ]; then
	echo 'Missing swift.conf';
	exit;
fi

# this folder must exist
if [ ! -d /srv/node ]; then
	echo 'Missing /srv/node';
	exit;
fi

# we only use ubuntu or centos, thus tmpwatch or tmpreaper is used based on the os
if [ -f /etc/debian_version ]; then
	if [ ! -x /usr/sbin/tmpreaper ]; then
		/admin/upscripts && /admin/upgradedebs && apt-get -y install tmpreaper
		exit;
	fi
# for centos
elif [ -e /etc/redhat-release ]; then
	if [ ! -x /usr/sbin/tmpwatch ]; then
		yum -y install tmpwatch
		exit;
	fi
# we shouldn't get here but if we do needs further look
else
	echo 'OS not supported';
	exit;
fi

# we exit if any install is done to check the output


# actually start the work
cd /srv/node
for disk in *; do
	if [ -d /srv/node/${disk}/quarantined ]; then
		echo "Working on $disk";
		sleep 1s;
		# rhel
		if [ -x /usr/sbin/tmpwatch ]; then
			tmpwatch -c 256 -v /srv/node/${disk}/quarantined
		# ubuntu
		elif [ -x /usr/sbin/tmpreaper ]; then
			tmpreaper -c 256 -v /srv/node/${disk}/quarantined
		# we should not get there
		else
			echo 'No tmpwatch or tmpreaper installed';
		fi
		echo
	fi
done
