#!/bin/bash

# John Quaglieri
# john@interserver.net
# 6/5/2018

# clean up old split files from swift

# if defined don't use colors for swift commands
export COLORS=0;

# exclude today because backups might be running
exclude=$(date "+%Y-%m-%d");

# exit if config doesn't exist
if [ ! -f /root/.swift/config ]; then
	exit;
fi

if [ ! "$1" = "real" ]; then
	echo 'Running in test mode. Call as ./prune_swift.sh real to actually run this';
	sleep 2s;
fi

echo "Excluding ${exclude}";

# get all files
for dir in $(/admin/swift/isls); do
	# debug help
        echo "working on $dir";
	# list of extension here fly is old split in the latest
        for ext in fly split; do
		# list extensions
                for check in $(/admin/swift/isls $dir | grep "${ext}-" | sort | uniq | grep -v "${exclude}"); do
			# check should never be blank
			if [ "$check" = "" ]; then
				echo 'Returned a blank variable breaking loop';
				continue;
			fi
			# get the metadata file if this doesn't exist we get to delete the data
                        flycheck=$(echo $check | cut -d/ -f1);
			# check for it
                        if [ "$(/admin/swift/isls $dir | grep ${flycheck}$)" = "" ]; then
				# debug
                                echo "removing $check for $dir for extension $ext";
				# only remove if we call ./prune_swift.sh real
				if [ "$1" = "real" ]; then
					/admin/swift/isrm $dir $check
				fi
                        fi
                done
        done
	# add a return to output
        echo
done

