#!/bin/bash

# 8/17/2025

#
# update litespeed update version
#

# added switch fast to skip findsuspected
# this is due for a rewrite

# this script does the following
#
# updates litespeed
# runs litespeed timezone db
# checks wswatch.sh is running
# remove lscheck.sh from cron
# add mccleanqueue
# update or install /opt/scan.sh if atomicmodsec exists
# addon domain protection from vhost.local
# update int rbls
# update int scanner mod sec
# update cpanel rules
# raise contract
# run findsyspenced
# add or update lfd monitoring
# update or add csf int config
# restart systemd-logn centos7 fix
# whmapi changes like no autossl, enable all services set cpanel autossl provider, spammer detection in tweak settings, bandwidth check
# update common domains
# set php 5.6 memory limit in cpanel
# change contact email from john@interserver.net
# update csf.txt
# turn off cpanel password reset
# log sucesssful logins in cpanel
# disable pagespeed litespeed
# remove files not needed badips and goodips
# phpint.txt
# mikes suspended page stuff
# disable cl_statistics_enabled
# clean monarx if exists
# turn off cpu scaling
# update softaculous universal.php settings
# run clean system
# update litespeed config
# resolv.conf update
# removes cpanel's file protect if cagefs is installed
# sets max emails per hour to 200 if set to unlimited
# disable acronis
# set max mails per hour to 200
# disable smtp tweak if csf is installed
# install memcached on shared
# restart csf if error
# link safe changes on cloudlinux
# cloudshield rename
# enable cagefs for all users
# create legacy /var/lib/clamav cagefs mount
# update int.cf spamassassin if exists and install ixhash
# run /admin/configs/allowlist_intrelay if needed
# set delayed kernelcare
# imunify change webshield name change template
# uceprotect lists for syncookies?! shit blacklist
# backup mysql.sql
# notes /admin/mccleanqueue runs on da and cpanel so some killall processes runn here
# disable cloudlinux resource notifications
# only run isput for mysql is swift is configured
# symlink old mysqldump and mysql commands on mariadb 11
# change to roundrobin relay

modsec=0;

if [ -e /admin/.info/_noupdatels ]; then
	exit;
fi

if [ -d /usr/local/directadmin ]; then
	echo 'Not designed for directadmin';
	exit;
fi

if [ -x /usr/local/lsws/admin/misc/lsup.sh ]; then
	# see if litespeed is running
	check=`ps auxw | grep [l]itespeed`;
	if [ ! "$check" = "" ]; then
		#/usr/local/lsws/admin/misc/lsup.sh || /usr/local/lsws/admin/misc/lsup.sh -f -v 5.4.7 -b 2
		/usr/local/lsws/admin/misc/lsup.sh && /bin/cp -u -f  /admin/configs/httpd_config.xml /usr/local/lsws/conf/httpd_config.xml
		# 4/8/2021 bug of license expires in 0 days
		/usr/local/lsws/bin/lshttpd -V
		#/bin/cp -u -f  /admin/configs/httpd_config.xml /usr/local/lsws/conf/httpd_config.xml
		#ea4 fix
		if [ -f /etc/cpanel/ea4/paths.conf ]; then
			/admin/replace-linux bin_apachectl=/usr/sbin/apachectl bin_apachectl=/usr/local/lsws/bin/lswsctrl -- /etc/cpanel/ea4/paths.conf
		fi

		# timezonedb
		TZDB=0;
		if [ -x /usr/local/lsws/add-ons/cpanel/lsws_whm_plugin/buildtimezone_ea4.sh ]; then
        		if [ -e /opt/cpanel ]; then
                		for PHPVER in `find /opt/cpanel -maxdepth 1 | grep /ea-php | cut -d/ -f4`; do
                        		if [ -f /opt/cpanel/$PHPVER/root/usr/lib64/php/modules/timezonedb.so ]; then
                                		echo $PHPVER 'has timezonedb'
                        		else
                                		echo $PHPVER 'does not have timezonedb we will install'
                                		TZDB=1;
						yum -y install $PHPVER-php-devel
                        		fi
                		done
        		else
                		echo 'TZDB needs easyapache4';
        		fi

        		if [ "$TZDB" = "1" ]; then
                		cd /usr/local/lsws/add-ons/cpanel/lsws_whm_plugin
                		/usr/local/lsws/add-ons/cpanel/lsws_whm_plugin/buildtimezone_ea4.sh y
        		fi
		fi


		#wscheck
		wscheck=`ps auxw | grep [w]swatch.sh`;
		if [ "$wscheck" = "" ]; then
			if [ -x /usr/local/lsws/bin/wswatch.sh ]; then
				echo 'Starting wswatch.sh';
				nohup /usr/local/lsws/bin/wswatch.sh &
			fi
		fi

		#wswatch takes care of this
		# this will be removable
		if [ -e /etc/cron.hourly/lscheck.sh ]; then
			/bin/rm /etc/cron.hourly/lscheck.sh
		fi

		# as will this
		if [ ! -e "/etc/cron.hourly/mccleanqueue" ] ; then
    			# code if the symlink is broken
    			/bin/rm /etc/cron.hourly/mccleanqueue
    			ln -s /admin/mccleanqueue /etc/cron.hourly/mccleanqueue
		fi

		if [ -e /etc/apache2/conf.d/atomicmodsec.conf ]; then
			echo 'Updating modsec ea4';
			/bin/cp -f -u /admin/ml/scan.sh /opt
			chown nobody:nobody /opt/scan.sh
			chmod 711 /opt/scan.sh


