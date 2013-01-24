#!/bin/bash
# scrapes cool images off the web
# written May 30 2009

medias=( tvshows games pictures music movies )
## first get listings of tvshows, movies, etc.

## now get the files

for media in ${medias[@]}
do
	cd $media.d/
	for name in `cat ../$media | awk '{print $5}'`
	do
		if [[ ! -e "$name" ]] ; then
			if [[ $DEBUG -eq 1 ]] ; then
				echo "i am in directory: `pwd`" ;
				echo "wget http://www.nekrosoft.net/aeon/bg_$media/$name"
			fi
			wget http://www.nekrosoft.net/aeon/bg_$media/$name 	
		fi
	done
	cd ..
done
