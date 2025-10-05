#!/bin/bash

# modified 8/22/2025

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

source /admin/includes/common_bash_functions

# touch /vz/qsXXXX/skiptemplates to skip templates - this allows to skip templates for a qs until cancelled
# touch /admin/.info/skiptemplates to globally skip (it will never run again unless removed)
# /admin/kvmgettemplate.sh to also verify templates

#/dev/vz/mytemplates
#
# lvcreate vz -L75000 -nmytemplates && mkfs.ext3 /dev/vz/mytemplates; mkdir -p /templates; mount /dev/vz/mytemplates /templates; echo "/dev/vz/mytemplates     /templates              ext3    defaults        0 0" >> /etc/fstab
#
#

# zfs
# zfs create vz/templates
# you could also - zfs set quota=120G vz/templates
# we run 5 4 * * * rsync --delete -v --exclude=*.xz --inplace -a rsync://kvmtemplates.is.cc/templates/ /vz/templates/ >/dev/null 2>&1
# so you need to add the ip to this template server too


# these are the rsync mirror servers in nj
servers='
vpsadmin.interserver.net\n
vpsadmin1.interserver.net
'

hostname=`hostname`;
# use an alternative mirror
if [[ $hostname =~ (dfw|lax) ]]; then
	mirror=157.250.201.60;
else
	# remove new line tr with leading space awk
	mirror=`echo -e $servers | sort --random-sort | head -n 1 | tr -d "\n" | awk '{print $1}'`;
fi

# this is the worker folder
if [ ! -d /root/cpaneldirect ]; then
	exit;
fi

if [ -x /usr/bin/bc ]; then
        RAN=`echo $RANDOM % 100 | /usr/bin/bc`;
else
        RAN=14400;
fi

if [ ! -z "$PS1" ]; then
        echo "sleeping $RAN minutes";
        sleep ${RAN}m
else
        echo 'Interactive run';
fi

if [ -x /root/cpaneldirect/provirted.phar ]; then
	if [ ! -e /usr/local/sbin/provirted ]; then
		ln -s /root/cpaneldirect/provirted.phar /usr/local/sbin/provirted
	fi
fi

mkdir -p /root/tmp

# start kvmv2 templates here
if [ -e /sbin/zfs ]; then
	echo 'KVMv2 Templates';
	# use -e in case we want a symlink
	if [ ! -e /vz/templates ]; then
		echo 'Creating /vz/templates';
		zfs create vz/templates; zfs set quota=200G vz/templates; zfs set compression=gzip vz/templates
	fi
	if [ -d /vz/templates ]; then 
		# set latest quota
		zfs set quota=200G vz/templates; zfs set compression=gzip vz/templates

		# add ability to skip templates
		skip=0;
		qscheck=`/admin/includes/check_for_qs`;
		if [ ! "$qscheck" = "" ]; then
			#
			# quick servers will have zfs arc off to save ram
			# this is because qs users want to see their full ram
			# it will over commit if arc is also in use
			# has occured on a few qs systems
			#
			zfs set primarycache=metadata vz/${qscheck}
			if [ -f /vz/${qscheck}/skiptemplates ]; then
				echo "skipping templates due to /vz/${qscheck}/skiptemplates";
				skip=1;
			fi
		fi

		if [ -f /admin/.info/skiptemplates ]; then
			skip=1;
			echo 'Skipping templates due to /admin/.info/skiptemplates';
		fi

		ploopcheck=`ls /vz | grep ploop$`;
		if [ ! "$ploopcheck" = "" ]; then
			echo "Skipping templates due to ploop image found";
			skip=1;
		fi

		if [ "$skip" = "0" ]; then
			echo "Using mirror $mirror";
			sleep 1s;
			/usr/bin/flock -n /tmp/rsync.lock rsync --timeout=20000 --exclude=windows*qcow* --exclude plesk.qcow2 --exclude storage.raw.gz -av --progress --inplace --skip-compress=qcow2 -W rsync://$mirror/qcow2/ /vz/templates/
			didwecomplete;
			sleep 2s;
			if [ -f /vz/templates/plesk.qcow2 ]; then /bin/rm -v /vz/templates/plesk.qcow2; fi
                        if [ -f /vz/templates/storage.raw.gz ]; then /bin/rm -v /vz/templates/storage.raw.gz; fi
			for oldfiles in fedora-30.qcow2 fedora-30.qcow2.sha1 fedora-36.qcow2 fedora-36.qcow2.sha1 centos-8.2.qcow2 centos-8.2.qcow2.sha1 centosstream-8.qcow2 centosstream-8.qcow2.sha1 centosstream-9.qcow2.sha1 windows10.qcow2.sha1 windows2012.qcow2.sha1 windows2019.qcow2.sha1 windowsr2.qcow2.sha1 ubuntu-16.04.qcow2.sha1 ubuntu-16.04.qcow2 ubuntu-14.04.qcow2.sha1 ubuntu-14.04.qcow2 ubuntu-12.04.qcow2.sha1 ubuntu-12.04.qcow2 ubuntu-10.04.qcow2.sha1 ubuntu-10.04.qcow2 scientificlinux-6.qcow2.sha1 scientificlinux-6.qcow2 windowsr2.qcow2 windows2012.qcow2 windows2019.qcow2 windows10.qcow2 debian11gpt.qcow2 debian11gpt.qcow2.sha1 plesk.qcow2 storage.raw.gz FreeBSD-10.4-RELEASE-amd64.qcow2 FreeBSD-10.4-RELEASE-amd64.qcow2.sha1 FreeBSD-11.2-RELEASE-amd64.qcow2 FreeBSD-11.2-RELEASE-amd64.qcow2.sha1 FreeBSD-11.3-RELEASE-amd64.qcow2 FreeBSD-11.3-RELEASE-amd64.qcow2.sha1 FreeBSD-12.1-RELEASE-amd64.qcow2 FreeBSD-12.1-RELEASE-amd64.qcow2.sha1; do
				if [ -f /vz/templates/$oldfiles ]; then
					/bin/rm -v /vz/templates/$oldfiles
				fi
			done
		fi

		if [ "$1" = "verify" ]; then
			echo 'Verify to be reworked';
		fi
	else
		echo 'Failed to create /vz/templates dataset';
	fi
else
	echo 'No zfs detected';
fi

# zfs points to qcow images (kvmv2)
# much faster placing all templates here
if [ -e /sbin/zfs ]; then
	if [ -e /proc/sys/vm/overcommit_memory ]; then
		echo 1 > /proc/sys/vm/overcommit_memory
	fi
elif [ -e /dev/vz/mytemplates ]; then
	echo "KVMv1";
	echo 'Please upgrade from KVMV1';
fi
echo 'Done with templates';

if [ -x /admin/upscripts ]; then
	/admin/upscripts > /dev/null 2>&1
fi

if [ ! -x /root/cpaneldirect/upscripts ]; then
	/usr/bin/flock -n /tmp/rsync.lock rsync --timeout=20000 -av rsync://vpsadmin.interserver.net/vps/cpaneldirect/ /root/cpaneldirect/
	didwecomplete;
else
	/root/cpaneldirect/upscripts > /dev/null 2>&1
fi

if [ ! -e /cloud ]; then
        if [ ! -x /scripts/upscripts ]; then
                /usr/bin/flock -n /tmp/rsync.lock rsync --timeout=20000 -av rsync://vpsadmin.interserver.net/vps/kvm/ /scripts/
		didwecomplete;
        else
                /scripts/upscripts > /dev/null 2>&1
        fi
fi
