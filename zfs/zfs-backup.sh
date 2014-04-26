#!/bin/bash

from="$1"
to="$2"

if [[ -z $1 || -z $2 ]] ; then
  echo "You have to specify from dataset and to directory in \$1 \$2"
  exit 2
fi

[[ ! -d $2 ]] && echo "Destination must be a directory" && exit 1

snapname="$from@backup-$(date +%s)"
mountpoint="var/tmp/$snapname"


zfs snapshot $snapname || echo "Unable to create backup snapshot" && exit 1
# we cant use zfs mount, so do it manually
mkdir -p "$mountpoint"
mount -t zfs "$snapname" "$mountpoint" || echo "Unable to mount snapshot" && exit 1

function on_exit() {
  umount "$mountpoint"
  zfs destroy "$snapname"
}
trap on_exit EXIT

rsync -azh --delete "$mountpoint" "$to"



