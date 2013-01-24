#!/bin/bash
# ghetto script to run commands on classes of boxes
# written Sept 11 2009

NTS='nts.wustl.edu'
WUSTL='wustl.edu'

SERVERS="all"
VERBOSE=0
COMMAND="uname -a"

SERVER_SPECIFIED=0
COMMAND_SPECIFIED=0
PRINT_SPECIFIED=0


# these get set to 1 if the server list is specified. (both -p and -s)
P_LINUX=0
P_MAC=0
P_SOLARIS=0

SOLARIS=( elliot.$NTS \
	aker.$NTS \
	loomis.$NTS \
	yitzhak.$NTS \
	kim.$NTS \
	ronj.$NTS \
	dialup.$NTS \
	directoryserver-1.$NTS \
	directoryserver-2.$NTS \
	flow.$WUSTL \
	ns1.$WUSTL \
	ns2.$WUSTL \
	$NTS \
	restech.$WUSTL \
	rts-dns.$WUSTL \
	smcpamela.$WUSTL \
	sugroups.$WUSTL \
	wugate.$WUSTL \
	weaver.$NTS \
	pats.$NTS \
	sherlock.$NTS \
	slic.$NTS \
	orwell.$NTS \
	syslog.$NTS \
	weiss.$WUSTL \
	nts-misc.$WUSTL \
	sysbak.$WUSTL \
	wubroadcast.$WUSTL \
	ldap-dev.$WUSTL \
	wright.$NTS \
	bleeke.$NTS \
	shawshank.$NTS \
	tribune.$NTS \
	windtalker.$NTS \	
)

MAC=(	streamer-1.$WUSTL \
	streamer-2.$WUSTL \
	eastwood.$NTS \
	woody.$NTS \
	tarantino.$NTS \
)

LINUX=( ns3.$NTS \
	ns4.$NTS \
	studentunion.$NTS \
	hosting1.$WUSTL \
	hosting2.$WUSTL \
)
#	irc.$NTS \

# defined

defined () {
	[[ ! -z "${1}" ]]
}

# debug

debug () {
	if [ $VERBOSE -eq 1 ] ; then
		printf ":: DEBUG :: $1\n"
	fi
}

# print servers

printservers () {
	if [ $P_LINUX -eq 1 ] ; then
		printf "===| LINUX servers |===\n"
		for val in ${LINUX[*]}
		do
			printf "\t$val\n"
		done
	fi
	if [ $P_SOLARIS -eq 1 ] ; then
		printf "===| SOLARIS servers |===\n"
		for val in ${SOLARIS[*]}
		do
			printf "\t$val\n"
		done
	fi
	if [ $P_MAC -eq 1 ] ; then
		printf "===| MAC servers |===\n"
		for val in ${MAC[*]}
		do
			printf "\t$val\n"
		done
	fi
}

# prompt user for another command to try to execute

promptcommand () {
	printf ":: ERROR :: $2 threw error $1\n"
	userinput=
	while [[ -z $userinput ]] ; do	
		printf "enter another command to execute, ctrl+c to break:> "
		read -e userinput
	done
	ssh $2 "$userinput" || promptcommand $? $2	
}

# usage function

usage () {
	printf "$0 usage:\n"
	printf "  -h				:	print this message\n"
	printf "  -v				:	turn on verbose mode\n"
	printf "  -p {mac|linux|solaris|all}	:	print the list of linux,mac, solaris servers, all all servers. assumes all if unspecified\n"
	printf "  -e \"command\"			:	execute \"command\" on the provided list of hosts, signaled by -s. if excluded, defaults to \"uname -a\"\n"
	printf "  -s {mac|linux|solaris|all}	:	signal which list of servers to perform the command on. -s assumes all if unspecified\n"
	printf "=====================\n"
	printf "NOTE: the use of -p and/or -h must be independant of -e/-s. -e/-s must be used together.\n"
}

# function to print out all hosts in $HOSTS

