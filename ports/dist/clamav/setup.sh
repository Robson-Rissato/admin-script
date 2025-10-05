#!/bin/sh

if [ -z "`/usr/bin/id -g clamav 2>/dev/null`" ]; then
        /usr/sbin/groupadd -g 46 -r -f clamav 2>&1 || :
fi
if [ -z "`/usr/bin/id -u clamav 2>/dev/null`" ]; then
        /usr/sbin/useradd -u 46 -r -M -d /tmp  -s /sbin/nologin -c "Clam AntiVirus" -g clamav clamav 2>&1 || :
fi

if [ ! -e /usr/local/share/clamav ]; then
	mkdir /usr/local/share/clamav
	chown clamav:clamav /usr/local/share/clamav
fi
