#!/bin/bash

if [ ! -x /usr/bin/curl ]; then
	echo 'Requires /usr/bin/curl';
	exit;
fi

if [ ! -x /usr/local/cpanel/3rdparty/bin/clamd ]; then
	echo 'Missing /usr/local/cpanel/3rdparty/bin/clamd';
	CLAM_LOC=/usr/local/cpanel/3rdparty/bin/clamscan;
else
	clamd=$(ps auxw | grep [c]lamd);
	if [ "$clamd" = "" ]; then
		echo 'Clamd is not running';
		sleep 1s;
		CLAM_LOC=/usr/local/cpanel/3rdparty/bin/clamscan;
	else
		CLAM_LOC=/usr/local/cpanel/3rdparty/bin/clamdscan;
	fi
fi

echo
echo 'Testing virus with';
echo '	clamav';
$CLAM_LOC --no-summary /admin/scanner/eicar.com.txt
sleep 1s;
echo

if [ -f /opt/scan.sh ]; then
	echo '	/opt/scan.sh 0 is virus';
	/opt/scan.sh /admin/scanner/eicar.com.txt
fi

echo '	quickcheck 0 is virus';
curl --silent --connect-timeout 10 -X POST --form "submit=quickcheck" --form "curl=curl" --form "hash=275a021bbfb6489e54d471899f7db9d1663fc695ec2fe2a2c4538aabf651fd0f" http://scanner.interserver.net/s
echo
echo
sleep 1s;

echo 'Testing for not virus';
echo '	clamav';
$CLAM_LOC --no-summary /admin/upscripts	
sleep 1s;
echo

if [ -f /opt/scan.sh ];	then
        echo '	/opt/scan.sh 1 is clean';
        /opt/scan.sh /admin/upscripts
fi
sleep 1s;
echo
echo 'Quick check 1 is clean';
curl --silent --connect-timeout 10 -X POST --form "submit=quickcheck" --form "curl=curl" --form "hash=b7e048f0eca6c7850ee80d46c9634d319b5c671f130bee357832d5fb1eed9d44" http://scanner.interserver.net/s
echo
echo
