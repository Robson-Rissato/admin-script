#!/usr/bin/env bash

if [ ! -d /usr/local/directadmin ]; then
	echo 'Requires directadmin';
	exit;
fi

version=`mysql -V | awk '{print $3}' | cut -d. -f1`;


if [ -f /var/www/html/roundcube/config/config.inc.php ]; then
 pw=`grep mysql:// /var/www/html/roundcube/config/config.inc.php | cut -d: -f3 | cut -d@ -f1`;
 if [ "$pw" = "" ]; then
  echo 'no pass found';
   exit;
 else
if [ "$version" = "8" ]; then
  echo "ALTER USER da_roundcube@'localhost' identified by '$pw'" | mysql mysql
 else
  echo "grant all on da_roundcube.* to da_roundcube@'localhost' identified by '$pw'" | mysql mysql
  echo "grant all on da_roundcube.* to da_roundcube@'127.0.0.1' identified by '$pw'" | mysql mysql
 fi
  mysqladmin reload
 fi
fi
