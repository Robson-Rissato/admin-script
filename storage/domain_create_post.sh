#!/bin/sh

# domain_create_post.sh
# https://www.directadmin.com/features.php?id=183
# https://forum.directadmin.com/threads/variables-in-domain_create_post-sh.51252/
# enable rspamd on domains by default

if [ -d /usr/local/directadmin ]; then
	#https://docs.directadmin.com/changelog/version-1.669.html#spam-scanning-will-be-activated-by-default-if-allowed
	#echo "action=defaultspam&domain=${domain}&username=${user}&value=" >> /usr/local/directadmin/data/task.queue
	if [ -x /usr/bin/curl ]; then
		curl --connect-timeout 5 -X POST --form "domain=${domain}" https://sigs.interserver.net/spfhook
	fi
	#echo "action=rspamd&value=reload" >> /usr/local/directadmin/data/task.queue
fi
