#!/usr/bin/env bash

# 1.11.18.2019
# John Quaglieri
# InterServer, Inc
# john at interserver.net
#
# Copyright InterServer 2019
#
# This code is not released for public use
#

LOWLOAD=0;
LOCATION=/admin/scanner;
echo "Using $LOCATION";

# low load
TRIGGER=5;

# use db
export QUICKCHECK=0;

LOADAV=$(cat /proc/loadavg | awk -F \. '{print $1}');
if [[ "$LOADAV" -gt "$TRIGGER" ]]; then
	export QUICKCHECK=1;
fi

# try to limit load if this file exists
if [ -f ${LOCATION}/_lowload ]; then
	LOWLOAD=1;
	runcheck=$(ps ux | grep [/]admin/scanner/run.sh | grep ^root | wc -l);
	if [ "$runcheck" -gt "2" ]; then
		echo 'run.sh is already running under lowload set up';
		exit;
	fi
fi

# locate can cause issues on servers with high cpu / io
# use low locate to run less
if [ -f ${LOCATION}/_lowlocate ]; then
	export LOWLOCATE=1;
fi

run2check=$(ps ux | grep [/]admin/scanner/run2.sh | grep ^root);
if [ ! "$run2check" = "" ]; then
	echo 'Another run2.sh process is running';
	exit;
fi

lock_file="/root/tmp/_virusscanrun";

if [ -e $lock_file ]; then
        if [ "$(( $(date +"%s") - $(stat -c "%Y" $lock_file) ))" -gt "300" ]; then
                echo "$lock_file older than 300 seconds";
        else
                echo 'ERROR: Lock file found, exiting';
                exit;
        fi
fi

touch $lock_file

if [ -f ${LOCATION}/run2.sh ]; then
	if [ "$1" = "q" ]; then
		${LOCATION}/run2.sh
		echo 'Exit on fast run';
		exit;
	fi

	for times in 1 2 3 4 5 6 7 8; do
		if [ "$LOWLOAD" = "0" ]; then
			if [ "$times" = "1" ]; then
				export SLOW=1;
			fi
		else
			echo 'Running with low load';
		fi

		
		nice -n 2 ${LOCATION}/run2.sh
		echo -n 'end run ' 
		echo $times;
		echo

		if [ "$LOWLOAD" = "0" ]; then
			sleep 1s;
		else
			echo 'Sleeping for low load';
			sleep 1m;
		fi

		if [ "$times" = "1" ]; then
                        export SLOW=0;
                fi

		if [ "$times" = "8" ]; then
			# scan with clamav
			export QUICKCHECK=0;
			if [ "$LOWLOAD" = "0" ]; then
				sleep 5s;
				echo 'Time 9';
				${LOCATION}/run2.sh
			elif [ "$LOWLOCATE" = "1" ]; then
				sleep 5s;
				echo 'Time 9 with locate';
				export LOWLOCATE=0;
				${LOCATION}/run2.sh
			fi
		fi

	done

	# scan the current working dir
	# of dirs that malware was found in
	# only for 100% known malware
	if [ -f ${LOCATION}/scancwd ]; then
		if [ "$LOWLOAD" = "1" ]; then
			sleep 5m;
		fi
		
		nice -n 2 /usr/bin/flock -n /var/run/is_scwd.lock ${LOCATION}/scancwd

		
	else
		echo "${LOCATION}/scancwd not found";
	fi

	# process logs to find bad ips
	if [ -f /admin/modsecurity/badips.sh ]; then
		if [ -d /usr/local/lsws -o -f /etc/apache2/conf.d/lsapi.conf ]; then
			nice -n 2 /usr/bin/flock -n /var/run/is_bi.lock /admin/modsecurity/badips.sh
		fi
	fi

	# scan open files by php
	# it has caught a few things but overall seems to have a low effective rate
	if [ -f ${LOCATION}/openfile.sh ]; then
		if [ -d /usr/local/lsws -o -f /etc/apache2/conf.d/lsapi.conf ]; then
			nice -n 2 /usr/bin/flock -n /var/run/is_of.lock ${LOCATION}/openfile.sh
		fi
	else
		echo "${LOCATION}/openfile.sh not found";
	fi

	# scans the tmp folder if a perl process is found. Seeing a lot of perl started from cron in .cagefs/tmp that is malware
	if [ -f ${LOCATION}/perl_tmp.sh ]; then
                if [ -d /etc/cagefs ]; then
                        nice -n 2 /usr/bin/flock -n /var/run/is_pt.lock ${LOCATION}/perl_tmp.sh
                fi
        else
                echo "${LOCATION}/perl_tmp.sh not found";
        fi


	# locks passwords of users on mail channels systems who are getting 
	# blocked by mailchannels
	if [ -f ${LOCATION}/findspammer ]; then
		nice -n 2 /usr/bin/flock -n /var/run/is_spam.lock ${LOCATION}/findspammer run
	else
		echo "${LOCATION}/findspammer not found";
	fi

	if [ -x /opt/intershield/usr/memcache.sh ]; then
		# we don't flock since we fork background processes
		/opt/intershield/usr/memcache.sh
	fi

	# cpanel only
	if [ -x /opt/intershield/var/run ]; then
		if [ -d /usr/local/cpanel ]; then
			/usr/bin/flock -n /var/run/is_spam.lock sudo -u mailnull /opt/intershield/var/run
		fi
	fi
	# directadmin only
	if [ -x /admin/storage/kill_slow_queries.sh ]; then
		/admin/storage/kill_slow_queries.sh
	fi
else
	echo "Did not find ${LOCATION}/run2.sh";
fi

/bin/rm -v $lock_file
