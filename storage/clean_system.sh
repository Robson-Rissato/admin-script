#!/usr/bin/env bash

if [ ! -x /usr/sbin/tmpreaper ]; then
        echo 'Missing /usr/sbin/tmpreaper';
        exit;
fi

if [ ! -x /usr/bin/sudo ]; then
        echo 'Missing /usr/bin/sudo';
        exit;
fi

if [ -d /usr/local/directadmin ]; then


        if [ -d /home ]; then
                cd /home
                for dausers in `df -m | grep /home | grep ^vz | cut -d/ -f2 | awk '{print $1}'`; do
                        if [ "$dausers" = "" ]; then
                                echo 'Got back blank user';
                                continue;
                        else
                                if [ -d /home/${dausers}/softaculous_backups ]; then
                                        if [ "$1" = "run" ]; then
                                                if [ "$2" = "m" ]; then
                                                        echo 'Using 72 hour removal';
                                                        sudo -u ${dausers} /usr/sbin/tmpreaper -a 72 /home/${dausers}/softaculous_backups
                                                elif [ "$2" = "mm" ]; then
                                                        echo 'Using 24 hour removal';
                                                        sudo -u ${dausers} /usr/sbin/tmpreaper -a 24 /home/${dausers}/softaculous_backups
                                                else
                                                        echo 'Using 720 hour removal';
                                                        sudo -u ${dausers} /usr/sbin/tmpreaper -a 720 ${dausers}/softaculous_backups
                                                fi
                                        else
                                                echo "I would have run sudo -u ${dausers} /usr/sbin/tmpreaper -a 720 /home/${dausers}/softaculous_backups";
                                                du -sm /home/${dausers}/softaculous_backups
                                        fi
                                fi
                        fi
                done
		if [ "$1" = "run" ]; then
	                if [ "$2" = "m" ]; then
        	                 echo 'Using 72 hour removal';
                                 if [ -x /admin/configs/zfssnapclean ]; then
                	                 /admin/configs/zfssnapclean all
                                 fi
                        elif [ "$2" = "mm" ]; then
                        	echo 'Using 24 hour removal';
                                if [ -x /admin/configs/zfssnapclean ]; then
                                	/admin/configs/zfssnapclean 3 && /admin/configs/zfssnapclean 2
                                fi
				if [ -x /admin/clean_lscache.sh ]; then
                                        if [ -d /usr/local/lsws ]; then
                                        	/admin/clean_lscache.sh run
                               		fi
                                fi

                        else
                        	echo 'Using 720 hour removal';
                                	if [ -x /admin/configs/zfssnapclean ]; then
                                        	/admin/configs/zfssnapclean 3
                                        fi
                        fi
                else
			echo "I would have run /admin/configs/zfssnapclean";
			echo "m = 72 hour removal  /admin/storage/clean_system.sh run m";
			echo "mm = 24 hour removal  /admin/storage/clean_system.sh run mm";
			echo "nothing passed = 720 hour removal  /admin/storage/clean_system.sh run";
		fi
        else
                echo 'missing /home';
        fi
else
        echo 'Requires directadmin';
fi

