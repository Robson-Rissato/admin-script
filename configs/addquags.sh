#!/usr/bin/env bash

#pw user add quags

if [ -f /etc/passwd ]; then
        user_check=`grep ^quags: /etc/passwd`;
else
	echo '/etc/passwd does not exist';
	exit;
fi

# check if user quags exists
if [ "$user_check" = "" ]; then
	echo 'User quags does not exist continuing';
else
	echo 'User quags exists existing';
	exit;
fi

# sudo file for ansible we need sudo installed to work
if [ ! -d /etc/sudoers.d -a ! -d /usr/local/etc/sudoers.d ]; then
	echo 'sudoers.d does not exist or is not a directory';
	if [ -f /etc/master.passwd ]; then
		echo 'install with pkg install sudo';
	elif [ -x /usr/bin/yum ]; then
		echo 'install with yum install sudo';
	elif [ -x /usr/bin/apt ]; then
		echo 'install with apt install sudo';
	fi
        exit;
fi

# skip if this exists as it should not
if [ -e /etc/sudoers.d/quags -a -e /usr/local/etc/sudoers.d/quags ]; then
	echo '/etc/sudoers.d/quags exists already';
        exit;
fi

if [ -d /usr/local/etc/sudoers.d ]; then
	echo 'quags  ALL=(ALL)       ALL' > /usr/local/etc/sudoers.d/quags
else
	echo 'quags  ALL=(ALL)       ALL' > /etc/sudoers.d/quags
fi

if [ -f /etc/master.passwd ]; then
	pw user add quags
	passwd quags
else	
	# add user on linux
	adduser quags	
	# debian will ask to set a password (ubuntu too)
	if [ ! -e /etc/debian_version ]; then
		passwd quags
	fi
fi

# add ssh key
mkdir -p /home/quags/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDMOf7zoCq2279qFSBfxECo/8jOSyUrkSBQok0SJG4+3dHGhNWo1jB9GDuJbVeT0S41/KLNrUScHvf2S3iij1G09hDAllfoMsGTTOxqL8jHj35iSuhohDjSuFr2kBCnSxTBjD0M/BTvX5xdnOEvlrOw6aqh0/I1/Pe2Tf+lQv4EQiKUvKWD3O90TAyqL6y5UkzHLW0S5kGhTVIp3IZjXvGsnslc3Y1Bz2VHaSfc/cwy/hOcldSPE+hMiCPXxznvmtttDXgpgMhDZkY4XsGfp5PbWxXlGYK74kmfZ1wmO0/nPI8pvYmUDrVwCHLwMV4zOsYM6WZevtDPhONH/unrDIUQ5IA2aLSbZowpPQZikPHwYNipYbL+6IOrwnquvxyEKIwVSSstexKhOfOmMksNdoSGH2PNk+08FUPIv83DxVgTVcC0sJotfhgriit4P0YbMMZXah3rbxQ1kRfcHDLs0wPf8sdToXMkqPc88SOWoU8RptEE+UYhQTDQDHfEcRzsKntbt0JNjdFbDW3kACe2CiwWCbRnxgHX0p51vvTSQmsBmDQqf2ozwgmgtZG6kCc89B6WnB13IJxyw1yJBnTfqee9DYNyqII75uZ1Hl0DjFOBGCRX3qC72caZ0KF6RjNz0DdvvFNlGtRTxRmO2xcQu+7rlQqBGRJ4ywKEyeWTaHg5oQ== quags@ansible.is.cc" > /home/quags/.ssh/authorized_keys
chown -R quags:quags /home/quags
chmod 700 /home/quags/.ssh
chmod 600 /home/quags/.ssh/authorized_keys

# only do this if we already restrict ssh
checkssh=`grep root@66.45.228.251 /etc/ssh/sshd_config`
if [ "$checkssh" = "" ]; then
	echo 'skipping adding allowuser to sshd_config because tech allow user is not there';
	sleep 1s;
else
	echo "AllowUsers quags@64.20.60.242" >> /etc/ssh/sshd_config
fi

if [ ! -f /etc/master.passwd ]; then
	echo "sshd: 64.20.60.242" >> /etc/hosts.allow
fi

# can not do this on webhosting
# password auth off that is
if [ -e /usr/local/cpanel/cpanel ]; then
	usermod -aG wheel quags
else
	if [ -f /etc/master.passwd ]; then
		pw group mod wheel -m quags
	else
		usermod -aG wheel quags
		/admin/replace-linux "PasswordAuthentication yes" "PasswordAuthentication no" -- /etc/ssh/sshd_config
	fi
fi
# most linux servers
if [ -e /usr/bin/systemctl -o -e /bin/systemctl ]; then
	systemctl stop sshd.service; systemctl start sshd.service
# freebsd
elif [ -x /etc/rc.d/sshd ]; then
	/etc/rc.d/sshd restart
else
	service sshd restart
fi
