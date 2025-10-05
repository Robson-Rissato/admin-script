#!/usr/bin/env bash

if [ -d /usr/local/jetapps ]; then
	if [ -x /admin/storage/fixroundcube ]; then
		/admin/storage/fixroundcube
	fi
fi