while getopts "hp:e:s:v" OPTION
do
	case $OPTION in
		h)			#heeeeeelpp!!!
			usage 
			exit 1 ;;
		s)			# switch on which servers we want to execute on
			SERVER_SPECIFIED=1
			case $OPTARG in
				solaris)
					SERVERS="$OPTARG"
					P_SOLARIS=1
					;;
				linux)
					SERVERS="$OPTARG"
					P_LINUX=1
					;;
				mac)
					SERVERS="$OPTARG"
					P_MAC=1
					;;
				all)
					SERVERS="$OPTARG"
					P_SOLARIS=1
					P_MAC=1
					P_LINUX=1
					;;
				*)
					printf ":: ERROR :: must specify -s {linux|mac|solaris|all}!!!!\n"
					exit 3 ;;
			esac
			debug "operating on:\n\tLINUX: $P_LINUX\n\tSOLARIS: $P_SOLARIS\n\tMAC: $P_MAC"
			;;
		p)			# print server list specified
			PRINT_SPECIFIED=1
			if [ $SERVER_SPECIFIED -eq 1 ] ; then 
				printf ":: ERROR :: cannot use -s/-e with -p! aborting...\n"
				exit 5
			fi
			case $OPTARG in
				solaris)
					SERVERS="$OPTARG" 
					P_SOLARIS=1
					;;
				linux)
					SERVERS="$OPTARG" 
					P_LINUX=1
					;;
				mac)
					SERVERS="$OPTARG"
					P_MAC=1
					;;
				all)
					SERVERS="$OPTARG"
					P_SOLARIS=1
					P_MAC=1
					P_LINUX=1
					;;
				*)
					printf ":: ERROR :: must specify -p {linux|mac|solaris|all}!!!!\n"
					exit 2 ;;
			esac
			debug "printing servers $SERVERS"
			;;
		e)			# command to execute
			COMMAND_SPECIFIED=1
			COMMAND="$OPTARG"
			debug "setting command to \"$COMMAND\"..."
			;;
		v)			# turn on verbose mode
			VERBOSE=1 
			debug "entering verbose mode..." ;;
		?)			# hjälpa mig gott im himmel!!!!
			usage
			exit 1	;;
		*)	
			usage
			exit 1 ;;
	esac
done

# error out if both -s and -p are specified
if [[ $PRINT_SPECIFIED -eq 1 && $SERVER_SPECIFIED -eq 1 ]] ; then 
	printf ":: ERROR :: cannot use -s/-e with -p! aborting...\n"
	exit 5
fi
# print servers if $PRINT_SPECIFIED
if [ $PRINT_SPECIFIED -eq 1 ] ; then
	printservers	#print the servers and exit
	exit 0
fi
# error if missing the -s flag now
if [ $SERVER_SPECIFIED -eq 0 ] ; then
	usage
	exit 4
fi

# now do the real work. if we are here, start logging in to boxes and executing the command
# do work on linux boxes
if [ $P_LINUX -eq 1 ] ; then
	debug "connecting to linux hosts..."
	for host in ${LINUX[*]}
	do
		debug "connecting to $host..."
		printf "$host says ->\t"
		ssh $host "$COMMAND" || promptcommand $? $host
		printf "\n"
	done
fi
# do work on solaris boxes
if [ $P_SOLARIS -eq 1 ] ; then
	debug "connecting to solaris hosts..."
	for host in ${SOLARIS[*]}
	do
		debug "connecting to $host..."
		printf "$host says ->\t"
		ssh $host "$COMMAND" || promptcommand $? $host
		printf "\n"
	done
fi
# do work on macs
if [ $P_MAC -eq 1 ] ; then
	debug "connecting to mac hosts..."
	for host in ${MAC[*]}
	do
		debug "connecting to $host..."
		printf "$host says ->\t"
		ssh $host "$COMMAND" || promptcommand $? $host
		printf "\n"
	done
fi









# get uname-a for host before executing?
