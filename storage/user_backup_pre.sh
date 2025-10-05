#!/bin/sh
MAXTRIES=20
MAXLOAD=20.00

# skip for reseller or admin
U=`echo $file | cut -d/ -f3`
if [ "$U" != "$username" ]; then
   #file is not in our /home, so is Reseller or Admin backup.
   exit 0;
fi

highload()
{
          LOAD=`cat /proc/loadavg | cut -d\  -f1`
          echo "$LOAD > $MAXLOAD" | bc
}

TRIES=0
while [ `highload` -eq 1 ];
do
          sleep 5;
          if [ "$TRIES" -ge "$MAXTRIES" ]; then
                    echo "system load above $MAXLOAD for $MAXTRIES attempts. Aborting.";
                    exit 1;
          fi
          ((TRIES++))
done;
exit 0;

