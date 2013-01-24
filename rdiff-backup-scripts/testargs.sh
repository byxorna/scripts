#!/bin/bash

if [[ $# > 0 ]] ; then
echo there are arguments present
echo there are $# args passed
for arg in "$@" ; do
	echo $arg
done
echo -----------------
while [ "$1" ] ; do
echo "$1" found in arg list
shift
done
else
echo there are no args present
fi
