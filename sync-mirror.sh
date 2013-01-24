#!/bin/bash
# written Feb 5 2010
# deps: tee, rsync
# TODO
# check that logfile exists, is writable
# check for binary deps
# write a config parser in perl http://inthebox.webmin.com/one-config-file-to-rule-them-all

#TODO TODO TODO make the sync run in 2 parts: first, sync all packages, then sync the index files


PATH='/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin'
# -- email settings -- #

notification_email=gummybearx@gmail.com
email_on_sync=true        # false=no email, true=email changes and status on every sync

# -- log file settings -- #

logfile=/var/log/mirrorsync.log
debug=true
logging=false

# -- server settings -- #

#parsed via argument to sync command
remoteprotocol=
remoteurl=          # read in from argument
remotepath=
localurl=/mirror/testing

max_failures=2          # number of sync failures before dying
failures=0
status=1
complete=false
sync=false

# TODO is there a different way that will work around shitty solaris returning 0 from which, even if the binary doesnt exist??
rsync_bin=`which rsync` || ( echo "rsync binary not found, exiting!!!" && exit 127 )


#source $config




DEBUG() {
  if [[ $debug == "true" ]] ; then
    date=`date +%Y-%m-%d-%R`
    if [[ $logging == "true" ]] ; then
      echo "$date DEBUG: $1" | tee -a $logfile
    else
      echo "$date DEBUG: $1"
    fi
  fi
}
WARN() {
  if [[ $debug == "true" ]] ; then
    date=`date +%Y-%m-%d-%R`
    if [[ $logging == "true" ]] ; then
      echo "$date WARN: $1" | tee -a $logfile
    else
      echo "$date WARN: $1"
    fi
  fi
}
inform() {
  date=`date +%Y-%m-%d-%R`
  if [[ $logging == "true" ]] ; then
    echo "$date INFO: $1" | tee -a $logfile
  else
    echo "$date INFO: $1"
  fi
}

validate_url () {
  temp=$1      # rsync://host.com/dir/tmp
  protocol=`echo $temp | awk -F"://" '{print $1}'`
  temp=`echo $temp | awk -F"://" '{print $2}'`
  # if temp is empty, then protocol should be http (default)
  if [[ -z $temp ]] ; then
    temp=$protocol
    protocol='http'
  fi
  url=`echo $temp | awk -F"/" '{print $1}'`
  path=/${temp#*/}
  # TODO this is broken if no / given after url

  # check all 3 are valid, then set remoteurl and type and path
  remoteprotocol=$protocol
  remoteurl=$url
  remotepath=$path
  if [[ "$protocol" != "http" && "$protocol" != "rsync" && "$protocol" != "ftp" ]] ; then
    status=120  # illegal protocol
    WARN "[$protocol] is not a supported protocol"
  fi
}

usage () {
  echo "$0 usage:"
  echo "$0 [show|sync] protocol://host.domain.com/dir/ect/ory"
}

# -- handle commands --
case $1 in
#debug)  debug=true
show)  sync=false
  validate_url $2
  inform "logfile:    $logfile"
  inform "remoteprotocol:    $remoteprotocol"
  inform "remoteurl:    $remoteurl"
  inform "remotepath:    $remotepath"
  inform "local sync dir:    $localurl"
  inform "max retries:    $max_failures"
  inform "rsync binary:    $rsync_bin"
  inform "debugging:    $debug"
  inform "notification email:  $notification_email"
  inform "send email:    $email_on_sync"
  inform "status:      $status"
  if [[ $status -ne 0 ]] ; then 
    status=0
  fi
  ;;
sync)  sync=true
  validate_url $2
  ;;
help)  sync=false
  usage
  status=0
  ;;
*)  inform "unknown command [$1], aborting"
  usage
  status=127
  ;;
esac

if [ $status -ne 0 ] ; then
  DEBUG "error $status encountered"
  exit $status
fi

if [[ $sync == "true" ]] ; then

  inform "syncing..."
  # TODO implement


else
  inform "nothing to do..."
fi

exit $status

