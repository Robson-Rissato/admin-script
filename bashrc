#!/bin/sh

# /************************************************************************************\
# * Trouble Free Admin Center                                                          *
# * (c)2002 Interserver.net                                                            *
# * ---------------------------------------------------------------------------------- *
# * Description:  Install default bashrc file                                          *
# \************************************************************************************/

md5sum=4ad25997244edea639e6f70980f9ccad
mirror=mirror.trouble-free.net

if [ ! -e "/root/tmp" ]; then
	mkdir -p /root/tmp
fi

echo "Downloading Source"
wget http://$mirror/jq/bashrc --directory-prefix=/root/tmp >/dev/null 2>&1

if [ -e /etc/master.passwd ]; then
	checksum="$(/sbin/md5 -q /root/tmp/bashrc)";
else
	checksum="$(md5sum /root/tmp/bashrc | cut -d" " -f1)";
fi

if [ "$md5sum" = "$checksum" ]; then
	echo "Checksum matches, installing"
	mv -f /etc/bashrc /etc/bashrc.old
	mv -f /root/tmp/bashrc /etc
	chmod 644 /etc/bashrc
	if [ ! -e /etc/master.passwd ]; then
		source /etc/bashrc 
	fi
else
	echo "Checksum Down not match ($md5sum != $checksum)"
fi

rm -f /root/tmp/bashrc
