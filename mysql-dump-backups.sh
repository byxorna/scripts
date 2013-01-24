#!/bin/bash
# script to dump mysql DBs
# written Apr 29 2010
#     _                                                   _ 
#  __| |_   _ _ __ ___  _ __    _ __ ___  _   _ ___  __ _| |
# / _` | | | | '_ ` _ \| '_ \  | '_ ` _ \| | | / __|/ _` | |
#| (_| | |_| | | | | | | |_) | | | | | | | |_| \__ \ (_| | |
# \__,_|\__,_|_| |_| |_| .__/  |_| |_| |_|\__, |___/\__, |_|
#                      |_|                |___/        |_|  
#     _       _        _                         
#  __| | __ _| |_ __ _| |__   __ _ ___  ___  ___ 
# / _` |/ _` | __/ _` | '_ \ / _` / __|/ _ \/ __|
#| (_| | (_| | || (_| | |_) | (_| \__ \  __/\__ \
# \__,_|\__,_|\__\__,_|_.__/ \__,_|___/\___||___/
#                                                
#

# careful what password you put here, as special sequences will break the script, like !! or so on
password='CHANGEME'
if [ -z "$password" ] ; then
        echo "No password given..."
        pwline=""
else
        pwline="--password=$password "
fi

user='root'
userline="--user=$user"

backupdir=/var/mysql-backup
if [ ! -d "$backupdir" ] ; then
# perform the dump here
  echo "INFO: $backupdir doesnt exist, creating..."
  /bin/mkdir "$backupdir"
fi

mysqldump=`which mysqldump`
if [ $? != 0 ] ; then
  echo "ERROR: no mysqldump found in $PATH, aborting..."
  exit 1
fi

date=`which date`
if [ $? != 0 ] ; then
  echo "ERROR: no date found in $PATH, aborting..."
  exit 1
fi
currentdate=`$date '+%Y-%m-%d-%H:%M:%S'`

mailx=`which mailx`
if [ $? != 0 ] ; then
  echo "ERROR: no mailx found in $PATH, aborting..."
  exit 1
fi


backupfile="`hostname`-mysql-$currentdate.sql"

# perform the dump here
$mysqldump --user=$user --password=$password --all-databases > "$backupdir/$backupfile"

if [ "$?" -eq 0 ]; then
  echo "MySQL backup on `hostname` was successful" | $mailx -s "[MYSQL:SUCCESS] backup on `hostname`" unixadmins@list.wustl.edu
else
  echo "MySQL backup on `hostname` FAILED" | $mailx -s "[MYSQL:FAILED] backup on `hostname`" unixadmins@list.wustl.edu
fi

/bin/chmod 600 "$backupdir/$backupfile"

`which find` "$backupdir/" -name '*.sql' -type f -mtime +10 -exec rm {} \;

