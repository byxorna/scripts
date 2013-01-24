#!/bin/bash
# sample init script, for templating
# written Aug 4 2009
#
#       /etc/rc.d/init.d/

# Source function library.
SCRIPTNAME='test_wireless.pl'
. /lib/lsb/init-functions
PIDFILE="/var/run/$SCRIPTNAME"
LOGFILE="/var/log/test_wireless"

start() {
	if [ -f "$PIDFILE" ] ; then
		PID=`/bin/cat $PIDFILE`	
		if [[ $PID && `/bin/ps -ef | /bin/grep $PID | /bin/grep -v grep` ]] ; then
			echo "$SCRIPTNAME is already running: $PID"
			exit 2;
		else
			start
		fi
	else
		echo "Starting $SCRIPTNAME"
# create the PIDFILE now
		if [[ -e "$PIDFILE" && -f "$PIDFILE" && -w "$PIDFILE" && -r "$PIDFILE" ]]; then
			true
		else
			touch "$PIDFILE"
			chmod 644 "$PIDFILE" 
		fi
# daemonize the script
		/home/noc/$SCRIPTNAME &
		testpid=$$
		echo $$
# check if the script started sucessfully
		if [ $? -eq 0 ] ; then
			PID=`/bin/ps -ef | /bin/grep "$SCRIPTNAME" | /bin/grep -v grep | /usr/bin/awk '{print $2}'`
			echo $PID > $PIDFILE 
		else 
			echo "something bad happened starting $SCRIPTNAME"
			rm -f "$PIDFILE"
			return 3
		fi
	fi
        return
}

status() {
	if [ -f "$PIDFILE" ] ; then
		PID=`/bin/cat $PIDFILE`
		if [ -z $PID ] ; then
			echo "$SCRIPTNAME not running"
			rm -f "$PIDFILE"
			return
		else
			echo "$SCRIPTNAME is running with PID $PID"
			return
		fi
	else
		echo "$SCRIPTNAME is not running"
		return
	fi
}
stop() {
        echo "Shutting down $SCRIPTNAME"
	if [[ -f "$PIDFILE" && -r "$PIDFILE" ]] ; then
		PID=`/bin/cat "$PIDFILE"`
		kill $PID
		rm -f "$PIDFILE"
	else
		echo "$SCRIPTNAME wasnt running!"
	fi
        return
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
	status	
        ;;
    restart)
        stop
        start
        ;;
    *)
        echo "Usage:  {start|stop|status|restart"
        exit 1
        ;;
esac
exit $?

