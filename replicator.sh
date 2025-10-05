#!/bin/bash
# - by detain@interserver.net

function help_sql() {
        echo ""
        echo "SQL Replicator - by detain@interserver.net"
        echo ""
        echo "This will test and resync a MySQL Mater/Slave setup if there are any problems."
        echo "The script is meant to be run from the Master SQL server."
        echo ""
        echo "                  Current Settings:"
        echo "          MySQL Master IP         $master"
        echo "          MySQL Slave IP          $slave"
        echo "          MySQL Username          $user"
        echo "          MySQL Password          $password"
        echo ""
        echo "Syntax: $0 <help|config|setup|grants|check|crontab> [debug]"
        echo ""
        echo "  <help>          This Page"
        echo "  <config>        Re-Configures the Database and server settings like setting"
        echo "                  Master and Slave IP Addresses, MySQL Username and Password."
        echo "  <setup>         Takes care of the initial setup of a MySQL Mater/Slave setup,"
        echo "                  including mysql.cnf adjustments, grants, syncing of the database,"
        echo "                  starting the replication, and making sure it started right"
        echo "  <grants>        Sets up grants between the Master and Slave MySQL servers, not"
        echo "                  really needed."
        echo "  <check>         Checks the Master/Slave servers to make sure they are running"
        echo "                  and currently syncd up.  If there are any issues, it will"
        echo "                  automatically try to fix them."
        echo "  <crontab>       Installs the script in crontab to automatically keep the servers"
        echo "                  Sync'd Up."
        echo "  [debug]         Optional argument to show more output and the specific"
        echo "                  commands that are being run on the servers."
        echo ""
}

function load_sql() {
        if [ ! -e ~/.replicator ]; then
                help_sql
                config_sql
        else
                . ~/.replicator
        fi
}

function test_sql() {
        if [ ! "$(echo "select 1;" | mysql -s -h $slave -u $user --password=$password)" = "1" ]; then
                echo -e "SQL Connection Problem, Call Again With:\n     $0 config"
                config_sql
        fi
}

function config_sql() {
        read -p "Master SQL IP [$master]:" tmaster
        if [ "$tmaster" = "" ]; then
                tmaster=$master;
        fi
        read -p "Slave SQL IP [$slave]:" tslave
        if [ "$tslave" = "" ]; then
                tslave=$slave;
        fi
        read -p "SQL Username [$user]:" tuser
        if [ "$tuser" = "" ]; then
                tuser=$user;
        fi
        read -p "SQL Password [$password]:" tpassword
        if [ "$tpassword" = "" ]; then
                tpassword=$password;
        fi
        echo "export master=$tmaster
export slave=$tslave
export user=$tuser
export password=$tpassword
" > ~/.replicator
        . ~/.replicator
}

function check_sql() {
        slaveio="$(echo "show slave status\G" | mysql -h $slave -u $user --password=$password | grep Slave_IO_Running | awk '{ print $2 }')"
        slavesql="$(echo "show slave status\G" | mysql -h $slave -u $user --password=$password | grep Slave_SQL_Running | awk '{ print $2 }')"
        if [ ! "$slaveio" = "Yes" ] || [ ! "$slavesql" = "Yes" ]; then
                echo -n "Out Of Sync, Fixing..."
                echo -n Locking...
                echo "FLUSH TABLES WITH READ LOCK;" | mysql
                echo -n "Getting Current BinLog File And Position..."
                file="$(mysql -Bse "show master status\G"| grep File | awk '{ print $2 }')"
                pos="$(mysql -Bse "show master status\G"| grep Position | awk '{ print $2 }')"
                echo -n "Got File $file Pos $pos..."
                echo -n "Unlocking Tables..."
                echo "UNLOCK TABLES;" | mysql
                echo -n "Stopping Slave..."
                echo "stop slave;" | mysql -h $slave -u $user --password=$password
                echo -n "Setting Slave To Correct Log File And Position..."
                echo "CHANGE MASTER TO MASTER_LOG_FILE=\"$file\",MASTER_LOG_POS=$pos;" | mysql -h $slave -u $user --password=$password
                echo -n "Restarting Slave Process..."
                echo "START SLAVE;" | mysql  -h $slave -u $user --password=$password
                slaveio="$(echo "show slave status\G" | mysql -h $slave -u $user --password=$password | grep Slave_IO_Running | awk '{ print $2 }')"
                slavesql="$(echo "show slave status\G" | mysql -h $slave -u $user --password=$password | grep Slave_SQL_Running | awk '{ print $2 }')"
                if [ ! "$slaveio" = "Yes" ] || [ ! "$slavesql" = "Yes" ]; then
                        echo "There are still problems"
                else
                        echo "Everything FIXED And Tested GOOD"
                fi
#       else
#               echo "All Good, Ending"
        fi
}

