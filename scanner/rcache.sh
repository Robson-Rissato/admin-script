#!/bin/bash

if [ ! -d /root/tmp ]; then
        mkdir /root/tmp
fi

if [ ! -d /usr/local/cpanel ]; then
        echo 'For cpanel servers only';
        exit;
fi

if [ ! -e /etc/redhat-release ]; then
        echo 'For rhel based servers only';
        exit;
fi

if [ ! -e /usr/local/lsws/ ]; then
        echo 'For litespeed servers only';
        exit;
fi

cd /root/tmp
DLNAME=realpath_turbo-master-2.0.0.tgz;

wget http://mirror.trouble-free.net/sources/realpath_turbo/${DLNAME}
tar -zxvf ${DLNAME}

if [ ! -d realpath_turbo-master ]; then
        echo 'Download did not extract';
        /bin/rm -v ${DLNAME}
        exit;
fi

for phpver in $(ls /opt/cpanel | grep ea-php | egrep -v "ea-php51|ea-php52|ea-php53"); do
        cd /root/tmp
        echo "Working on $phpver";
        if [ ! -f /opt/cpanel/$phpver/root/usr/lib64/php/modules/realpath_turbo.so ]; then
                if [ ! -e /opt/cpanel/$phpver/root/usr/bin/phpize ]; then
                        echo 'Missing php devel';
                        continue;
                fi

                if [ ! -e /opt/cpanel/$phpver/root/usr/bin/php-config ]; then
                        echo 'Missing php config';
                        continue;
                fi

                cd realpath_turbo-master
                make clean
                /opt/cpanel/$phpver/root/usr/bin/phpize
                ./configure --with-php-config=/opt/cpanel/$phpver/root/usr/bin/php-config
                make
                make install

                cat > /opt/cpanel/$phpver/root/etc/php.d/realpath_turbo.ini <<EOF
; you have to load the extension first
extension=realpath_turbo.so

; Disable dangerous functions (see the warning in the README file for
; details).
; Possible values:
;   0 - Ignore potential security issues
;   1 - Disable dangerous PHP functions (link,symlink)
realpath_turbo.disable_dangerous_functions = 1
; cagefs and symlink protections take care of other security issues
EOF
        else
                echo "No need to update $phpver";
        fi

done

cagefsctl --force-update

cd /root/tmp
/bin/rm -v ${DLNAME}
/bin/rm -rf realpath_turbo-master

