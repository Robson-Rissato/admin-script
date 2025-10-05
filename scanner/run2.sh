#!/bin/bash

version=1.12.30.2017;

# for now if run.sh has export QUICKCHECK=1 then we use this
# note if we find malware and fall back to run_scaner then we need to re-enable quickscan

imunifyc=`ps auxw | grep [i]munify-realtime-av$`;
if [ ! "$imunifyc" = "" ]; then
	echo 'Exiting due to imunify-realtime-av';
	exit;
fi

if [ "$QUICKCHECK" = "1" ]; then
	export QUICKSCAN=1;
fi

export QUICKSCAN=0;

# John Quaglieri
# InterServer, Inc
# john at interserver.net
#
# Copyright InterServer 2017 
#
# This code is not released for public use
# 

# needs ln -s /admin/virusscanner.sh clamscanrun.sh

# new method:  hostname GET /~sshah/7uq1qr2ov.php HTTP/1.1
# need to add support for /~username

#
# supports litespeed easyapache3 and easyapache4
# tested with cpanel only / directadmin (with lsws)
#
# speed improvements made with lsof
# skip recent scans
# more speed improvements with readlink
# index scan only for litespeed
#

#debugging
#echo "run2.sh Version $version";


lock_file="/root/tmp/_virusscan";
# change to /root
lastscanned="/root/tmp/_lastscanned";
thisrunscanned="/root/tmp/_thisrun";

totalscanskipped=0;
moredebug=0;
debug=0;
totalscans=0;

if [ "$1" = "d" ]; then
	moredebug=1;
	echo "Running with more debug";
	debug=1;
fi

if [ "$1" = "f" ]; then
	echo 'Force run';
	if [ -f $lock_file ]; then
		/bin/rm -v $lock_file
	fi
	if [ -f $lastscanned ]; then
		/bin/rm -v $lastscanned
	fi
	        if [ -f $thisrunscanned ]; then
                /bin/rm -v $thisrunscanned
        fi
fi

if [ -e $lock_file ]; then
	if [ "$(( $(date +"%s") - $(stat -c "%Y" $lock_file) ))" -gt "300" ]; then
		echo "$lock_file older than 300 seconds";
        else
                echo "ERROR: Lock file found, exiting $lock_file";
                exit;
        fi
fi

touch $lock_file

if [ -f $thisrunscanned ]; then
	mv -f -v $thisrunscanned $lastscanned
fi



export HOME=/root;
LOCATION=/admin/scanner;

# colors
green=$(tput setaf 2)
red=$(tput setaf 1)
normal=$(tput sgr0)

myCWD=$(pwd);

# fallback locate
if [ -x /usr/bin/locate ]; then
        printf "locate / updatedb fallback ${green}is${normal} available \n";
        fallback=1;
else
        printf "locate / updatedb fallback is ${red}not${normal} available \n";
        fallback=0;
fi

if [ "$LOWLOCATE" = "1" ]; then
	fallback=0;
	printf 'locate disabled due to LOWLOCATE setting';
	sleep 1s;
fi

#this is prevented from being called anyway
exclude="/wp-config.php$|/requests.php$"

if [ "$1" = "public_html" ]; then
	exclude="public_html/index.php|public_html/requests.php" 
fi

echo "Excluding ${exclude}";

if [ ! -d /usr/local/cpanel -a ! -d /usr/local/directadmin ]; then
        echo 'Not continuing:  Tested for cpanel / da servers only';
	/bin/rm -v $lock_file
        exit;
fi

if [ ! -e ${LOCATION}/clamscanrun.sh ]; then
        echo "${LOCATION}/clamscanrun.sh not found";
	/bin/rm -v $lock_file
        exit;
fi

if [ ! -e ${LOCATION}/quickscan.sh ]; then
	echo "${LOCATION}/quickscan.sh does not exist can not use quickscan";
	export QUICKSCAN=0;
fi

