#!/bin/bash

#sanity checks everywhere
if [ ! "$username" = "" ]; then
        if [ -d /home ]; then
                cd /home
                if [ -d $username ]; then
                        mv $username $username.zfs
                        /usr/sbin/zfs create vz/$username
                        /usr/sbin/zfs set refquota=100G vz/$username
                        rsync -a $username.zfs/ /home/$username/
                        rm -rf $username.zfs
			/admin/storage/fixquota $username
                fi
        fi
fi