cat > /etc/apache2/conf.d/atomicmodsec.conf <<EOF
<IfModule Litespeed>

    SecAuditLog logs/modsec_audit.log
    SecDebugLog logs/modsec_debug.log
    SecDebugLogLevel 0
    SecDefaultAction "phase:2,deny,log,status:406"


##
## ModSecurity fixed global configuration directives
##

SecDataDir "/var/cpanel/secdatadir"

##
## ModSecurity manageable global configuration directives
##


SecAuditEngine "RelevantOnly"
SecRuleEngine "On"

##
## ModSecurity configuration file includes:
##

Include /etc/apache2/modsecurity.d/00_asl_whitelist.conf
Include /etc/apache2/modsecurity.d/00_asl_0_global.conf
Include /etc/apache2/modsecurity.d/00_int_rbl.conf
Include /etc/apache2/modsecurity.d/10_asl_antimalware.conf
Include /etc/apache2/modsecurity.d/10_asl_rules.conf
Include /etc/apache2/modsecurity.d/11_asl_adv_rules.conf
Include /etc/apache2/modsecurity.d/20_asl_useragents.conf
Include /etc/apache2/modsecurity.d/30_asl_antispam.conf
Include /etc/apache2/modsecurity.d/50_asl_rootkits.conf
Include /etc/apache2/modsecurity.d/60_asl_recons.conf
Include /etc/apache2/modsecurity.d/61_asl_recons_dlp.conf
Include /etc/apache2/modsecurity.d/99_asl_jitp.conf
Include /etc/apache2/modsecurity.d/99_int_scanner.conf

</IfModule>

EOF
modsec=1;

# addon domain protection
if [ ! -f /admin/.info/_novhostlocalupdate ]; then
	if [ -f /var/cpanel/templates/apache2_4/ssl_vhost.local ]; then
		/bin/rm -v /var/cpanel/templates/apache2_4/ssl_vhost.local /var/cpanel/templates/apache2_4/vhost.local
		/usr/local/cpanel//bin/build_apache_conf
		#/bin/cp -u -v /admin/scanner/ssl_vhost.local /admin/scanner/vhost.local /var/cpanel/templates/apache2_4 && /admin/scanner/rcache.sh
		#chmod 0640 /var/cpanel/templates/apache2_4/vhost.local
		#chmod 0640 /var/cpanel/templates/apache2_4/ssl_vhost.local
		#chown root:root /var/cpanel/templates/apache2_4/vhost.local /var/cpanel/templates/apache2_4/ssl_vhost.local
	fi
fi

if [ -f /etc/apache2/modsecurity.d/00_int_rbl.conf ]; then
	/bin/cp -f -u /admin/00_int_rbl.conf /etc/apache2/modsecurity.d/00_int_rbl.conf
fi

