#!/bin/bash

if [ -x /tools/vztemplatesync.sh ]; then
	/tools/vztemplatesync.sh
else
	echo 'This is depreciated and /tools/vztemplatesync.sh is not found';
fi
