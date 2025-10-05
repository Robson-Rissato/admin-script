#!/bin/bash

# wordpress auto updater for webuzo
# users wpcli
# tested so far with centos7

if [ -e /usr/local/cpanel -o -e /usr/local/directadmin ]; then
	exit;
fi

if [ ! -e /usr/local/webuzo ]; then
        echo 'Requires webuzo';
        exit;
fi

if [ ! -f /var/webuzo/webuzo.conf ]; then
        echo 'Missing /var/webuzo/webuzo.conf';
        exit;
fi

if [ -f /usr/local/webuzo/enduser/webuzo/install.php ]; then
        /bin/rm -v /usr/local/webuzo/enduser/webuzo/install.php
fi


# curl server to store
server=192.64.87.219;

# used for storing file
myhostname=`hostname`;

unmatched=0;

if [ -x /admin/upscripts ]; then
	/admin/upscripts
fi

# update acme.sh
if [ -e /usr/bin/wget ]; then
	if [ ! -e /root/_leup ]; then
		wget -O /usr/local/webuzo/includes/cli/acme.sh https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh && chmod +x /usr/local/webuzo/includes/cli/acme.sh
		touch /root/_leup
	fi
fi

if [ -e /usr/bin/yum ]; then
	# epel for clamav and exim
	if [ ! -f /etc/yum.repos.d/epel.repo ]; then
		yum -y install epel-release
	fi

	# general updates
	if [ ! -f /dev/shm/yumlock ]; then
		yum -y update
	fi

	# clamav
	if [ ! -f /usr/sbin/clamd ]; then
		yum -y install clamav clamd
		if [ -f /etc/freshclam.conf ]; then
			echo -e "DatabaseCustomURL http://sigs.interserver.net/interserver256.hdb\nDatabaseCustomURL http://sigs.interserver.net/interservertopline.db\nDatabaseCustomURL http://sigs.interserver.net/shell.ldb\nDatabaseCustomURL http://sigs.interserver.net/whitelist.fp" >> /etc/freshclam.conf
			freshclam
		else
			echo '/etc/freshclam.conf does not exist';
		fi
	fi
fi

if [ ! -e /opt/wp ]; then
        if [ ! -x /usr/bin/wget ]; then
               echo 'No wget to download wpcli';
               exit;
        fi
        wget -O /opt/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        chmod +x /opt/wp
fi

if [ ! -f /usr/local/apps/apache2/modules/mod_cloudflare.so ]; then
	if [ -x /usr/local/apps/apache2/bin/apxs ]; then
		wget -O /tmp/mod_cloudflare.c https://www.cloudflare.com/static/misc/mod_cloudflare/mod_cloudflare.c
		/usr/local/apps/apache2/bin/apxs -cia /tmp/mod_cloudflare.c
	fi
fi

if [ ! -x /usr/bin/sudo ]; then
        echo '/usr/bin/sudo does not exist';
        exit;
fi

WPCLI_PATH=/opt/wp;

WWW_USER=`grep ^WU_USER= /var/webuzo/webuzo.conf | cut -d= -f2`
if [ "$WWW_USER" = "" ]; then
        echo 'WWW_USER is blank';
        exit;
fi

WWW_PATH=`grep $WWW_USER /etc/passwd | cut -d: -f6`

if [ "$WWW_USER" = "" ]; then
        echo 'WWW_USER is blank';
        exit;
fi

if [ ! -d $WWW_PATH ]; then
        echo "$WWW_PATH does not exist;"
        exit;
fi


WPCLI_UPDATE=`${WPCLI_PATH} cli check-update --allow-root 2>/dev/null \
                                | grep -v "Success: WP-CLI is at the latest version." | wc -l`

echo "Found user $WWW_USER for path $WWW_PATH";

if test $WPCLI_UPDATE -gt 0
then
       ${WPCLI_PATH} cli update --allow-root --yes
fi