function run_index() {
	if [ "$1" = "" ]; then
                echo 'Usage scanner called with out passing script name';
                continue;
	else
		export THISISINDEX=1;
		run_scanner "${1}" ${2}
	fi
}

function run_scanner() {

# pid is optional

	if [ "$1" = "" ]; then
        	echo 'Usage scanner called with out passing script name';
		continue;
        else

                SCAN_SCRIPT="${1}";

		if [ -f $lastscanned ]; then
			lastscancheck=$(grep "^${SCAN_SCRIPT}$" $lastscanned)
			if [ ! "$lastscancheck" = "" ]; then
				totalscanskipped=$(expr $totalscanskipped + 1)
				echo "Skipping scanning ${SCAN_SCRIPT} due to a previous scan";
				#skip again
				echo ${SCAN_SCRIPT} >> $thisrunscanned;
				# prevent from running again in this run
				echo ${SCAN_SCRIPT} >> $lastscanned;
				echo "Total skipped scans ${green}$totalscanskipped${normal}";
				echo
				return;
			fi
		fi

		if [ "$2" = "" ]; then
			SCAN_PID='';
		else
			SCAN_PID=${2};
		fi
		
		
		echo ${SCAN_SCRIPT} >> $thisrunscanned;
		totalscans=$(expr $totalscans + 1)
		if [ "$QUICKSCAN" = "1" ]; then
			echo "	Running ${green}quickscan${normal}";
			# returns 0 good 1 bad, but any value other than 0 we will rescan
			qscheck=$(${LOCATION}/quickscan.sh "${SCAN_SCRIPT}");
			if [ ! "$qscheck" = "0" ]; then
				if [ "$qscheck" = "2" ]; then
					echo "  ${red}quickscan failed eic test ${normal}"
				fi
				echo "	${red}Rescanning${normal} in run_scanner";
				export QUICKSCAN=0;
				echo "	${green}Running${normal} clamscanrun.sh";
				${LOCATION}/clamscanrun.sh "${SCAN_SCRIPT}" ${SCAN_PID}
				# enable for next runs
				export QUICKSCAN=1;
			else
				echo "	${green}passed${normal} quickscan";
			fi
		else
			echo '	Running clamscanrun.sh';
			${LOCATION}/clamscanrun.sh "${SCAN_SCRIPT}" ${SCAN_PID}
		fi

		echo "Total scans run: ${green}$totalscans${normal}";
		echo
        fi
}

#/etc/apache2/conf.d/lsapi.conf is lsapi in cloudlinux
if [ -d /usr/local/lsws -o -f /etc/apache2/conf.d/lsapi.conf ]; then
	CLLSAPI=0;
        echo -n ' litespeed detected ';
	if [ -f /tmp/lshttpd/lshttpd.pid ]; then
		echo 'Found litespeed pid';
		CLLSAPI=0;
	elif [ -e /etc/apache2/conf.d/lsapi.conf ]; then
		echo 'cloudlinux lsapi';
		CLLSAPI=1;
	else
		echo
	fi
	echo
	totalfallback=0;
