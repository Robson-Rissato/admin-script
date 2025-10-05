#!/bin/sh

#######################################################################################
# This script is to set server and virtual host level cache root and cache policies for LSCache.
# @Author:   LiteSpeed Technologies, Inc. (https://www.litespeedtech.com)
# @Copyright: (c) 2016
#######################################################################################

LSCONFPATH=/usr/local/lsws/conf

check_errs()
{
  if [ "${1}" -ne "0" ] ; then
    echo "[ERROR] ${2}"
    exit ${1}
  fi
}

INST_USER=`id`
INST_UID=`expr "$INST_USER" : 'uid=\(.*\)(.*) gid=.*'`
INST_USER=`expr "$INST_USER" : 'uid=.*(\(.*\)) gid=.*'`
if [ $INST_UID != "0" ] ; then
    check_errs 1 "Only root user can run this script!"
fi

display_usage()
{
    cat <<EOF
The script will setup server and virtual host level of cache roots set cache policies for LSCache.
It works with cPanel and Plesk control panel.

EOF
    exit 1
}

verify_license()
{
  echo "Need to verify Licenses!"
}

reset_cache_polity()
{
#set cache policy in LSWS config
#remove any server level of cache root set in LSWS config
#Backup configuration file
  echo ""
  echo "Backup $LSCONFPATH/httpd_config.xml to  $LSCONFPATH/httpd_config.xml.bak_lscache"
  yes | cp -pf $LSCONFPATH/httpd_config.xml $LSCONFPATH/httpd_config.xml.bak_lscache
  echo "Check and remove any server level cache root and policy setting in LSWS config."
  sed -i '/<cacheStorePath>/d' $LSCONFPATH/httpd_config.xml

#remove any cache policy
  sed -i '/<enableCache>/d' $LSCONFPATH/httpd_config.xml
  sed -i '/<checkPublicCache>/d' $LSCONFPATH/httpd_config.xml
  sed -i '/<maxCacheObjSize>/d' $LSCONFPATH/httpd_config.xml
  sed -i '/<expireInSeconds>/d' $LSCONFPATH/httpd_config.xml
  sed -i '/<maxStaleAge>/d' $LSCONFPATH/httpd_config.xml
  sed -i '/<qsCache>/d' $LSCONFPATH/httpd_config.xml
  sed -i '/<reqCookieCache>/d' $LSCONFPATH/httpd_config.xml
  sed -i '/<ignoreReqCacheCtrl>/d' $LSCONFPATH/httpd_config.xml
  sed -i '/<enablePrivateCache>/d' $LSCONFPATH/httpd_config.xml
  sed -i '/<checkPrivateCache>/d' $LSCONFPATH/httpd_config.xml
  sed -i '/<privateExpireInSeconds>/d' $LSCONFPATH/httpd_config.xml

#restart LSWS
  service lsws restart
}

