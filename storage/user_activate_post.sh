#!/bin/sh

# allow user line must have sshd restart

if [ ! "$username" = "" ]; then
        systemctl stop sshd; systemctl start sshd
fi

