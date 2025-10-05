#!/bin/sh

if [ ! -e /admin/virusscanner.sh ]; then
	echo 'missng virusscanner.sh';
	exit;
fi

if [ ! -e /etc/redhat-release ]; then
	echo 'tested on RHEL only';
	exit;
fi

cd /admin/scanner
if [ -e clamscanrun.sh ]; then
        echo 'clamscanrun.sh exists';
else
	ln -s /admin/virusscanner.sh clamscanrun.sh	
fi

if [ ! "$1" = "cron" ]; then
	echo 'Not activating cron. Pass as ./create.sh cron to create with cron';
	/admin/clamscan shelldb updatedb
	exit;
fi

if [ -e /etc/cron.daily/virusscanner_freshclam.sh ]; then
	echo '/etc/cron.daily/virusscanner_freshclam.sh exists already';
	exit;
fi

cat >> /etc/cron.daily/virusscanner_freshclam.sh <<EOF
#!/bin/sh

/admin/clamscan shelldb updatedb >> /dev/null 2>&1
EOF

chmod +x /etc/cron.daily/virusscanner_freshclam.sh
nohup /etc/cron.daily/virusscanner_freshclam.sh &

cat >> /etc/cron.d/virusscanner_php.sh <<EOF
SHELL=/bin/sh
*/5 * * * * root /admin/scanner/run.sh >> /dev/null 2>&1
EOF

yum -y install lynx nc
