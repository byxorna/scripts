#!/bin/bash
## this script backs up directories with the rsync script
## it will backup all arguments to a -d directory, optionally on -s server over ssh
# written May 10  2009


RSYNC_COMMAND=`which rsync`
SSH_COMMAND=`which ssh`
VERBOSE=0
BACKUPDIR=
SERVER=
PASSWORD=
USER=
REMOTE=
#declare array DIRS to have every dir to backup
declare -a DIRS

# print usage message
usage () {
  printf "\n"
  printf "usage: $0 options\n"
  printf "\n"
  printf "This script runs rsync to synchronize some directories with a specific location\n"

  printf "OPTIONS:\n"
  printf "  -h\t\t\tPrint help\n"
  printf "  -d /directory\t\twhat directory to sync to (i.e. /backup)\n"
  printf "  -v\t\t\tVerbose mode\n"
  printf "  -s server\t\tServer name to use (remote backup)\n"
  printf "  -u user\t\tUsername to use (remote backup) defaults to your invoking user name\n"
  printf "  -p password\t\tPassword to use (remote backup) UNSECURE! setup ssh keys instead\n"

}

# performs the local backup
backuplocal () {
	if [ $VERBOSE -eq 1 ] ; then 
		printf ":: (INFO) performing local backup on files/dirs:\n"
	fi

	for arg in ${DIRS[*]} 
	do
		if [ $VERBOSE -eq 1 ] ; then
			printf ":: (INFO)\tbacking up %s\n" $arg
		fi
		$RSYNC_COMMAND -avhz --delete --rsh=$SSH_COMMAND $arg $BACKUPDIR
	done
}

# performs the remote backup
backupremote () {

	if [ $VERBOSE -eq 1 ] ; then 
		printf ":: (INFO) performing remote backup to $USER@$SERVER:$BACKUPDIR\n"

	fi
printf "${DIRS[*]}\n"
	for arg in ${DIRS[*]} 
	do
		if [ $VERBOSE -eq 1 ] ; then
			printf ":: (INFO)\tbacking up %s\n" $arg
		fi
		printf "$RSYNC_COMMAND -avhz --delete --rsh=$SSH_COMMAND -e \"$SSH_COMMAND -l $USER\" %s $USER@$SERVER:$BACKUPDIR\n" $arg
	done
	#printf "ERROR: FIXME remotebackup\n"
	#exit 3;
}


## parse arguments
while getopts "hd:vu:s:p:" OPTION
do
	case $OPTION in
		h)
			usage
			exit 1 ;;
		v)
			VERBOSE=1 ;;
		d)
			BACKUPDIR=$OPTARG ;;
		u)
			USER=$OPTARG ;;
		p)
			PASSWORD=$OPTARG ;;
		s)
			SERVER=$OPTARG ;;
		?)	
			usage
			exit 1 ;;
	esac
done

# shift arguments past options, so args are at 1st position
shift $(($OPTIND - 1)) 

# check username, or set to default
if [ "$USER" == '' ] ; then
	USER=`whoami`
fi

if [ "$BACKUPDIR" == '' ] ; then
	printf "ERROR: you must specify a backup directory\n"
	exit 4;
fi
if [ "$SERVER" == '' ] ; then
	REMOTE=0
else 
	REMOTE=1
fi

# check if directory is valid
if [ $REMOTE -eq 0 ] ; then
	if [ -d $BACKUPDIR ] && [ -w $BACKUPDIR ] ; then 
		if [ $VERBOSE -eq 1 ] ; then
			printf ":: (INFO) backup directory exists and is writable\n"
		fi
	else 
		printf "$BACKUPDIR is NOT a directory, or it is not writable, exiting...\n"
		exit 2;
	fi
fi

n=0
# make $DIRS be the list of directories to backup
for arg in $@
do	## populate $DIRS with the leftover arguments
	if [ -r $arg ] && [ -d $arg ] || [ -f $arg ] && [ -r $arg ] ; then
		DIRS[$n]=$arg
		n=$(($n+1))
	else 
		printf "ERROR: backup argument $arg is unreadable\n"
		exit 5;
	fi
done


## now start the backup process
if [ $REMOTE -eq 0 ] ; then
	backuplocal
## TODO: implement remote functionality
else
	backupremote
fi



