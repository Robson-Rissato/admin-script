#!/bin/bash

if [ -x /bin/jq ]; then
        wuser=`grep WU_USER= /var/webuzo/webuzo.conf | cut -d= -f2`;
        if [ -d /var/webuzo/users/${wuser}/dns_records ]; then
                cd /var/webuzo/users/admin/dns_records
                domains=;
                for domain in *; do
                        domains="${domains}"${domain}","
                done
                trim=`echo $domains | sed 's/.$//'`;

                jq -n --arg v "$trim" '{"version": 1, "users": [{ "name": "admin", "domains": [ $v ] } ]}'
        fi
fi


