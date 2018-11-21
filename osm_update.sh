#!/bin/bash
# script to pull openstreetmap updates and integrate into database
# version 0.1 simon@ateb.co.uk 2017-08-10
# version 0.2 simonannetts@esdm.co.uk 2018-11-06

exec > >(awk '{print strftime("%Y-%m-%d %H:%M:%S [1] "),$0; fflush();}')
exec 2> >(awk '{print strftime("%Y-%m-%d %H:%M:%S [2] "),$0; fflush();}' >&2)

starttime=$(date +%s)

baseUrl="http://download.geofabrik.de/"
baseDir=~/osm-data/

# get a list of the datasets we need to update based on the directories present
datasets=$(find -mindepth 2 -maxdepth 2 -type d | grep -v ".git" | awk 'BEGIN{FS="/"}{printf $2 "/" $3 " "}')

for dataset in $datasets; do

        cd ${baseDir}${dataset}

	# the update url
	url="${baseUrl}${dataset}-updates/"
	echo "Downloading ${url}state.txt to update-state.txt..."

	rm -f update-state.txt 2>/dev/null
	wget -O update-state.txt "${url}state.txt"

	if [ ! -f update-state.txt ]; then
		echo "Could not find Map Updates at URL $url. Please check the update location exists!"
		exit 1
	fi
	
	state=$(cat update-state.txt |awk 'BEGIN{FS="="}/timestamp/{printf $2}' |sed -e 's@\\@@g')

	if [ -z "$state" ]; then
		echo "Could not read timestamp from update-state.txt!"
		exit 1
	fi

	echo "$(d) Found update-state.txt with timestamp $state"

	# now check last state.txt file
	if [ ! -f "state.txt" ]; then
		region=$(echo $dataset|awk 'BEGIN{FS="/"}{printf $2}')
		echo "Could not find state.txt in ${baseDir}${dataset}... checking timestamp of the file ${region}-latest.osm.pbf ..."
		lastupdate=$(osmconvert --out-timestamp ${region}-latest.osm.pbf)
	else
		echo "Getting last update timestamp from state.txt ..."
		lastupdate=$(cat state.txt |awk 'BEGIN{FS="="}/timestamp/{printf $2}' |sed -e 's@\\@@g')
	fi
	
	[ -z "${lastupdate}" ] && echo "Could not determine the last update time for dataset ${dataset}!" && exit 1

	echo "Last Update timestamp was ${lastupdate}"
	
	if [ "${state}" != "${lastupdate}" ]; then

		rm -f updates.osc.gz 2>/dev/null

		echo "Last Update was ${lastupdate}. Downloading updates from ${url} ..."
		osmupdate -v --sporadic --base-url=${url} ${lastupdate} updates.osc.gz
	
		if [ $? = 0 ]; then
			newlastupdate=$(osmconvert --out-timestamp updates.osc.gz)
			[ ! -f "update.osc.gz.${newlastupdate}" ] && cp -f updates.osc.gz updates.osc.gz.${newlastupdate} 2>/dev/null
		else
			echo "osmupdate failed to download and merge the updates for ${dataset}. Please investigate or try again!"
			exit 1
		fi

		if [ -f updates.osc.gz ]; then
	
			rm -f expire.list 2>/dev/null
		
			osm2pgsql --append --slim -G --hstore -C 8000 --number-processes 8 \
          		--style ~/openstreetmap-carto/openstreetmap-carto.style --tag-transform-script ~/openstreetmap-carto/openstreetmap-carto.lua \
          		-d gis updates.osc.gz --e 11-18 -o expire.list

			if [ $? = 0 ]; then
				[ ! -f "expire.list.${newlastupdate}" ] && cp expire.list expire.list.${newlastupdate} 2>/dev/null
			else 
				echo "osm2pgsql failed to update the database for ${dataset}. Please investigate or try again!"
				exit 1
			fi
		
			cp -f update-state.txt state.txt

		else
			echo "No updates to apply for dataset ${dataset}!"
			exit 1
		fi
	else
		echo "No updates to apply for dataset ${dataset}!"
		exit 0
	fi
done
endtime=$(date +%s)
echo "Done in $[${endtime}-${starttime}] seconds! All your Maps Belong to Us!"
exit 0
