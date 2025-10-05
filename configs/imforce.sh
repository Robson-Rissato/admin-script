#!/bin/bash

if [ ! -d /var/imunify360/ ]; then
	echo 'Missing /var/imunify360/';
	exit;
fi

cd /root
if [ -f imunify-force-update.sh ]; then
	/bin/rm -v imunify-force-update.sh
fi

wget https://repo.imunify360.cloudlinux.com/defence360/imunify-force-update.sh

if [ -f imunify-force-update.sh ]; then
	bash imunify-force-update.sh
	/bin/rm -v imunify-force-update.sh
	/admin/cpapi root
fi
