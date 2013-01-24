#!/bin/bash
# ghetto script to make up for DKMS not being invented yet (or at least me not knowing about it)
# written Nov 3 2009
# update modules after a kernel update
#                 _       _       
# _   _ _ __   __| | __ _| |_ ___ 
#| | | | '_ \ / _` |/ _` | __/ _ \
#| |_| | |_) | (_| | (_| | ||  __/
# \__,_| .__/ \__,_|\__,_|\__\___|
#      |_|                        
# _                        _ 
#| | _____ _ __ _ __   ___| |
#| |/ / _ \ '__| '_ \ / _ \ |
#|   <  __/ |  | | | |  __/ |
#|_|\_\___|_|  |_| |_|\___|_|
#                     _       _           
# _ __ ___   ___   __| |_   _| | ___  ___ 
#| '_ ` _ \ / _ \ / _` | | | | |/ _ \/ __|
#| | | | | | (_) | (_| | |_| | |  __/\__ \
#|_| |_| |_|\___/ \__,_|\__,_|_|\___||___/
#
#

#variables
err=0
arch=`uname -m`

#how do we find out if the script is being run with root privs?
uid=`id -u`
if [ ! $uid -eq 0 ] ; then
	# we want to rerun as root, or tell user to run with sudo
	echo "you are not running this script as root, please either:"
	echo "	hit ctrl-c, and re-run sudo $0"
	echo "	OR type in the root password below."
	exec su -c ${0} "$@"
	exit $?
else
	echo "Groovy, you are running as root."
fi
	

echo "Beginning to build required modules..."


#vbox 
#this binary is on arch
vbox_rebuild=/usr/bin/vbox_build_module
#on ubuntu it is a init.d script
vbox_init=/etc/init.d/vboxdrv

if [ -f $vbox_rebuild ] ; then
	echo "Detected virtualbox, rebuilding Vbox Kernel Modules (via binary)..."
	echo $vbox_rebuild
	vboxerr=$?
	if [ $vboxerr != 0 ] ; then
		echo "ERROR: building VBox Kernel Modules..."
		err=$vboxerr
	fi	
else 
	if [ -f $vbox_init ] ; then
		#this machine is most likely ubuntu, so we need to run the driver update
		echo "Detected virtualbox, Rebuilding Vbox Kernel Modules (via init script)..."
		echo $vbox_init setup
		vboxerr=$?
		if [ $vboxerr != 0 ] ; then
			echo "ERROR: building VBox Kernel Modules..."
			err=$vboxerr
		fi	
	fi	
fi

#vbox guest? guest additions
#where does the vbox update script live?
vboxarch=
vboxguest=/usr/bin/VBoxLinuxAdditions
case $arch in
	x86_64)
		vboxarch="x86_64"
		;;
	x86)
		vboxarch="x86"
		;;
	*)
		echo "ERROR: error detecting architecture type, got $arch."
		;;
esac	
if [ ! -z $vboxarch ] ; then
	echo "Detected $vboxarch architecture..."
fi

if [ -f $vboxguest$vboxarch.run ] ; then
	echo "Detected Virtual Box guest system, rebuilding Guest Additions..."
	echo $vboxguest$vboxarch.run
fi



echo ""
echo "Rebuilding modules complete. Please reboot now before expecting anything to work."

exit $err
#shouldnt get here