IFS="
"
	for data in $(ps axo user:20,pid,args:50 | grep [l]sphp: | awk '{print $1 ":" $2 ":" substr($0,index($0,$3))}' | egrep -v "${exclude}" | sort -u -t: -k3); do

		index=0;
		THISISINDEX=0;
                user=$(echo "${data}" | cut -d: -f1);
                pid=$(echo "${data}" | cut -d: -f2);

		realfilename=$(echo "${data}" | cut -d: -f4- | rev | cut -d/ -f1 | rev);
		if [ "${realfilename}" = "index.php" ]; then
			echo 'Found index.php file';
			index=1;
		else
			echo "$realfilename";
		fi

		firsttest=$(echo "${data}" | cut -d: -f4);
		homepartition=$(grep ^${user}: /etc/passwd | cut -d: -f6 | cut -d/ -f2);
		firsttest=$(echo "${data}" | cut -d: -f4 | grep ${homepartition}/${user});
		if [ -f "$firsttest" ]; then
			echo "$firsttest is a file ${green}match${normal} on 1st test"
			script=$firsttest;
			if [ "$index" = "0" ]; then
                        	run_scanner "$script" $pid
                        else
                        	echo 'Running index scanner';
                                run_index "$script" $pid
                        fi
			continue;

		fi

		# sometimes the process ends before we can get this
		if [ -d /proc/$pid ]; then
			# read link first
			realfullpath=$(readlink /proc/$pid/cwd | grep /home);
			if [ "$realfullpath" = "" ]; then
				echo 'failed to read cwd, trying lsof';
				realfullpath=$(lsof -p $pid | grep ${homepartition}/${user} | awk '{print substr($0,index($0,$9))}' | head -n 1);
			else
				echo 'readlink success';
			fi
		else
			echo -n 'Trying to refetch process';
			newdata=$(ps u -U $user | grep [l]sphp: | awk '{print $1 ":" $2 ":" substr($0,index($0,$11))}' | grep ${realfilename} | sort -u -t: -k3 | egrep -v "${exclude}" | head -n 1 );
			if [ "$newdata" = "" ]; then
				echo '	Failed to refetch';
			else
				pid=$(echo "${newdata}" | cut -d: -f2);
				if [ -d /proc/$pid ]; then
                        		# read link first
                        		realfullpath=$(readlink /proc/$pid/cwd | grep /home);
                        		if [ "$realfullpath" = "" ]; then
						echo 'Readlink failed, trying lsof';
						realfullpath=$(lsof -p $pid | grep ${homepartition}/${user} | awk '{print substr($0,index($0,$9))}' | head -n 1);
					else
						echo 'read link success refetch';
					fi
				else
					echo 'Pid missing after refetch';
				fi
			fi
			
		fi

                if [ "$debug" = "1" ]; then
                        echo "user is ${user}";
                        echo "pid is ${pid}";
			echo "homepartition is ${homepartition}";
			echo "realfullpath is ${realfullpath}";
			echo "realfilename is $realfilename";
                fi

		if [ ! "${realfullpath}" = "" -a ! "$realfilename" = "" ]; then
			script=${realfullpath}/${realfilename};
			if [ -f "$script" ]; then 
				echo "$script ${green}is${normal} a file using fast litespeed method.";
				if [ "$index" = "0" ]; then
	                        	run_scanner "$script" $pid
				else
					echo 'Running index scanner';
					run_index "$script" $pid
				fi
                        	echo
				continue
			else
				echo "$script is ${red}not${normal} a file in fast litespeed method.";
			fi
		
		else
			if [ "$moredebug" = "1" ]; then
				lsof -p $pid
			fi
			echo "Can ${red}not${normal} test file in fast litespeed method. One variable may be blank.";
		fi

		# fall back scanner when fast fails
		scriptcheck=$(echo "${data}" | cut -d: -f4);
                scriptcheck2=$(echo "${data}" | cut -d: -f4 | cut -d/ -f2-);
		if [ "$debug" = "1" ]; then
			echo
			echo 'Falling back to legacy litespeed';
			echo "scriptcheck is ${scriptcheck}";
			echo "scriptcheck2 is ${scriptcheck2}"
		fi
		totalfallback=$(expr $totalfallback + 1)

                # sometimes litespeed returns full path
                # 1
                if [[ ${scriptcheck} == /home* || ${scriptcheck} == home* ]]; then   # True if $script starts with an "/home" (wildcard matching).
                        echo -n "Found ${scriptcheck} which begins with /home";
                        if [ -f /${scriptcheck} ]; then
				printf " and ${green}is${normal} a file (1) \n"
                                script=/${scriptcheck};
                        else
				printf " but is ${red}not${normal} a file (1) \n"
                                echo
				continue  # move on to next in for loop
                        fi

		elif [[ ${scriptcheck} == /${user}* || ${scriptcheck} == ${user}* ]]; then
			echo -n "Found ${scriptcheck} which begins with /${user} testing /${homepartition}/${scriptcheck}";
			if [ -f /${homepartition}/${scriptcheck} ]; then
				printf " and ${green}is${normal} a file (1.5) \n"
                                script=/${homepartition}/${scriptcheck};
                        else
				printf " but is ${red}not${normal} a file (1.5) \n"
				echo
                        fi
                else
                        if [ "$debug" = "1" ]; then
                                echo "scriptcheck2 is $scriptcheck2";
                        fi
                        # sometimes litespeed cuts off the /home/username
                        # 2
                        if [[ $scriptcheck2 == /public_html* || $scriptcheck2 == public_html* ]]; then
                                if [ -d $uhome ]; then
                                        uhome=$(cat /etc/passwd | grep ^${user}: | cut -d: -f6);
                                        if [ "$debug" = "1" ]; then
                                                echo "2: uhome is $uhome";
                                        fi
                                        if [ -f "${uhome}/${scriptcheck2}" ]; then
                                                echo -n "Found ${uhome}/${scriptcheck2}"
						printf " and ${green}is${normal} a file (2) \n"
                                                echo
						script=${uhome}/${scriptcheck2};
                                        else
                                                echo -n "Found ${uhome}/${scriptcheck2}"
						printf " but is ${red}not${normal} a file (2) \n"
                                                echo
						continue
                                        fi
                                else
                                        echo -n "Found home dir of $uhome for $user" 
					printf " but is ${red}not${normal} a directory (2) \n"
                                        echo
					continue
                                fi
                        else
                                #sometimes it cuts off even more, grab the home partition but exclue the username
                                #3
                                if [ "$debug" = "1" ]; then
                                        # need beginning /
                                        echo "3: homepartition is /$homepartition";
                                fi
                                if [ -f /"${homepartition}/${scriptcheck2}" ]; then
                                        echo -n "Found /${homepartition}/${scriptcheck2}"
					printf " and ${green}is${normal} a file (3) \n"
                                        echo
					script="/${homepartition}/${scriptcheck2}";
                                else
                                        echo -n "Found /${homepartition}/${scriptcheck2}" 
					printf " but is ${red}not${normal} a file (3) \n"
					echo
					echo -n "Testing with adding in username and public_html /${homepartition}/${user}/public_html/${scriptcheck2} (3.1) ";

					if [ -f "/${homepartition}/${user}/public_html/${scriptcheck2}" ]; then
						printf " and ${green}is${normal} a file (3.1) \n"
						echo
						script="/${homepartition}/${user}/public_html/${scriptcheck2}";
					# for directadmin
					elif [ -f "/${homepartition}/${user}/${scriptcheck2}" ]; then
						echo
						echo -n "Testing with adding in username with out public_html /${homepartition}/${user}/${scriptcheck2} (3.2 directadmin) \n";
						printf " and ${green}is${normal} a file (3.2 directadmin end) "
						script="/${homepartition}/${user}/${scriptcheck2}";
					else
						printf " but is ${red}not${normal} a file (3.1 end) \n"
						echo
						# local fall back could return multiple scripts
						# we will call run scanner in a for loop here
						if [ "$fallback" = "1" ]; then
							echo "Using fall back locate method";
							# locate command written a second time for debug only
							# adding -n1 to exit on first match to speed up locate
							# was using a lot of CPU otherwise
							scripts=$(locate -n1 ${scriptcheck2} | grep ^/${homepartition}/${user} | grep ${scriptcheck2}$);
							if [ "$debug" = "1" ]; then
								# thats here
								echo "locate command locate ${scriptcheck2} | grep ^/${homepartition}/${user} | grep ${scriptcheck2}$";
							fi
							if [ ! "$scripts" = "" ]; then
								# show number count of locate
								count=0;

								for script in $scripts; do
									echo "Found $script";
									count=$(expr $count + 1)
									if [ -f "$script" ]; then
										printf " and ${green}is${normal} a file (3.5 fallback count $count) \n"
										echo
										if [ "$index" = "0" ]; then
											run_scanner "$script" $pid
										else
											run_index "$script" $pid
										fi
									else
										printf " but is ${red}not${normal} a file (3.5 fallback) \n"
										echo
									fi
								done
								# exiting the function
								# in other functions we call run scanner in another point
								# but those do not have multiple files like locate may
								continue
							else
								echo 'Nothing returned in fallback (3.5)';
								continue
							fi
						else
							echo 'Fall back not enabled';
							continue
						fi
					fi
                                fi
                        fi
                fi
                        # if we got here run the scanner
			if [ "$index" = "0" ]; then
				run_scanner "$script" $pid
			else
				run_index "$script" $pid
			fi
			echo
        done
        echo "Total fallbacks ${red}$totalfallback${normal}";
        echo

