#!/bin/bash

# John Quaglieri
# InterServer, Inc
# john at interserver.net
#
# Copyright InterServer 2018
#
# This code is not released for public use
#


if [ "$SUPRESS" = "1" ]; then

	echo() { :; }
fi

#NOMAIL=1 - don't email
#THISISINDEX=1 and SLOW=1 - for index.php pages

mail=root;

VERSION=12.27.2017;
#echo "$VERSION"

# begin
date_prog=/bin/date;
date=$(${date_prog});
hostname=$(/bin/hostname);
master_path=/admin/scanner;
script=$(basename $0)
IFS=""

# for email
# touch /root/tmp/_clammail
# for ftp 
# touch /root/tmp/_clammailftp
# email users 
# touch /root/tmp/_wpmanaged

# touch /root/tmp/_clammail /root/tmp/_wpmanaged /root/tmp/_clammailftp
# * todo add in customer emailing for ftp

#                                # userlog
#                                # remove in the future as we now above drop with sudo
#                                chown ${owner}:${owner} ${home}/.quarentine/log.txt


currentuser=$(whoami);


if [ "$currentuser" = "" ]; then
        echo "Did not get current user at line $LINENO";
        exit;
elif [ "$currentuser" = "root" ]; then
	if [ ! "$script" = "quickscan.sh" ]; then
       		echo "Running as root, sudo functions will be used";
	fi
else
        echo "Running as user $currentuser";
fi

if [ -x /usr/bin/sudo ]; then
        SUDOPATH="/usr/bin/sudo";
elif [ -x /sbin/sudo ]; then
        SUDOPATH="/sbin/sudo";
else
        echo "Did not find sudo at line $LINENO";
        exit;
fi

function getcontact()
{

                if [ -e /etc/wwwacct.conf ]; then
                        mail=$(grep ^CONTACTEMAIL  /etc/wwwacct.conf | cut -d" " -f2);
                        if [ "$mail" = "" ]; then
                                mail=root;
                                echo 'Setting mail user to root as no contact mail set in /etc/wwwacct.';
                                echo
                        fi
                fi


}

function didwecomplete()
{

        # if we get a non zero/non 1 run with the above command we need to exit out of this loop and send an error
        did_we_complete=$(echo $?);

        echo "returned $did_we_complete";

        if [ ! "$did_we_complete" = "0" -a ! "$did_we_complete" = "1" ]; then
		echo
                echo 'scan command existed with non zero or non one and is exiting (clamd may not be running)';
                exit;
	else
		echo 'Clamav passed non zero test';
        fi



}

if [ -x /usr/local/cpanel/3rdparty/bin/clamscan ]; then
        CLAMN_LOC=/usr/local/cpanel/3rdparty/bin/clamscan;
	CLAMD_LOC=/usr/local/cpanel/3rdparty/bin/clamdscan;
	CLAMD=/usr/local/cpanel/3rdparty/bin/clamd;
elif [ -x /usr/bin/clamscan ]; then
        CLAMN_LOC=/usr/bin/clamscan;
	CLAMD_LOC=/usr/bin/clamdscan;
	CLAMD=/usr/sbin/clamd;
else
        CLAMN_LOC=$(which clamscan);
	CLAMD_LOC=$(which clamdscan);
	CLAMD=$(which clamd);
fi



# prefer clamd
if [ ! "$CLAMD" = "" ]; then
	proc_check=$(ps auxw | grep $CLAMD | grep -v grep | grep ^root);
	if [ ! "$proc_check" = "" ]; then
		#echo 'Using CLAMD';
		CLAM_LOC="$CLAMD_LOC";
	else
		CLAM_LOC="$CLAMN_LOC";
	fi
else
	CLAM_LOC=$CLAMN_LOC;
fi

if [ "$CLAM_LOC" = "" ]; then
        echo 'ClamAV not installed';
        exit;
fi

# by default disable email warnings of quarentined scripts
# this has gone over 1 year of testing with warnings on and considered safe to disable
if [ -e /root/tmp/_clammail ]; then
	if [ ! -e /root/tmp/_wpmanaged ]; then
		domail=1;
		getcontact
	else
		# wp managed
		domail=2;
	fi
else
	domail=0;
fi

if [ "$NOMAIL" = "1" ]; then
        domail=0;
fi


if [ "$1" = "" ]; then
        echo 'Variable is blank';
        exit;
fi
if [ ! -f "$1" ]; then
        echo "$1 file not found"
        exit;
fi