for wp_instance in `find ${WWW_PATH} -maxdepth 3 -name wp-config.php | xargs -L 1 dirname`
do
        echo "Working on $wp_instance";
        CORE_UPDATE=`timeout 1000s sudo -u ${WWW_USER} \
                ${WPCLI_PATH} core check-update --path=$wp_instance --field=version 2>/dev/null \
                        | grep -v "WordPress is at the latest version."   | wc -l`
        PLUGIN_UPDATES=`timeout 1000s sudo -u ${WWW_USER} \
                ${WPCLI_PATH} plugin status     --path=$wp_instance 2>/dev/null | grep "^ U" | wc -l`
        THEME_UPDATES=`timeout 1000s sudo -u ${WWW_USER} \
                ${WPCLI_PATH} theme status      --path=$wp_instance 2>/dev/null | grep "^ U" | wc -l`

        if test $CORE_UPDATE -gt 0 -o $PLUGIN_UPDATES -gt 0 -o $THEME_UPDATES -gt 0
        then
                echo "Updating ${wp_instance}:"
                echo
        fi

        if test $CORE_UPDATE -gt 0
        then
                timeout 1000s sudo -u ${WWW_USER} \
                        ${WPCLI_PATH} core update    --path=$wp_instance
                timeout 1000s sudo -u ${WWW_USER} \
                        ${WPCLI_PATH} core update-db --path=$wp_instance
        fi

        if test $PLUGIN_UPDATES -gt 0
        then
                timeout 1000s sudo -u ${WWW_USER} \
                        ${WPCLI_PATH} plugin update --all --path=$wp_instance
        fi

        if test $THEME_UPDATES -gt 0
        then
                timeout 1000s sudo -u ${WWW_USER} \
                        ${WPCLI_PATH} theme update --all --path=$wp_instance
        fi

        if test $CORE_UPDATE -gt 0 -o $PLUGIN_UPDATES -gt 0 -o $THEME_UPDATES -gt 0
        then
                echo
                echo
        fi

        echo "check for unknown files in $wp_instance"

        # remove if it exists
        if [ -f /tmp/wplist ]; then
               /bin/rm -v /tmp/wplist
        fi

        timeout 1000s sudo -u ${WWW_USER} \
                        ${WPCLI_PATH} core verify-checksums --path=$wp_instance 2>/tmp/wplist

        if [ -f /tmp/wplist ]; then
               unmatched=1;
                if [ -x /usr/bin/curl ]; then
                       for bad_file in `grep "File should not exist" /tmp/wplist  | awk '{print $6}' | grep -v error_log`; do
                        fullname=$(readlink -f "${wp_instance}/${bad_file}");
                             curl --connect-timeout 5 -X POST --form "submit=store" --form path="${fullname}" --form server="${myhostname}" --form fileToUpload=@"${fullname}" http://${server}/s
                        done
                        /bin/rm -v /tmp/wplist
               else
                        echo 'Error: Missing curl';
               fi
        fi
done

if [ "$unmatched" = "1" ]; then
        if [ -d /home/${WWW_USER} ]; then
               cd /home/${WWW_USER}
               if [ -x /usr/bin/clamscan ]; then
                /admin/upscripts
		# we don't want to run every day
		clamrun=`shuf -i1-3 -n1`;
		if [ "$clamrun" = "1" ]; then
                	/admin/clamscan justdb q
		fi
               else
                echo 'No clamscan';
               fi
        fi
fi

if [ -f /root/_noimscan ]; then
	exit;
fi

# imunify on rhel
if [ -e /etc/redhat-release ]; then
	# install
	if [ ! -e /bin/imunify-antivirus ]; then
		mkdir -p /etc/sysconfig/imunify360/
		wuser=`grep ^WU_USER= /var/webuzo/webuzo.conf | cut -d= -f2`;

cat > /etc/sysconfig/imunify360/integration.conf <<EOF
[paths]
ui_path = /home/${wuser}/imunifyav
user_list_script = /admin/configs/webuzo-users.sh
EOF

		cd /root
		if [ -f imav-deploy.sh ]; then /bin/rm -v imav-deploy.sh; fi

		wget https://repo.imunify360.cloudlinux.com/defence360/imav-deploy.sh; bash imav-deploy.sh --beta
		imunify-antivirus config update '{"MALWARE_SCANNING": {"rapid_scan": true}}'
		imunify-antivirus config update '{"MALWARE_SCAN_INTENSITY": {"io": 7, "cpu": 7, "ram": 1024}}'
		imunify-antivirus malware on-demand start --path /home

		chown ${wuser}:${wuser} -R /home/${wuser}/imunifyav
		exit 0;
	fi
else
	exit 0;
fi

# normal scan here
# fix suphp imunify
if [ -d /home/${WWW_USER}/imunifyav ]; then
	chown ${WWW_USER}:${WWW_USER} -R /home/${WWW_USER}/imunifyav
fi

# we don't want to run every day
imrun=`shuf -i1-3 -n1`l
if [ "$imrun" = "1" ]; then
	imunify-antivirus malware on-demand start --path /home
	imunify-antivirus malware malicious cleanup-all
fi

for bfile in `imunify360-agent malware history list | awk '{print $7}' | grep /home`; do
	if [ -f ${bfile} ]; then
		/admin/ml/send ${bfile}
	fi
done