if [ -f /etc/apache2/modsecurity.d/99_int_scanner.conf [; then
	/bin/cp -f -u /admin/99_int_scanner.conf /etc/apache2/modsecurity.d/99_int_scanner.conf
fi
		elif [ -e /usr/local/apache/conf/atomicmodsec.conf ]; then
			echo 'Updating mod_sec ea3';
cat > /usr/local/apache/conf/atomicmodsec.conf <<EOF
<IfModule Litespeed>

    SecAuditLog logs/modsec_audit.log
    SecDebugLog logs/modsec_debug.log
    SecDebugLogLevel 0
    SecDefaultAction "phase:2,deny,log,status:406"


##
## ModSecurity fixed global configuration directives
##

SecDataDir "/var/cpanel/secdatadir"

##
## ModSecurity manageable global configuration directives
##


SecAuditEngine "RelevantOnly"
SecRuleEngine "On"

##
## ModSecurity configuration file includes:
##

Include /usr/local/apache/modsecurity.d/00_asl_whitelist.conf
Include /usr/local/apache/modsecurity.d/00_asl_0_global.conf
Include /usr/local/apache/modsecurity.d/00_int_rbl.conf
Include /usr/local/apache/modsecurity.d/10_asl_antimalware.conf
Include /usr/local/apache/modsecurity.d/10_asl_rules.conf
Include /usr/local/apache/modsecurity.d/11_asl_adv_rules.conf
Include /usr/local/apache/modsecurity.d/20_asl_useragents.conf
Include /usr/local/apache/modsecurity.d/30_asl_antispam.conf
Include /usr/local/apache/modsecurity.d/50_asl_rootkits.conf
Include /usr/local/apache/modsecurity.d/60_asl_recons.conf
Include /usr/local/apache/modsecurity.d/61_asl_recons_dlp.conf
Include /usr/local/apache/modsecurity.d/99_asl_jitp.conf
Include /usr/local/apache/modsecurity.d/99_int_scanner.conf
</IfModule>
EOF
/bin/cp -f -u /admin/ml/scan.sh /opt
chown nobody:nobody /opt/scan.sh
chmod 711 /opt/scan.sh
if [ -f /usr/local/apache/modsecurity.d/00_int_rbl.conf ]; then
	/bin/cp -f -u /admin/00_int_rbl.conf /usr/local/apache/modsecurity.d/00_int_rbl.conf
fi

if [ -f /usr/local/apache/modsecurity.d/99_int_scanner.conf ]; then
	/bin/cp -f -u /admin/99_int_scanner.conf /usr/local/apache/modsecurity.d/99_int_scanner.conf
fi

modsec=1;
		else
			echo 'No modsec installed';
		fi
		#rebuild httpd.conf
		if [ -x /usr/local/cpanel/bin/build_apache_conf ]; then
			echo 'Rebuilding apache for cpanel';
			/usr/local/cpanel/bin/build_apache_conf
			# restart after updating httpd.conf
			if [ -x /usr/local/lsws/bin/lswsctrl ]; then
				/usr/local/lsws/bin/lswsctrl restart
				sleep 2s;
				if [ "$modsec" = "1" ]; then
					echo 'Testing modsec';
					wget -O/dev/null http://localhost/?foo=http://www.example.com
					# update spamassassin to
					#cagefsctl --force-update
				fi
			fi
		if [ -e /proc/sys/net/nf_conntrack_max ]; then
			if [ -e /admin/.info/raisecontrackmore ]; then
				echo 4096000 > /proc/sys/net/nf_conntrack_max
			elif [ -e /admin/.info/raisecontrack ]; then
				echo 1512000 > /proc/sys/net/nf_conntrack_max
			else

				echo 512000 > /proc/sys/net/nf_conntrack_max
			fi
			sysctl -p
		fi
		else
			echo 'cPanel not detected';
		fi
	fi
else
	echo 'Litespeed not installed';
fi

if [ "$1" = "fast" ]; then
	exit;
fi

if [ "$modsec" = "1" ]; then
	if [ ! -d /etc/asl ]; then
		mkdir -p /etc/asl
		touch /etc/asl/whitelist
	fi
	if [ -x /admin/ml/findsuspected ]; then
		/admin/ml/findsuspected
	fi

	if [ -x /admin/ml/intcsf ]; then
		/admin/ml/intcsf
	fi
	
	if [ -e /etc/chkserv.d/lfd ]; then
		/bin/cp -f -u /admin/configs/lfd.chkservd /etc/chkserv.d/lfd
	fi

fi


# slow ssh login fix centos7
if [ -x /usr/bin/systemctl ]; then
	systemctl restart systemd-logind
fi

# swift backup disk check if enabled
if [ -e /etc/cron.d/swift_backup.sh ]; then
	/admin/swift/cpanelbackup diskcheck all
fi

/admin/configs/lscache



if [ -e /proc/sys/kernel/pid_max ]; then
	echo 1048576 > /proc/sys/kernel/pid_max
fi

if [ -e /usr/sbin/whmapi1 ]; then
	# disable cpdavd due to security issues
	# this has been resolved now in tsr from 11/18
	if [ ! -f /etc/cpdavddisable ]; then
		/usr/sbin/whmapi1 configureservice service=cpdavd enabled=1 monitored=1
	fi

	# max emails per hour was not set on webhosting2014
	/usr/sbin/whmapi1 set_tweaksetting key=maxemailsperhour value=201

	# disable email for autossl
	/usr/sbin/whmapi1 set_application_contact_event_importance app=AutoSSL event=CertificateExpiring importance=Disabled
	
	# up/downgrade accounts
	/usr/sbin/whmapi1 set_application_contact_event_importance app=upacct event=all importance=Disabled

	# monitor all services	
	/usr/sbin/whmapi1 enable_monitor_all_enabled_services

	# set comodo this is depreciated
	#/usr/sbin/whmapi1 set_autossl_provider provider=cPanel
	sslcheck=`whmapi1 get_autossl_providers | grep -A 1 "enabled: 1" | grep module_name | awk '{print $2}'`;
        # change over to LE if needed
        if [ "$sslcheck" = "cPanel" ]; then
		whmapi1 set_autossl_provider provider=LetsEncrypt x_terms_of_service_accepted=https://letsencrypt.org/documents/LE-SA-v1.4-April-3-2024.pdf
	fi
	# domains to not permit addon domains 
	/bin/cp -u -f /admin/ml/commondomains /var/cpanel/commondomains

	# php 5.6 default settings
	/usr/sbin/whmapi1 php_ini_set_directives directive-1=post_max_size%3A32M directive-2=upload_max_filesize%3A128M directive-3=memory_limit%3A256M version=ea-php56
	
	# 7.2 is the new default
	/usr/sbin/whmapi1 php_ini_set_directives directive-1=post_max_size%3A32M directive-2=upload_max_filesize%3A128M directive-3=memory_limit%3A256M version=ea-php72

	# change contact email if set to john
	grep "^CONTACTEMAIL john@interserver.net" /etc/wwwacct.conf; if [ "$?" = "0" ]; then whmapi1 update_contact_email contact_email=not-monitored-email%40interserver.net; fi

	# clean out trash
	/usr/sbin/whmapi1 set_tweaksetting key=empty_trash_days value=14

	# bandwidth check
	whmapi1 set_tweaksetting key=skipbwlimitcheck value=0

	# csf.conf settings shared hosting only
	if [ -f /root/.swift/config ]; then
		if [ -e /usr/lib/Acronis ]; then
			/bin/cp -v -u -f /admin/configs/csf.conf.acronis /etc/csf/csf.conf && service lfd restart && csf -r
		else
			/bin/cp -v -u -f /admin/configs/csf.conf.txt /etc/csf/csf.conf && service lfd restart && csf -r
		fi
		#for asl whitelist
		whmapi1 set_tweaksetting key=log_successful_logins value=1

		#latest malware uses cpanel reset password
		whmapi1 set_tweaksetting key=resetpass_sub value=0
		whmapi1 set_tweaksetting key=resetpass value=0

		# spammer detection
		whmapi1 set_tweaksetting key=email_outbound_spam_detect_enable value=1
		whmapi1 set_tweaksetting key=email_outbound_spam_detect_action value=hold
		whmapi1 set_tweaksetting key=email_outbound_spam_detect_threshold value=250

		# cnc botnet
		csf --deny 216.218.185.162
	fi

fi

# we are disabling pagespeed for now
if [ -f /etc/apache2/conf.d/includes/pre_main_global.conf ]; then
        pagespeedcheck=`grep pagespeed /etc/apache2/conf.d/includes/pre_main_global.conf`;
        if [ "$pagespeedcheck" = "" ]; then
                if [ -f /usr/local/lsws/modules/modpagespeed.so ]; then
                        cat >> /etc/apache2/conf.d/includes/pre_main_global.conf <<EOF

<IfModule Litespeed>
 LoadModule pagespeed_module /usr/local/lsws/modules/modpagespeed.so
 ModPagespeedFileCachePath  /var/pagespeed/cache/
 ModPagespeed off
</IfModule>

EOF
                fi
        fi
fi

# this file is not needed
if [ -f /etc/apache2/modsecurity.d/badips.sh ]; then
	/bin/rm -v /etc/apache2/modsecurity.d/badips.sh
fi

if [ -f /etc/apache2/modsecurity.d/goodips.sh ]; then
        /bin/rm -v /etc/apache2/modsecurity.d/goodips.sh
fi

if [ -f /etc/apache2/modsecurity.d/buildaslwhitelist.sh ]; then
        /bin/rm -v /etc/apache2/modsecurity.d/buildaslwhitelist.sh
fi


# update phpmmdrop ini if needed
if [ -f /opt/cpanel/ea-php71/root/etc/phpint.ini ]; then
	if [ -f /admin/configs/cpanel/phpint.ini ]; then
		/bin/cp -u /admin/configs/cpanel/phpint.ini /opt/cpanel/ea-php71/root/etc/phpint.ini
	fi
fi

# for wordpress manager
if [ -f /opt/cpanel/ea-php56/root/etc/php.d/300-suhosin.ini ]; then
	grep phar /opt/cpanel/ea-php56/root/etc/php.d/300-suhosin.ini; if [ "$?" = "0" ]; then echo "nothing to do"; else echo "adding phar";  echo "suhosin.executor.include.whitelist = phar" >> /opt/cpanel/ea-php56/root/etc/php.d/300-suhosin.ini; fi
fi
# systemctl may make this unnecessary
if [ ! -e /etc/cron.hourly/lscheck.sh ]; then
	ln -s /admin/lscheck.sh /etc/cron.hourly/lscheck.sh
fi

# mikes suspendedpage template
if [ -x /admin/configs/cpanel/cpaneltemplate ]; then
	/admin/configs/cpanel/cpaneltemplate
fi

# update timezonedb in php
if [ -x /admin/configs/cpanel/fixtimezonedb ]; then
	/admin/configs/cpanel/fixtimezonedb
fi

# remove pagespeed config in litespeed if it exists
# because it hurts performance
if [ -f /etc/apache2/conf.d/pagespeed.conf ]; then
	/bin/rm -v /etc/apache2/conf.d/pagespeed.conf
fi

# remove patchman in cpanel if we have removed the patchman agent
if [ ! -x /usr/local/patchman/patchmand ]; then
	if [ -f /usr/local/cpanel/base/frontend/paper_lantern/dynamicui/dynamicui_patchman.conf ]; then
		/bin/rm -v /usr/local/cpanel/base/frontend/paper_lantern/dynamicui/dynamicui_patchman.conf
	fi
fi

# maldet cron
# this was spiking load on webhosting2017
# we don't want it to run automatically since it doesn't scale well
# also we have alternatives to malware scanning
if [ -f /etc/cron.d/maldet_pub ]; then
	/bin/rm -v /etc/cron.d/maldet_pub
fi

if [ -f /etc/cron.daily/maldet ]; then
	/bin/rm -v /etc/cron.daily/maldet
fi

#disable cloudlinux stats was done due to high load for acronis now acronis is replaced
if [ -f /etc/sysconfig/cloudlinux ]; then
	if [ -e /usr/sbin/cloudlinux-config ]; then
		cloudlinux-config set --json --data '{"options":{"uiSettings":{"hideRubyApp":false, "hidePythonApp":false, "hideLVEUserStat":false}}}'
	fi
	# enable if acronis is not running
	if [ -d /etc/Acronis ]; then
		if [ "$(grep ^cl_statistics_enabled=0$ /etc/sysconfig/cloudlinux)" = "cl_statistics_enabled=0" ]; then
			echo 'CL statistics are disabled';
		else
			echo 'Disabling usage statitics in cloudlinux';
			# 2017 did not have a line break at the end so we add in \n to be sure
 			#echo -e "\ncl_statistics_enabled=0" >> /etc/sysconfig/cloudlinux
			/admin/replace-linux cl_statistics_enabled=1 cl_statistics_enabled=0 -- /etc/sysconfig/cloudlinux
		fi
	else
		cloudlinux-summary enable
	fi
fi

# cloudshield rename
if [ -f /etc/imunify360-webshield/webshield.conf ]; then
	if [ -x /admin/replace-linux ]; then
		/admin/replace-linux imunify360-webshield/1.8 interserver-webshield/1.8 -- /etc/imunify360-webshield/webshield.conf && systemctl restart imunify360-webshield.service
		/bin/cp -f /admin/configs/cpanel/body.tpl /usr/share/imunify360-webshield/captcha/templates/body.tpl
	fi
	# limit load of previous scanner with webshield installed
	if [ ! -f /admin/scanner/_lowlocate ]; then
		touch /admin/scanner/_lowlocate
	fi
fi

if [ -d /var/cache/monarx-export ]; then
	if [ -x /usr/sbin/tmpwatch ]; then
		tmpwatch -c 72 -v /var/cache/monarx-export/
	fi
fi

# stop scaling on webhosting servers
if [ -e /sys/devices/system/cpu ]; then
	for CPUFREQ in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do [ -f $CPUFREQ ] || continue; echo -n performance > $CPUFREQ; done
fi

# update softaculous on interserver systems 
# while in this loop also set cpanel max emails to 200 from unlimited
if [ -f /root/.swift/config ]; then
	if [ -f /usr/local/cpanel/whostmgr/docroot/cgi/softaculous/enduser/universal.php ]; then
		if [ -f /admin/configs/universal.php ]; then
			/bin/cp -f -u /admin/configs/universal.php /usr/local/cpanel/whostmgr/docroot/cgi/softaculous/enduser/universal.php		
		fi
		# rename wordpress manager
		if [ -x /usr/local/cpanel/3rdparty/bin/php ]; then
			if [ -x /usr/local/cpanel/whostmgr/docroot/cgi/softaculous/cli.php ]; then
				/usr/local/cpanel/3rdparty/bin/php /usr/local/cpanel/whostmgr/docroot/cgi/softaculous/cli.php --rebuild_wordpress_manager --title="Wordpress Manager"
			fi
		fi
	fi
	# clean system in this method
	if [ -f /admin/configs/clean_system.sh ]; then
		/admin/configs/clean_system.sh run
	fi

	# max emails per hour
	if [ -d /var/cpanel/users ]; then
		cd /var/cpanel/users && /admin/replace-linux MAX_EMAIL_PER_HOUR=unlimited MAX_EMAIL_PER_HOUR=200 -- * && /scripts/updateuserdomains && /scripts/restartsrv_cpsrvd
	fi
fi

if [ -e /etc/apache2/conf.d/passenger.conf ]; then yum -y remove ea-ruby24-mod_passenger; fi
if [ -e /opt/passenger-5.3.7-4.el7.cloudlinux ]; then yum -y remove alt-mod-passenger; yum -y install ea-apache24-mod-alt-passenger; fi

if [ -f /admin/resolvconf ]; then
	/admin/resolvconf
fi

# no need for cagefs and file protect
# file protect seems to cause issues with litespeed
if [ -f /var/cpanel/fileprotect ]; then
	if [ -f /usr/sbin/cagefsctl ]; then
		cagefsctl --enable-all && /scripts/disablefileprotect && /bin/rm -v /var/cpanel/fileprotect
	fi
fi

# disable acronis cpanel side restore until kernel issue between acronis mounts and cloudlinux is fixed
if [ -e /usr/local/cpanel/base/3rdparty/acronisbackup ]; then
	/usr/sbin/whmapi1 update_featurelist featurelist=default acronisbackup=0
fi

if [ -e /usr/sbin/csf ]; then
	
	# disable smtp tweak
	if [ -e /scripts/smtpmailgidonly ]; then
		if [ -f /root/.swift/config ]; then
			/scripts/smtpmailgidonly off
		fi
	fi

	# restart if csf has an error
	if [ -f /etc/csf/csf.error ]; then /bin/rm -v /etc/csf/csf.error; csf -r; lfd -r; fi

fi

#linksafe changes
if [ -f /etc/sysctl.d/cloudlinux-linksafe.conf ]; then 
	/admin/replace-linux "fs.protected_symlinks_create = 1" "fs.protected_symlinks_create = 0" -- /etc/sysctl.d/cloudlinux-linksafe.conf
	/admin/replace-linux "fs.protected_hardlinks_create = 1" "fs.protected_hardlinks_create = 0" -- /etc/sysctl.d/cloudlinux-linksafe.conf
fi 

sysctl -p


# enable memcache on interserver shared hosting
if [ ! -f /usr/bin/memcached ]; then
	if [ -f /root/.swift/config ]; then
		if [ -e /usr/bin/systemctl ]; then
			yum -y install memcached; systemctl disable memcached.service		
		fi
	fi
fi

# enable cagefs for all users
# issue here
# while we sortof want to do this, the issue is a --enable-all will kill processes running in the lve
# so we only want to run this if needed
# we will do this only on sunday
if [ -f /usr/sbin/cagefsctl ]; then
	date=`date +%u`;
		#1 - 7 day of week monday is 1
		if [ "$date" = "7" ]; then
			if [ ! -f /admin/.info/_skip_cagefs_enable_all_check ]; then
			/usr/sbin/cagefsctl --enable-all
			# legacy cagefs mount
			if [ ! -d /var/lib/clamav ]; then
				mkdir -p /var/lib/clamav
			fi
		fi
	fi
fi

if [ -f /etc/mail/spamassassin/INT.cf ]; then
	# ixhash
	if [ -x /admin/configs/cpanel/install_ix ]; then
		/admin/configs/cpanel/install_ix
	fi
        /bin/cp -u /admin/configs/cpanel/INT.cf /etc/mail/spamassassin/INT.cf && echo "updated INT.cf spamassassin";
	if [ -e /usr/local/cpanel/3rdparty/bin/sa-update ]; then
		/usr/local/cpanel/3rdparty/bin/sa-update -D; PERL_MM_OPT='' /usr/local/cpanel/3rdparty/bin/sa-compile; 
		if [ -e /usr/sbin/cagefsctl ]; then
			cagefsctl --force-update; 
		fi
		/scripts/restartsrv_spamd; /scripts/restartsrv_exim
	fi
fi

if [ -f /admin/configs/allowlist_intrelay ]; then
	/admin/configs/allowlist_intrelay
fi

#delayed feed. 24 hours on webhosting. There is also 48 hours.
# 8/10/2020 -burned again
if [ -f /etc/sysconfig/kcare/kcare.conf ]; then
	echo 'Found kcare sysconfig file';
        kcarecheck=`grep ^PREFIX= /etc/sysconfig/kcare/kcare.conf`;
        if [ "$kcarecheck" = "" ]; then
                echo "PREFIX=24h" >> /etc/sysconfig/kcare/kcare.conf
       		echo 'added 24h prefix';
        else
                echo 'Delayed update prefix already added';
        fi

fi

# uceprotect will add ips for syncookies
if [ -d /proc/sys/net/ipv4/tcp_syncookies ]; then
	echo 0 > /proc/sys/net/ipv4/tcp_syncookies
fi



# backup mysql users table
if [ -d /usr/local/cpanel ]; then
	# drop spam
	# 66.254.0.0/19 needs to release 173.225.96.0/20
	for range in 104.128.144.0/20 65.39.244.0/24 66.254.0.0/19 185.165.186.2; do
		if [ -f /etc/spammeripblocks ]; then
			rcheck=`grep ^${range}$ /etc/spammeripblocks`;
			if [ "$rcheck" = "" ]; then
				echo "adding $range to /etc/spammeripblocks";
				echo $range >> /etc/spammeripblocks
			fi
		fi
	done

	if [ ! -d /backup/mysql ]; then
		mkdir -p /backup/mysql
	fi
	cd /backup/mysql
	today=`/bin/date +%m-%d-%Y`;
	mysqldump --skip-extended-insert --single-transaction -u root mysql | gzip --stdout > mysql.sql.${today}
	if [ -f /root/.swift/hostname ]; then
		hostname=`cat /root/.swift/hostname`;
	else
		hostname=`hostname`;
	fi

	if [ -f /root/.swift/config ]; then
		/admin/swift/isput $hostname /backup/mysql/mysql.sql.${today} mysql.sql.${today}
		/admin/swift/deleteafter $hostname mysql.sql.${today} 60
	fi

	tmpwatch -c 128 -v /backup/mysql

	# geo ip update
	if [ ! -d /usr/share/GeoIP/ ]; then
		mkdir -p /usr/share/GeoIP/
	fi
	if [ ! -f /usr/share/GeoIP/GeoLite2-Country.mmdb ]; then
		cp /admin/configs/geo/GeoLite2-Country.mmdb /usr/share/GeoIP/GeoLite2-Country.mmdb && chown root:root /usr/share/GeoIP/GeoLite2-Country.mmdb
	else
		/bin/cp -u -v /admin/configs/geo/GeoLite2-Country.mmdb /usr/share/GeoIP/GeoLite2-Country.mmdb && chown root:root /usr/share/GeoIP/GeoLite2-Country.mmdb
	fi
fi

# cloudlinux8 lvemanager is being removed so lets check for 8
cl_8=`cat /etc/redhat-release  | cut -d" " -f3 | cut -d. -f1`;
if [ "$cl_8" = "8" ]; then
	echo 'Cloudlinux 8 detected';
	yum -y install lvemanager
fi

if [ -f /root/.bash_profile -o -f /root/.bashrc ]; then
        if [ -f /root/.bash_profile ]; then
                thefile=/root/.bash_profile;
        elif [ -f /root/.bashrc ]; then
                thefile=/root/.bashrc;
        else
                echo 'Error in histtimeformat: How did I get there';
                exit;
        fi

        hcheck=`grep HISTTIMEFORMAT ${thefile}`;
        if [ "$hcheck" = "" ]; then
                echo 'Adding histtimeformat';
                echo 'export HISTTIMEFORMAT="%m/%d/%y %T "' >> ${thefile}
        else
                echo 'Histtimeformat is done';
        fi
fi

if [ ! -e /usr/bin/python ]; then
	if [ -x /usr/bin/python2.7 ]; then
		ln -s /usr/bin/python2.7 /usr/bin/python
	fi
fi

# for albert count the number of users in cpanel
if [ -d /home/quags ]; then
        if [ -d /var/cpanel/users ]; then
                ls /var/cpanel/users | grep "system|root" -vw | wc -l > /home/quags/usercount
        fi
fi

# disable resource notifications
if [ -x /usr/sbin/cloudlinux-config ]; then
        cloudlinux-config set --json --data '{"options":{"faultsNotification":{"notifyCustomers":false}}}'
fi

# symlink mysql for compatibility
if [ -e /usr/bin/mariadb-dump ]; then
	if [ ! -e /usr/bin/mysqldump ]; then
		ln -s /usr/bin/mariadb-dump /usr/bin/mysqldump
	fi
fi

if [ -e /usr/bin/mariadb ]; then
	if [ ! -e /usr/bin/mysql ]; then
		ln -s /usr/bin/mariadb /usr/bin/mysql
	fi
fi

# relay change
if [ -f /etc/exim.conf.local ]; then
        relaycheck=`grep "webhosting-mailchannels-outbound.is.cc" /etc/exim.conf.local | awk '{print $4}'`;
        if [ "$relaycheck" = "webhosting-mailchannels-outbound.is.cc" ]; then
                if [ -x /admin/replace-linux ]; then
                        /admin/replace-linux webhosting-mailchannels-outbound.is.cc webhosting-relay.interserver.net -- /etc/exim.conf.local && /scripts/buildeximconf
                else
                        echo '/admin/replace-linux missing to replace /etc/exim.conf.local relay';
                fi
        fi
fi


if [ -f /etc/sudoers.d/quags ]; then
	myhostname=`hostname`;
	mydate=`date`;
	logincheck=`cat /usr/local/cpanel/logs/access_log | grep "\- root \[" | grep "HTTP/1.1\" 200" | grep -v "FAILED LOGIN"  | awk '{print $1 " " $3 " " $4}'  | rev | cut -d: -f4- | rev | sort | uniq | egrep -v "66.45.228.251|106.51.49.165|66.45.233.83|66.45.235.105|88.198.109.76|66.45.235.226|66.45.235.94|173.225.104.170|216.158.226.14|192.64.80.218|162.220.165.125" | grep root | grep "\["`;
	if [ ! "$logincheck" = "" ]; then
        	echo "${logincheck}" | mail -s "login check on $myhostname at $mydate" john@interserver.net
	fi

	if [ -d /home/quags ]; then
		random=`openssl rand -base64 16`;
		if [ ! "$random" = "" ]; then
			echo $random | passwd --stdin root
			echo "random root has been set";
		fi
	fi
fi