# clamav test
if [ "$script" = "quickscan.sh" ]; then
	ENDPOINT=s;
        SERVER='http://scanner.interserver.net';
	clamav_test=$(curl --silent --connect-timeout 10 -X POST --form "submit=quickcheck" --form "curl=curl" --form "hash=275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f" ${SERVER}/${ENDPOINT});
	if [ ! "$clamav_test" = "0" ]; then
		echo 2;
		exit;
	fi
else
	clamav_test=$($CLAM_LOC --no-summary /admin/scanner/eicar.com.txt);
	if [ "$clamav_test" = "/admin/scanner/eicar.com.txt: eicar.com.txt.sigs.InterServer.net.SHA256.26685.UNOFFICIAL FOUND" ]; then
		echo 'Scanner has passed Eicar test';
	else
		echo "Failed Eicar test output $clamav_test will not continue";
		exit;
	fi
fi
#

#pure-ftpd
# add in customer email only master email supported so far
# this really is not used
if [ "$script" = "clamscanftp.sh" ]; then
	if [ -e /root/tmp/_clammailftp ]; then
		getcontact
		domail=1;
	fi
	owner=$(ls -l "$1" | awk '{print $3}');
        check=($CLAM_LOC  --stdout --infected --remove --no-summary "$1");

        if [ ! "$check" = "" ]; then

		printf "PURE-FTPD: $1 $check $date $VERSION \n" >> ${master_path}/log.txt

                if [ "$domail" = "1" ]; then
                        printf "Removed at Location: $1 \nowner $owner \n Removed by pure-ftpd" | mail -s "Clamav detected virus uploaded on $hostname on $date" $mail
                fi
        fi
# quick check on high load, we will rescan if there is a virus
elif [ "$script" = "quickscan.sh" ]; then
	# by default do not rescan
	hash=$(sha256sum ${1} | awk '{print $1}');
        if [[ "$hash" =~ [A-Fa-f0-9]{64} ]]; then
                scanfile=$(curl --silent --connect-timeout 10 -X POST --form "submit=quickcheck" --form "curl=curl" --form "hash=${hash}" ${SERVER}/${ENDPOINT});
		# 0 not malware, 1 malware but we rescan with clamav
		if [ "$scanfile" = "" ]; then
			echo 1;
		else
			if [ "$scanfile" = "0" ]; then
				echo 1;
			elif [ "$scanfile" = "1" ]; then
				echo 0;
			else
				echo 1;
			fi
		fi
	else
		echo 1;
	fi
elif [ "$script" = "clamscanapache.sh" ]; then
        # mod_sec but this is replaced by /opt/scan.sh in most systems
        check=$($CLAM_LOC --stdout --no-summary --infected "$1");
        if [ ! "$check" = "" ]; then
                echo "0 clamscan: $1";
        else
                echo "1 clamscan: OK";
        fi

