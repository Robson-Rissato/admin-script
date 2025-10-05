#!/bin/bash

# create mailchannels config
# touch /etc/static_route to exclude forwarders. MC cron will rebuild everything.

if [ -f /admin/.info/intrelay ]; then
	echo 'Exit on /admin/.info/intrelay';
	exit;
fi


if [ "$1" = "" ]; then
	echo -n "Enter password: ";
	read pass
elif [ "$1" = "fix" ]; then
	if [ ! -f /etc/exim.conf.local ]; then
		echo 'Can not fix with out /etc/exim.conf.local (da support not added)';
		exit;
	fi
	pass=$(grep "client_send = : interserver" /etc/exim.conf.local | awk '{print $6}');

else
	pass=$1;
fi

hostname=`hostname`;

if [ -f /scripts/buildeximconf ]; then
        echo 'cPanel detected';

# begin default config
cat > /etc/exim.conf.local <<EOF
%RETRYBLOCK%
+secondarymx                    *                               F,4h,5m; G,16h,1h,1.5; F,4d,8h
*                               *                               F,2h,15m; G,16h,1h,1.5; F,4d,8h
*                               auth_failed
@AUTH@
mailchannels_login:
 driver = plaintext
 public_name = LOGIN
 client_send = : interserver : $pass
@BEGINACL@

@CONFIG@
allow_mx_to_ip = yes
chunking_advertise_hosts = ""
local_from_check = true
message_size_limit = 100M
openssl_options = +no_sslv2 +no_sslv3
ignore_bounce_errors_after = 1h
timeout_frozen_after = 12h
smtp_accept_max = 300




@DIRECTOREND@


@DIRECTORMIDDLE@

@DIRECTORSTART@

@ENDACL@

@POSTMAILCOUNT@

EOF

# this can vary
	if [ -f /etc/static_route ]; then

		echo 'Using static route config';
		sleep 1s;

cat >> /etc/exim.conf.local <<EOF
send_via_mailchannels:
 driver = manualroute
 domains = !+local_domains
 condition = "\${if eq{\${lookup{\$sender_address_domain}partial-lsearch{/etc/static_route}{\$value}}}{}{false}{true}}"
 headers_add = "\${perl{mailtrapheaders}}"
 transport = mailchannels_smtp
 route_list = !+local_domains "\${lookup{\$sender_address_domain}partial-lsearch{/etc/static_route}}"

EOF

# end static_route block

	else
		# begin legacy non static_route
		echo 'Using legacy non static route method';
		sleep 1s;
cat >> /etc/exim.conf.local <<EOF
remoteserver_route:
 driver = manualroute
 transport = mailchannels_smtp
 domains = !+local_domains
 senders = !root@${hostname} : !not-monitored-email@interserver.net
 route_list = * smtp.mailchannels.net::25 randomize byname

EOF

	fi

# finish standard config
cat >> /etc/exim.conf.local <<EOF

@PREDOTFORWARD@

@PREFILTER@

@PRELOCALUSER@

@PRENOALIASDISCARD@

@PREROUTERS@

@PREVALIASNOSTAR@

@PREVALIASSTAR@

@PREVIRTUALUSER@

@RETRYEND@

@RETRYSTART@
*                               data_4xx                        F,4h,1m
*                               rcpt_4xx                        F,4h,1m
*                               timeout                         F,4h,1m
*                               refused                         F,1h,5m
*                               lost_connection                 F,1h,1m
*                               *                               F,6h,5m

@REWRITE@

@ROUTEREND@

@ROUTERMIDDLE@

@ROUTERSTART@

@TRANSPORTEND@

@TRANSPORTMIDDLE@

@TRANSPORTSTART@

    mailchannels_smtp:
    driver = smtp
    hosts_require_auth = *
    tls_tempfail_tryclear = true
    headers_add = X-AuthUser: \${if match {\$authenticated_id}{.*@.*}    {\$authenticated_id} {\${if match {\$authenticated_id}{.+}  {\$authenticated_id@\$primary_hostname}{\$authenticated_id}}}}
    dkim_domain = \$sender_address_domain
    dkim_selector = default
    dkim_canon = relaxed
    dkim_private_key = "/var/cpanel/domain_keys/private/\${dkim_domain}"

EOF
# end exim.conf.local

	hostname=`hostname`;
	if [ -f /etc/localdomains ]; then
		check=`grep ^${hostname}$ /etc/localdomains`;
		if [ "$check" = "" ]; then
			echo $hostname >> /etc/localdomains
			echo 'adding in hostname to /etc/localdomains';
			sleep 1s;
		fi
	fi
	# set config and rebuild
	replace rewrite_from=all rewrite_from=disable -- /etc/exim.conf.localopts
	/scripts/update_db_cache
	/scripts/buildeximconf && /scripts/restartsrv_exim

	# cron to ensure everything is working correctly

	if [ -f /admin/mailchannelscron ]; then
		/admin/mailchannelscron
		if [ ! -e /etc/cron.daily/mailchannelscron ]; then
			cd /etc/cron.daily && ln -s /admin/mailchannelscron
		fi
	fi

	if [ ! -e /usr/local/cpanel/3rdparty/bin/clamd ]; then
		/admin/installcpanelclamav
	fi

	if [ ! -e /etc/cron.hourly/mccleanqueue ]; then
		cd /etc/cron.hourly && ln -s /admin/mccleanqueue
	fi

	if [ ! -e /etc/cron.d/virusscanner_php.sh ]; then
		/admin/scanner/create.sh cron
	fi
elif [ -d /usr/local/directadmin ]; then
	echo 'Directadmin detected';
	if [ -f /etc/exim.routers.pre.conf ]; then /bin/rm -v /etc/exim.routers.pre.conf; fi
	if [ -f /etc/exim.transports.pre.conf ]; then /bin/rm -v /etc/exim.transports.pre.conf; fi
	if [ -f /etc/exim.authenticators.post.conf ]; then /bin/rm -v /etc/exim.authenticators.post.conf; fi
	wget -O /etc/exim.routers.pre.conf http://files.directadmin.com/services/SpamBlocker/smart_route/exim.routers.pre.conf
	wget -O /etc/exim.transports.pre.conf http://files.directadmin.com/services/SpamBlocker/smart_route/exim.transports.pre.conf
	wget -O /etc/exim.authenticators.post.conf http://files.directadmin.com/services/SpamBlocker/smart_route/exim.authenticators.post.conf

	/admin/replace-linux "your@email.com" "interserver" -- /etc/exim.authenticators.post.conf
	/admin/replace-linux "yourpass" ${pass} -- /etc/exim.authenticators.post.conf
	/admin/replace-linux "smtp.yourisp.com" "smtp.mailchannels.net" -- /etc/exim.routers.pre.conf
	echo "		headers_add = X-AuthUser: \$authenticated_id" >> /etc/exim.transports.pre.conf
	cd /usr/local/directadmin/custombuild
	./build exim_conf

        if [ ! -e /etc/cron.hourly/mccleanqueue ]; then
                cd /etc/cron.hourly && ln -s /admin/mccleanqueue
        fi


else

	echo 'Type not detected';

fi

