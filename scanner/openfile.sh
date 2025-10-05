#!/bin/bash

echo 'Openfile scanner';

pcheck=`ps aux | grep [i]munify-realtime-av | grep ^root`;
if [ ! "$pcheck" = '' ]; then
	echo 'skipping openfile due to imunify-realtime-av';
	exit;
fi
# colors
green=$(tput setaf 2)
red=$(tput setaf 1)
normal=$(tput sgr0)

IFS="
"

lock_file="/root/tmp/_openvirusscan";
lastscanned="/root/tmp/_openfilelastscanned";
thisrunscanned="/root/tmp/_openfilethisrun";
exclude='/index.php|/wp-config.php|error_log|zip|admin-ajax.php|wp-cron.php';

touch $lock_file

if [ -f $thisrunscanned ]; then
        mv -f -v $thisrunscanned $lastscanned
fi


# uniq to not have duplicate matches
for data in $(ps auxw | grep [l]sphp: | uniq --skip-fields=10 | awk '{print $2 }'); do

        for SCAN_SCRIPT in $(lsof -p $data |grep /home | awk '{print substr($0,index($0,$9))}' | egrep -v "$exclude"); do

                if [ "$SCAN_SCRIPT" = "" ]; then
                        echo 'Returned blank';
                        continue;
                fi

                if [ -f "$SCAN_SCRIPT" ]; then
                        if [ -f $lastscanned ]; then
                                lastscancheck=$(grep "^${SCAN_SCRIPT}$" $lastscanned)
                                if [ ! "$lastscancheck" = "" ]; then
                                        totalscanskipped=$(expr $totalscanskipped + 1)
                                        echo "Skipping scanning ${SCAN_SCRIPT} due to a previous scan";
                                        #skip again
                                        echo ${SCAN_SCRIPT} >> $thisrunscanned;
                                        echo "Total skipped scans ${green}$totalscanskipped${normal}";
                                        echo
                                        continue;
                                fi
                        fi
                        echo "Scanning $SCAN_SCRIPT";
                        /admin/scanner/clamscanrun.sh "$SCAN_SCRIPT"
			#skip
			echo ${SCAN_SCRIPT} >> $thisrunscanned;
			echo
                fi
        done
done

/bin/rm -v $lock_file