elif [ "$script" = "clamscanrun.sh" ]; then
	date_folder=$(${date_prog} +%Y%m%d.$$)

	# one non clamav scan on index.php files only for the first scan
	if [ "$SLOW" = "1" -a "$THISISINDEX" = "1" ]; then
		output=$($CLAM_LOC  --stdout --no-summary --infected "$1");
		if [ "$output" = "" ]; then
			echo 'shellb run';
			output=$($CLAMN_LOC  -d /admin/whitelist.fp -d /admin/shellb.ldb -d /admin/shellb.db -d /admin/shellb.hdb -d /admin/clamav/interservertopline.db --stdout --no-summary --infected "$1");
		fi
	else
		echo 'Fast run';
		output=$($CLAM_LOC  --stdout --no-summary --infected "$1");
	fi
	
	# if we get a non zero/non 1 run with the above command we need to exist out of this loop and send an error
	didwecomplete

        if [ ! "$output" = "" ]; then
                owner=$(ls -l "$1" | awk '{print $3}');
                printf "0 clamscan: $1 $output \n";
		if [ "$THISISINDEX" = "1" ]; then
			echo ' ... !! This is an index.php file and we have malware !! ...';
			if [ -x $CLAMN_LOC ]; then
				checkforwp=$($CLAMN_LOC -d /admin/whitelist.fp -d /admin/scanner/reverse.ldb  --stdout --no-summary --infected "$1");
				didwecomplete

				if [ ! "$checkforwp" = "" ]; then
					echo ' !! Wordpress found, I am replacing file automatically !!';
					echo
					REPLACEFILE=1;
					domail=0;
					sleep 2s;
				else
					echo '!! Non wordpress file found. Manually inspect the file !! ';
					echo -n '	Filename ';
					echo "$1";
					echo
					sleep 3s;
					exit;
				fi
			else
				echo "$CLAMN_LOC not found at line $LINENO exiting";
				exit;
			fi
		fi
		if [ ! "$owner" = "" ]; then
			home=$(grep ^${owner}: /etc/passwd  | cut -d: -f6);
			if [ -d "${home}" ]; then
				if [ ! -e "${home}/.quarentine/${date_folder}" ]; then
					# to be removed
					if [ -d ${home}/.quarentine ]; then 
						chown ${owner}:${owner} ${home}/.quarentine
					fi
					${SUDOPATH} -u ${owner} mkdir -p -v ${home}/.quarentine/${date_folder}
				fi

				${SUDOPATH} -u ${owner} mv -v -f "$1" ${home}/.quarentine/${date_folder}

				echo ' !! MALWARE FOUND !!';

				if [ "$REPLACEFILE" = "1" ]; then
					echo '	Replacing hacked wordpress';
					cp -v /admin/scanner/files/index.php "$1"
					chown ${owner}:${owner} "$1"
					sleep 1s;
				fi				

				# userlog
				# remove in the future as we now above drop with sudo
				if [ -f ${home}/.quarentine/log.txt ]; then
					chown ${owner}:${owner} ${home}/.quarentine/log.txt
				fi
				printf "$1 $output $date $VERSION \n" >> ${home}/.quarentine/log.txt
				if [ "$REPLACEFILE" = "1" ]; then
					printf "	REPLACED wordpress index.php \n" >> ${home}/.quarentine/log.txt
				fi
				# big log
				printf "$1 $output $date $VERSION \n" >> ${master_path}/log.txt
				# remote log
				if [ -f /etc/cron.daily/modsec.sh ]; then
					curl --silent --connect-timeout 10 -X POST --form "submit=userlog" --form "myuser=${owner}" --form "mypath=${1}" --form "myreason=${output}" --form "myhostname=${hostname}" http://scanner.interserver.net/s
				fi				

				if [ "$REPLACEFILE" = "1" ]; then
					printf "        REPLACED wordpress index.php \n" >> ${master_path}/log.txt
				fi
				# mail
				if [ "$domail" = "1" ]; then
                        		printf "$1 $check $date has been moved to ${home}/.quarentine/${date_folder} for user ${owner} as it has been detected as a virus" | mail -s "Virus quarentined on $hostname $date" $mail
                		elif [ "$domail" = "2" ]; then
					if [ -f $home/.contactemail ]; then
						mail=$(cat $home/.contactemail);
						if [ "$mail" = "" ]; then
                                			echo '.contact is blank checking cpanel user file';
                                			mail=$(grep ^CONTACTEMAIL= /var/cpanel/users/${owner} | cut -d= -f2);
							if [ "$mail" = "" ]; then
								echo "Failed to get a contact mail";
							else
								echo "Found mail $mail";
								docustomermail=1;
							fi
						else
							echo "Found mail $mail";
							docustomermail=1;
						fi

                                                # skip resold accounts
                                                if [ -e /usr/sbin/whmapi1 ]; then
	                                                isitreseller=$(whmapi1 accountsummary user=${owner} | grep owner: | cut -d: -f2 | awk '{print $1}');
                                                        if [ ! "$isitreseller" = "root" ]; then
								echo "Account ${owner} is resold and owned by $isitreseller";
        	                                                mail=$(whmapi1 accountsummary user=${isitreseller} | grep email: | cut -d: -f2 | awk '{print $1}');
								if [ "$mail" = "" -o "$mail" = "\"*unknown*\"" ]; then
									echo "Found no email for reseller";
									docustomermail=0;
								else
									echo "Found reseller email $mail for owner ${isitreseller}";
									docustomermail=1;
								fi
                                                        fi
                                                fi
					fi
					
					if [ "$docustomermail" = "1" ]; then
						printf "Sent from non monitored email. Please do not directly reply. $1 $check $date has been moved to ${home}/.quarentine/${date_folder} for your user ${owner} as it has been detected as a virus or malware. Please review https://www.interserver.net/tips/kb/malware-shared-hosting/ for more information. Open a new ticket if you believe this is a false positive." | mail -s "InterServer Shared hosting Hosting :: Virus or Malware quarentined on user $owner $date" $mail
						printf "	emailed $mail for $1 $VERSION \n" >> ${master_path}/log.txt
					else
						echo "Failed to find email for ${owner} - email on virus is enabled";
						printf "	No email address found for $1 $VERSION \n" >> ${master_path}/log.txt
					fi
				fi

				# pid kill if used
				if [ ! "$2" = "" ]; then
					echo "Killing pid $2";
					kill -9 $2
				fi
			else
				echo "${home} is not a directory"
			fi
		else
			echo "Unable to find owner of $1";
		fi
        else
                echo "1 clamscan: OK";
        fi

else
	$CLAM_LOC --no-summary "$1"

fi

