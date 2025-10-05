#!/usr/bin/env bash

 #-
 # Copyright (c) 2006 InterServer, Inc.
 # All rights reserved.
 #
 # Redistribution and use in source and binary forms, with or without
 # modification, are permitted provided that the following conditions
 # are met:
 # 1. Redistributions of source code must retain the above copyright
 #    notice, this list of conditions and the following disclaimer.
 # 2. Redistributions in binary form must reproduce the above copyright
 #    notice, this list of conditions and the following disclaimer in the
 #    documentation and/or other materials provided with the distribution.
 # 3. All advertising materials mentioning features or use of this software
 #    must display the following acknowledgement:
 #        This product includes software developed by InterServer, Inc and
 #        its contributors.
 # 4. Neither the name of InterServer, Inc nor the names of its
 #    contributors may be used to endorse or promote products derived
 #    from this software without specific prior written permission.
 #
 # THIS SOFTWARE IS PROVIDED BY INTERSERVER, INC. AND CONTRIBUTORS
 # ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 # TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 # PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COMPANY OR CONTRIBUTORS
 # BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 # CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 # SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 # INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 # CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 # ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 # POSSIBILITY OF SUCH DAMAGE.
 #/

if [ "$1" = "" ]; then
	echo 'Usage: ./res httpd|exim|ccs|da|unit|ols';
	exit;
fi

function didwecomplete_ls()
{

        did_we_complete=$(echo $?);

        #echo "returned $did_we_complete";

        if [ ! "$did_we_complete" = "0" -a ! "$did_we_complete" = "1" ]; then
                echo
                echo 'command did not complete successfully';
		/usr/local/lsws/bin/lswsctrl stop; sleep 1s;
		killall litespeed lsphp; sleep 2s;
		killall -9 litespeed
		/usr/local/lsws/bin/lswsctrl start
		if [ -d /usr/local/lsws/admin/tmp ]; then
			touch /usr/local/lsws/admin/tmp/.lsphp_restart.txt
		fi
		/usr/local/lsws/bin/lswsctrl status
	else
		echo 'Litespeed reloaded';
        fi



}

if [[ $1 =~ ^[a-z]+$ ]]; then
	echo "Restarting $1";
else
	echo 'service must be alpha';
	exit;
fi

case "$1" in
 	httpd)

	if [ -d /usr/local/directadmin/custombuild ]; then
		echo 'DA detected';
		if [ -d /usr/local/lsws ]; then
			if [ "$2" = "" ]; then
				# detached php
				if [ -d /usr/local/lsws/admin/tmp ]; then
                                	touch /usr/local/lsws/admin/tmp/.lsphp_restart.txt
                        	else
                                	killall lsphp
                        	fi
				/usr/local/lsws/bin/lswsctrl restart
			elif [ "$2" = "all" ]; then
                                cd /usr/local/directadmin/custombuild
                                ./build rewrite_confs
			else
				if [ -d /usr/local/directadmin/data/users/$2 ]; then
					echo "Fast restart and rebuild config for user $2";
					echo "action=rewrite&value=httpd&user=$2" >> /usr/local/directadmin/data/task.queue.cb
					/usr/local/directadmin/dataskq --custombuild d2000
					/usr/local/lsws/bin/lswsctrl restart
				else
					echo "User $2 does not exist in /usr/local/directadmin/data/users fast restart not run";
				fi
			fi
		else
			# rewrite confs for all webservers except litespeed
			cd /usr/local/directadmin/custombuild
                        ./build rewrite_confs
		fi
	elif [ -e /scripts/restartsrv_httpd ]; then
		/scripts/rebuildhttpdconf; /scripts/restartsrv_httpd
		if [ "$2" = "a" -o "$2" = "all" ]; then
			if [ -x /admin/configs/cpanel/updatealldbs ]; then
				/admin/configs/cpanel/updatealldbs
			fi
		fi
	elif [ -f /etc/systemd/system/httpd.service ]; then
		echo restarting via systemctl
		systemctl stop httpd.service; systemctl start httpd.service
	elif [ -e /usr/sbin/apachectl ]; then
		killall httpd >/dev/null 2>&1
		sleep 1s;
    		killall -9 httpd >/dev/null 2>&1
   		
		if [ -e /usr/local/bin/fixsemgetapache2 ]; then
			/usr/local/bin/fixsemgetapache2 >/dev/null 2>&1
		elif [ -e /admin/fixsemgetapache ]; then
        		/admin/fixsemgetapache >/dev/null 2>&1
		fi
		
		/usr/sbin/apachectl start

	# if we get here the server is not installed as default 
	elif [ -e /etc/init.d/httpd ]; then
		/etc/init.d/httpd stop
		killall httpd
		sleep 2s
		killall -9 httpd
		if [ -e /admin/fixsemgetapache ]; then
                        /admin/fixsemgetapache >/dev/null 2>&1
                fi
		sleep 2s;
		/etc/init.d/httpd start
	else
		echo 'Unable to find apachectl or httpd run script';
		exit;
	fi
   ;;
  exim)
	# try a quick restart first
	if [ -f /var/spool/exim/exim-daemon.pid ]; then
		echo '	Sending exim a HUP signal for restart';
		kill -HUP `cat /var/spool/exim/exim-daemon.pid`
	elif [ -x /scripts/restartsrv_exim ]; then
		/scripts/restartsrv_exim
	elif [ -e /etc/systemd/system/exim.service ]; then
		echo restarting via systemctl
		systemctl restart exim.service
	elif [ -f /etc/init.d/exim ]; then
		/etc/init.d/exim restart
	else
		echo 'Exim may not be installed';
	fi

   ;;
 ccs)
	if [ -e /opt/cpanel-ccs/data/Logs/state ]; then
		systemctl stop cpanel-ccs.service; rm -f /opt/cpanel-ccs/data/Logs/state/*.pid; systemctl start cpanel-ccs.service
	fi
   ;;
 da)
	if [ -d /usr/local/directadmin ]; then
		/usr/local/directadmin/scripts/getLicense.sh auto
		echo "action=directadmin&value=restart" >> /usr/local/directadmin/data/task.queue.cb
		/usr/local/directadmin/dataskq d20 --custombuild
	else
		echo '/usr/local/directadmin not found';
	fi
   ;;
  unit)
	if [ -d /usr/local/directadmin ]; then
		if [ -x /usr/sbin/unitd ]; then
			echo "action=rewrite&value=nginx_unit" >> /usr/local/directadmin/data/task.queue.cb
			/usr/local/directadmin/dataskq d20 --custombuild
			sleep 1s;
			systemctl check unit && systemctl restart unit
		else
			echo 'Missing /usr/sbin/unitd';
		fi
	else
		echo 'Requires directadmin';
	fi
   ;;
  ols)
        if [ -d /usr/local/lsws ]; then
                echo 'found lsws';
                if [ -d /usr/local/directadmin ]; then
                        echo 'DA detected';
                        if [ -d /usr/local/directadmin/custombuild ]; then
                                cd /usr/local/directadmin/custombuild
                                ./build rewrite_confs
                        else
                                echo 'Missing /usr/local/directadmin/custombuild';
                        fi
                fi
                if [ -x /usr/local/lsws/bin/lswsctrl ]; then
                        /usr/local/lsws/bin/lswsctrl restart
			didwecomplete_ls
                else
                        echo 'Missing /usr/local/lsws/bin/lswsctrl or not executable';
                fi
        else
                echo 'Missing /usr/local/lsws';
        fi
   ;;
  *)
  echo "Error: I do not know about $1"
  exit;
  ;;
 esac
