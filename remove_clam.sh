#!/bin/sh

if [ ! "$1" = "run" ]; then
	exit;
fi

files_bin='clamav-config clambc clamconf clamdscan clamdtop clamscan freshclam';
files_sbin='clamd';
files_etc='clamd.conf freshclam.conf';
files_lib='libclamav.la libclamav.so libclamav.so.6 libclamav.so.6.1.2 libclamunrar_iface.la libclamunrar_iface.so libclamunrar_iface.so.6 libclamunrar_iface.so.6.1.2 libclamunrar.la libclamunrar.so libclamunrar.so.6 libclamunrar.so.6.1.2';

for file_bin in $files_bin; do
	if [ -f /usr/local/bin/$file_bin ]; then
		/bin/rm -v /usr/local/bin/$file_bin
	fi
done

for file_sbin in $files_sbin; do
        if [ -f /usr/local/sbin/$file_sbin ]; then
                /bin/rm -v /usr/local/sbin/$file_sbin
        fi
done

for file_etc in $files_etc; do
        if [ -f /usr/local/etc/$file_etc ]; then
                /bin/rm -v /usr/local/etc/$file_etc
        fi
done


for file_lib in $files_lib; do
        if [ -f /usr/local/lib/$file_lib ]; then
                /bin/rm -v /usr/local/lib/$file_lib
        fi
done



