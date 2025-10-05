#!/bin/bash

# run as ./clean_system.sh run

# check for cpanel for a wh clean
if [ -e /usr/local/cpanel ]; then
	echo 'Detected cpanel';
	# check for tmpwatch which is used for cleaning apache logs
	if [ -x /usr/sbin/tmpwatch ]; then
		if [ -d /usr/local/apache ]; then
			cd /usr/local/apache
			if [ -e domlogs ]; then
				if [ "$1" = "run" ]; then
					tmpwatch -v -m 720 domlogs
				else
					echo 'I would have cleaned domlogs';
				fi
			fi
		fi

		if [ -e logs ]; then
			if [ "$1" = "run" ]; then
				tmpwatch -v -m 720 logs
			else
				echo 'I would have cleaned apache logs';
			fi
		fi

		if [ "$1" = "run" ]; then
			if [ -e /usr/local/lsws ]; then
				/usr/local/lsws/bin/lswsctrl restart
			else
				/scripts/restartsrv_httpd
			fi
		else
			echo 'I would have restarted apache';
		fi
	else
		echo '/usr/sbin/tmpwatch does not exist';
	fi

	if [ -x /usr/bin/locate ]; then
		if [ "$1" = "run" ]; then
			for i in `locate /error_log | egrep "/home|/backup" | grep error_log$`; do if [ -f $i ]; then /bin/rm -v $i; fi done
		else
			echo 'I would have used locate to remove error logs in /home and /backup';
		fi
	else
		echo 'No /usr/bin/locate';
	
	fi
	if [ "$1" = "run" ]; then
		if [ ! -x /usr/bin/sudo ]; then
        		echo 'No /usr/bin/sudo';
        		exit;
		fi

		cd /var/cpanel/users
		for username in *; do
        		if [ "$username" = "system" -o "$username" = "nobody" ]; then
                		echo "Skipping $username";
                		continue;
        		fi
        		user_home_dir=$(grep ^${username}: /etc/passwd | cut -d: -f6);
        		if [ "$user_home_dir" = "" -o "$user_home_dir" = "/" ]; then
                		echo "Skipping $username due to homedir $user_home_dir";
                		continue;
        		fi

        		if [ -d ${user_home_dir}/softaculous_backups ]; then
                		echo "Found ${user_home_dir}/softaculous_backup";
                		cd ${user_home_dir}/softaculous_backups
				if [ "$2" = "m" ]; then
					echo "72 hour removal"
					/usr/bin/sudo -u $username tmpwatch -c 72 -v ${user_home_dir}/softaculous_backups
				elif [ "$2" = "mm" ]; then
					echo "24 hour removal";
					/usr/bin/sudo -u $username tmpwatch -c 24 -v ${user_home_dir}/softaculous_backups
				else
					echo "720 hour removal";
                			/usr/bin/sudo -u $username tmpwatch -c 720 -v ${user_home_dir}/softaculous_backups
				fi
        		fi
		done
		if [ -x /admin/clean_lscache.sh ]; then
                	if [ -d /usr/local/lsws ]; then
                        	/admin/clean_lscache.sh run
	                fi
                fi

	else
		echo 'I would have cleaned softaculous backups';
	fi
fi
