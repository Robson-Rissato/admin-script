#!/bin/bash

if [ -e /usr/bin/virsh ]; then
	virsh list | grep running$ | awk '{print $2}'
else
	echo 'virsh not found at /usr/bin/virsh';
fi