function crontab_sql() {
        echo "Setting Up Crontab To Run"
        script="$PWD$(basename "$0")"
        crontab -l | grep -v "$script" > /tmp/crontab.tmp
        read -p "How Many Minutes Between Checks? [15]:" checktime
        if [ "$checktime" = "" ]; then
                checktime=15
        fi
        echo "*/$checktime * * * * $script check" >>  /tmp/crontab.tmp
        crontab /tmp/crontab.tmp
        rm -f /tmp/crontab.tmp
        echo "Done, Your Replication Will Now Be Tested And Fixed As Needed Every $checktime Minutes"
}

function setup_sql() {
        echo "Setting Up MySQL Master Config File"
        echo "[mysqld]
log-bin
server-id=1
" >> /etc/my.cnf
        echo "Setting Up MySQL Slave Config File"
        echo "echo \"[mysqld]
[mysqld]
server-id=2
master-host = $master
master-user = $user
master-password = $password
master-port = 3306
\" >> /etc/my.cnf;" | ssh root@$slave
        echo "Stopping MySQL Server On Master"
        /etc/init.d/mysqld stop
        echo "Stopping MySQL Server On Slave"
        echo "/etc/init.d/mysqld stop;" | ssh root$slave
        echo "Removing Old Bin Log Files"
        rm -f /var/lib/mysql/mysqld-bin.*
        echo "Syncing Data From Master To Slave"
        cd /var/lib/mysql/
        rsync -ae ssh --delete . root@$slave:/var/lib/mysql/
        echo "Restarting MySQL On Master"
        /etc/init.d/mysqld restart
        echo "Restarting MySQL On Slave"
        echo "/etc/init.d/mysqld restart;" | ssh root$slave
        grants_sql
        echo "Starting Slave SQL Process..."
        echo "echo 'start slave;' | mysql;" | ssh root@$slave;
}

function grants_sql() {
        echo "Setting Up Grants For Slave On Master"
        echo 'grant replication slave on *.* to \"repl\"@\"$slave\" identified by \"$password\";' | mysql
        mysqladmin flush-privileges;
        echo "Setting Up Grants For Master On Slave"
        echo "echo 'grant all on *.* to \"repl\"@\"$master\" identified by \"$password\";' | mysql;" |  ssh root@$slave
        echo "echo 'grant replication slave on *.* to \"repl\"@\"$master\" identified by \"$password\";' | mysql;" |  ssh root@$slave
        echo "mysqladmin flush-privileges;" | ssh root@$slave;
}

if [ "$2" = "debug" ]; then
        echo "Debugging Enabled"
        set -x
fi

load_sql
test_sql

if [ "$1" = "config" ]; then
        config_sql
elif [ "$1" = "setup" ]; then
        setup_sql
        check_sql
elif [ "$1" = "grants" ]; then
        grants_sql
elif [ "$1" = "crontab" ]; then
        crontab_sql
elif [ "$1" = "check" ]; then
        check_sql
elif [ "$1" = "help" ]; then
        help_sql
else
        help_sql
fi