fi
# begin ea4 type
# not all sites will use lsapi so we run here as well
# also php-fpm is now in use as well as suphp in easyapache4
# normal litespeed we exit
if [ "$CLLSAPI" = "0" ]; then
	echo 'Ending litespeed run';
	/bin/rm -v $lock_file
	exit;
else
	if [ ! -d /usr/local/cpanel ]; then
		echo 'ending run no cpanel found';
		/bin/rm -v $lock_file
		exit;
	fi
	echo 'easyapache run';
fi

	#easyapache4
	FPM=0;
	if [ -d /opt/cpanel/ea-php56 -o -d /opt/cpanel/nghttp2 ]; then
		echo "Easyapache 4 detected";
		EA4=1;
		FPM_check=$(ps auxw | grep "[/o]pt/cpanel/ea-.*etc/php-fpm.conf");
		if [ ! "$FPM_check" = "" ]; then
			echo 'FPM detected';
			FPM=1;
		fi
	else
		EA4=0;
	fi

	if [ "$EA4" = "1" ]; then
		# check for dso
		type=$(/usr/local/cpanel//bin/rebuild_phpconf --current | grep ^ea-php | grep dso$ | awk '{print $3}');
	else
		#ea3
		type=$(/usr/local/cpanel//bin/rebuild_phpconf --current | grep PHP5 | awk '{print $3}');
	fi

	#suphp/cgi we can see processes in ps
	if [ "$type" = "suphp" -o "$EA4" = "1" ]; then
		echo '	suphp/cgi run';
		echo
        	# ignore index.php
		# fix me - code reuse here
		exclude='/index.php|/wp-config.php';
		if [ "$EA4" = "1" ]; then
			for data in $(ps axo user:20,pid,args:50 | grep "[/o]pt/cpanel/ea-.*php-cgi" |  awk '{print $2 ":" substr($0,index($0,$4))}' | grep /home | egrep -v "${exclude}"); do
				pid=$(echo "${data}" | cut -d: -f1);
                                script=$(echo "${data}" | cut -d: -f2);
                                if [ -f "$script" ]; then
                                echo "Found $script";
                                # if we got here run the scanner
                                run_scanner "$script" $pid
                                echo
                                fi
			done
		else
			echo 'EA3 run';
        		for data in $(ps axo user:20,pid,args:50 | grep php | awk '{print $2 ":" substr($0,index($0,$4))}' | grep /home | egrep -v "${exclude}"); do
                		pid=$(echo "${data}" | cut -d: -f1);
                		script=$(echo "${data}" | cut -d: -f2);
                		if [ -f "$script" ]; then
                       		echo "Found $script";
				# if we got here run the scanner
                        	run_scanner $script $pid
				echo
                		fi
        		done
		fi
	fi


	# easyapache4 can be both cgi, suphp and/or dso so we check for this type as well
	if [ "$type" = "suphp" -o "$type" = "dso" -o "$EA4" = "1" -o "$FPM" = "1" ]; then
		echo '	get/post run';
		exclude='/index.php|/wp-config.php';
		PORT=$(grep ^apache_port= /var/cpanel/cpanel.config| cut -d: -f2);
		# | cut -d"?" - exclude query string
		# :: -> : found on ea3 server
IFS="
"
		getdata=$(lynx -connect_timeout=15 -dump http://localhost:${PORT}/whm-server-status | egrep "GET|POST"  | egrep -v "${exclude}" | sed s#"http/1.1"#""#g | sed s#"http/1.0"#""#g | awk '{print $1 ":" $3}' | sed s#"\:443"#""#g | sed s#"\:80"#""#g | sed s#"::"#":"#g | grep -v ":/$" | cut -d"?" -f1 | egrep "\.php|\.pl|\.cgi|\.rb|\.py|\.pyc" | sort | uniq);
		for data in $getdata; do
			domain=$(echo ${data} | cut -d: -f1);
			# remove query string
			scriptcheck=$(echo "${data}" | cut -d: -f2 | cut -d? -f1);
			if [ "$debug" = "1" ]; then
				echo
				echo "Found domain ${domain} with script ${scriptcheck}";
			fi

			if [ "$scriptcheck" = "" ]; then
				echo "Script returned ${red}blank${normal}  value (1)";
				continue
				echo
			fi
			if [ "${domain}" = "(unavailable)" ]; then
				printf 'Skipping (unavailable) domain at LINE '
				printf "$LINENO \n"
				continue
			fi
			usercheck=$(/scripts/whoowns ${domain});
			if [ "$usercheck" = "" ]; then
				echo 'Not able find domain with first check (usercheck 1)';
				usercheck2=$(/admin/whoownes ${domain});
				if [ "$usercheck2" = "" ]; then
					printf "Unable ${red}to${normal} find domain (usercheck 2) \n";
					continue
					echo
				else
					numbercheck=$(echo $usercheck2 | wc -w);
					if [ "$numbercheck" = "1" ]; then
						user=${usercheck2};
						echo "Found user ${user}";
					else
						printf "usercheck returned ${red}too${normal} many users (usercheck 2.1) \n";
						continue
						echo
					fi
				fi
			else
				user=${usercheck};
				echo "Found user ${user}";
			fi

			if [ ! -d "/var/cpanel/userdata/${user}" ]; then
				echo "/var/cpanel/userdata/${user} does not exist";
				continue;
			fi
	
			cd /var/cpanel/userdata/${user}

			domaincheck=$(ls | grep ^${domain} | egrep -v ".yaml$|.cache$|_SSL" | grep -v "\,v");
			numbercheck=$(echo ${domaincheck} | wc -w);
			if [ "$debug" = "1" ]; then
				echo "number check returned $numbercheck";
			fi
			cd $myCWD;

			if [ "$numbercheck" = "1" ]; then
				path=$(grep ^documentroot: /var/cpanel/userdata/${user}/${domaincheck} | awk '{print $2 }');
				if [ "$debug" = "1" ]; then
					echo "Found path $path";
				fi
                        else
                        	printf "domaincheck returned ${red}too${normal} many users (domaincheck 3) \n";
                                continue
				echo
                        fi


			if [ "$debug" = "1" ]; then
				echo "Script is ${path}/${scriptcheck}";
			fi

			script="${path}/${scriptcheck}";
			# first test
			printf "Found ${script} ";
			if [ ! -f "${script}" ]; then
				printf "but is not a file (4) \n";

				uhome=$(grep ^${user}: /etc/passwd | cut -d: -f6);
                        	if [ "$uhome" = "" ]; then
                               		printf "Got blank homedir for ${user}\n";
                              		continue
					echo
                        	fi

				if [ "$debug" = "1" ]; then
					echo -n "Testing ${uhome}/public_html/${scriptcheck}";
				fi

				script="${uhome}/public_html/${scriptcheck}";

				if [ -f "${script}" ]; then
					printf " and ${green}is${normal} a file (4.1)\n";

				else
					printf " but ${red}is not${normal} a file (4.1)\n";
					continue
					echo
				fi
			else
				printf " and ${green}is${normal} a file (4) \n";

			fi


			# if we got here run the scanner
                        run_scanner $script

		done
	else
		echo
		echo "Got back type: $type which is not supported";
		echo
	fi

echo

/bin/rm -v $lock_file
