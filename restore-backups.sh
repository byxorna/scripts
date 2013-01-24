#!/bin/bash
# restore backup cpanel accounts
# written June 2 2010
#                              _                                   _   
#   ___ _ __   __ _ _ __   ___| |   __ _  ___ ___ ___  _   _ _ __ | |_ 
#  / __| '_ \ / _` | '_ \ / _ \ |  / _` |/ __/ __/ _ \| | | | '_ \| __|
# | (__| |_) | (_| | | | |  __/ | | (_| | (_| (_| (_) | |_| | | | | |_ 
#  \___| .__/ \__,_|_| |_|\___|_|  \__,_|\___\___\___/ \__,_|_| |_|\__|
#      |_|                                                             
#                _                 
#  _ __ ___  ___| |_ ___  _ __ ___ 
# | '__/ _ \/ __| __/ _ \| '__/ _ \
# | | |  __/\__ \ || (_) | | |  __/
# |_|  \___||___/\__\___/|_|  \___|
#                                  
# 
# which packages to not transfer
ignoreaccounts=(nts ntsold)
# where the packages live
restoredir=/backup/cpbackup/daily
# which accounts to specifically restore
#restoreaccounts=(nso)
restoreaccounts=`ls $restoredir/*.tar.gz`
# which accounts to _not_ restore
dontrestoreaccounts=(nts ntsold)

# if restoreaccounts is created with the `ls *.tar.gz`, make the array just the names of the accounts
#echo ${restoreaccounts[@]}
i=0
for acct in ${restoreaccounts[@]} ; do
	if [[ "$acct" =~ "^$restoredir/(\w+).tar.gz" ]] ; then 
		#echo ${BASH_REMATCH[1]}
		restoreaccounts[$i]=${BASH_REMATCH[1]}
	fi
	let i++
done
#echo ${restoreaccounts[@]}
#echo ".........................................."

excludearg=""
for exc in ${ignoreaccounts[@]} ; do
	excludearg="--exclude=$restoredir/$exc.tar.gz $excludearg"
done
rsync -avzr $excludearg --delete -e 'ssh -i /etc/ssh/ssh_host_dsa_key -l root -c blowfish' stormy.nts.wustl.edu:$restoredir/ $restoredir/

for package in ${restoreaccounts[@]} ; do

	echo "processing $package..."
	# run the restore command on each tar.gz
	restore=true
	for x in ${dontrestoreaccounts[@]} ; do
		if [[ $x == $package ]] ; then
			# skip this package, it has been excluded
			echo " :: package $package excluded from restore due to exclusion"
			restore=false
		else
			#echo " :: excluded package $x does not match $package"
			sleep 0	# NOP
		fi
	done

	if [[ $restore == true ]] ; then
		/scripts/restorepkg --force $restoredir/$package.tar.gz
	fi
	
done
