#!/bin/bash
# written Feb 18, 2010

dir="/var/flows/$1"

array=`find "$dir" -type d -mtime +32 -exec echo {} \;`

for a in ${array[@]} ; do 
	if [[ `ls -1 $a | wc -l` == '0' ]] ; then 
		echo "removing $a because it is empty and old..."
		rmdir $a 
	fi
done