set_cache_root_policy_cpanel()
{
#remove the folder in case it was manually created and has permission problem
#rm -rf /home/lscache
echo ""

if [ -e "/etc/cpanel/ea4/is_ea4" ] ; then
  APACHECONFD=/etc/apache2/conf.d
else
  APACHECONFD=/usr/local/apache/conf
fi

#set server level cache root
if grep -q CacheRoot $APACHECONFD/includes/pre_main_global.conf
then
  #If cache root has been set, delete it to avoid permission issue
  SCROOT=`grep CacheRoot $APACHECONFD/includes/pre_main_global.conf | cut -d' ' -f2`
  echo "Found server level cache root has already been set to: $SCROOT"
#  rm -rf $SCROOT
else
  cat >> $APACHECONFD/includes/pre_main_global.conf <<EOF
<IfModule Litespeed>
CacheRoot /home/lscache/
</IfModule>
EOF
  echo "Server level cache root is set to /home/lscache."
  echo ""
fi

  echo "List server root level cache root configuration files:"
  grep -R CacheRoot $APACHECONFD/includes/
  echo ""

#set virtual host level cache root

if grep -q CacheRoot $APACHECONFD/userdata/*
then
  VHCROOT=`grep CacheRoot $APACHECONFD/userdata/* | cut -d' ' -f2`
  echo "Found virtual host level cache root set to: /home/username/$VHCROOT"
  echo "List virtual host level cache root configuration files:"
  grep -R CacheRoot $APACHECONFD/userdata/

else
  echo "Don't worry. We will make the changes for you!"
  mkdir -p $APACHECONFD/userdata/
  cat > $APACHECONFD/userdata/lscache_vhosts.conf <<EOF
<IfModule Litespeed>
CacheRoot lscache
</IfModule>
EOF
  echo "Virtual host level cache root is set to /home/username/lscache."
fi

#apply changes to all virtual hosts
/scripts/ensure_vhost_includes --all-users

reset_cache_polity
}


set_cache_root_policy_plesk()
{
APACHECONFD=''

if [ -f '/etc/os-release' ] ; then
  OS=`grep ^ID= /etc/os-release | cut -d"=" -f2 | xargs`
elif [ -f '/etc/redhat-release' ] ; then
  CHECK=`grep -i centos /etc/redhat-release`
  if [ $? -eq 0 ] ; then
    OS='centos'
  fi
  CHECK=`grep -i cloudlinux /etc/redhat-release`
  if [ $? -eq 0 ] ; then
    OS='cloudlinux'
  fi
elif [ -f '/etc/lsb-release' ] ; then
  CHECK=`grep ^DISTRIB_ID= /etc/lsb-release | cut -d"=" -f2 | xargs`
  if [ "x$CHECK" = 'Ubunutu' ] ; then
    OS='ubuntu'
  fi
elif [ -f '/etc/debian_version' ] ; then
  OS='debian'
fi

if [ "x$OS" = "xcentos" ] || [ "x$OS" = "xcloudlinux" ] ; then
  APACHECONFD=/etc/httpd/conf.d
elif [ "x$OS" = "xubuntu" ] ; then
  APACHECONFD=/etc/apache2/conf-enabled
elif [ "x$OS" = "xdebian" ] ; then
  APACHECONFD=/etc/apache2/conf.d
else
  echo "This automation script does not support system other than CentOS/Ubuntu/Debian for Plesk."
  exit 1
fi

echo ""
echo "OS is $OS."
echo ""

#set server level cache root
if grep -q CacheRoot $APACHECONFD/*
then
  #If cache root has been set, delete it to avoid permission issue
  SCROOT=`grep CacheRoot $APACHECONFD/* | cut -d' ' -f2`
#  echo $SCROOT
  echo "Found server level cache root has already been set to: $SCROOT"
#  rm -rf $SCROOT
else
  cat >> $APACHECONFD/lscache.conf <<EOF
<IfModule Litespeed>
CacheRoot /var/www/vhosts/lscache/
</IfModule>
EOF
  echo "Server level cache root is set to /var/www/vhosts/lscache."
fi

  echo "List server root level cache root configuration files:"
  grep -R CacheRoot $APACHECONFD/*
  echo ""

#set virtual host level cache root


if grep -q CacheRoot /usr/local/psa/admin/conf/templates/custom/domain/domainVirtualHost.php
then
  VHCROOT=`grep CacheRoot /usr/local/psa/admin/conf/templates/custom/domain/domainVirtualHost.php | cut -d' ' -f2`
  echo "Found virtual host level cache root set to: /var/www/vhosts/<domain_name>/$VHCROOT"
  echo "List virtual host level cache root configuration files:"
  echo "/usr/local/psa/admin/conf/templates/custom/domain/domainVirtualHost.php"
  grep -R CacheRoot /usr/local/psa/admin/conf/templates/custom/domain/domainVirtualHost.php

else
  echo "Don't worry. We will create file for you."
  echo "/usr/local/psa/admin/conf/templates/custom/domain/domainVirtualHost.php has been created."
  echo ""
  mkdir -p /usr/local/psa/admin/conf/templates/custom/domain
  cp -p /usr/local/psa/admin/conf/templates/default/domain/domainVirtualHost.php /usr/local/psa/admin/conf/templates/custom/domain/domainVirtualHost.php

  sed -i.bak 's/<\/VirtualHost>/<IfModule Litespeed>\nCacheRoot lscache\n<\/IfModule>\n<\/VirtualHost>\n/g' /usr/local/psa/admin/conf/templates/custom/domain/domainVirtualHost.php
  echo "Virtual host level cache root is set to /var/www/vhosts/<domain_name>/lscache."
fi

#apply changes to all virtual hosts
/usr/local/psa/admin/bin/httpdmng --reconfigure-all

echo ""

reset_cache_polity

}

detect_control_panel()
{
    if [ -d "/usr/local/cpanel/whostmgr" ] ; then
	CP="WHM"
	CPCMD="/usr/local/cpanel/whostmgr/docroot/cgi/lsws/bin/lsws_cmd.sh"
	if [ -f "$CPCMD" ] ; then
	    echo "Detect cPanel WHM environment"
	else
	    check_errs 1 "cPanel environment detected, but LiteSpeed WHM plugin not installed."
	fi

    elif [ -e "/opt/psa/version" ] || [ -e "/usr/local/psa/version" ] ; then
	# detect Plesk
	CP="PSA"
	if [ -e "/usr/local/psa/version" ] ; then
	    PSA_BASE="/usr/local/psa"
	else
	    PSA_BASE="/opt/psa"
	fi

	CPCMD="$PSA_BASE/admin/sbin/modules/litespeed/lsws_cmd"
	if [ -f "$CPCMD" ] ; then
	    echo "Detect Plesk environment"
	else
	    check_errs 1 "Plesk environment detected, but LiteSpeed Plesk plugin not installed."
	fi
    else
	check_errs 1 "Cannot detect control panel environment. Only cPanel WHM and Plesk are checked for now."
    fi
}


if [ $# -ne 0 ] ; then
    echo "No parameters required!"
    display_usage
fi

detect_control_panel

if [ "$CP" = "WHM" ] ; then
  set_cache_root_policy_cpanel
elif [ "$CP" = "PSA" ] ; then
  set_cache_root_policy_plesk
else
  echo "There is no cPanel or Plesk detected. Exit the script."
  exit 1
fi

