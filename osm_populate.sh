#!/bin/bash
# script to pull openstreetmap regions and push into database
# version 0.2 simonannetts@esdm.co.uk 2018-11-06

exec > >(awk '{print strftime("%Y-%m-%d %H:%M:%S [1] "),$0; fflush();}')
exec 2> >(awk '{print strftime("%Y-%m-%d %H:%M:%S [2] "),$0; fflush();}' >&2)

starttime=$(date +%s)

# OpenStreeMap and OpenTopoMap
osm=0
otm=0

[ "$1" = "--osm" ] || [ "$2" = "--osm" ] && osm=1
[ "$1" = "--otm" ] || [ "$2" = "--otm" ] && otm=1

[ $osm = 0 ] && [ $otm = 0 ] && echo "You must specify options --osm and/or --otm" && exit 1


baseUrl="http://download.geofabrik.de/"
baseDir=~/osm-data/
cartoDir=~/openstreetmap-carto/
topoDir=~/OpenTopoMap/

touch -d "1970-01-01T00:00:00Z" /var/lib/mod_tile/planet_import_complete

# get a list of the datasets we need to grab based on the directories present
datasets=$(find -mindepth 2 -maxdepth 2 -type d | awk 'BEGIN{FS="/"}{printf $2 "/" $3 " "}')
o5mfiles=$(find -mindepth 2 -maxdepth 2 -type d | awk 'BEGIN{FS="/"}{printf $2 "/" $3 "/" $3 "-latest.o5m "}')

for dataset in $datasets; do

	# the download url
	region=$(echo $dataset|awk 'BEGIN{FS="/"}{printf $2}')
	url="${baseUrl}${dataset}-latest.osm.pbf"
	echo "Downloading ${url} ..."
	
	mkdir -p ${baseDir}${dataset} 2>/dev/null
	cd ${baseDir}${dataset}
	
	wget -o /dev/null -O ${region}-latest-new.osm.pbf "${url}"
		
	if [ $? = 0 ]; then
		if [ -f  ${region}-latest-new.osm.pbf ]; then
			rm -f ${region}-latest.osm.pbf 2>/dev/null
			mv -f ${region}-latest-new.osm.pbf ${region}-latest.osm.pbf
		fi	
		lastupdate=$(osmconvert --out-timestamp ${region}-latest.osm.pbf)
		echo "timestamp=${lastupdate}" >state.txt
		echo "Region last updated: ${lastupdate}"
		osmconvert -v ${region}-latest.osm.pbf --drop-author --out-o5m -o=${region}-latest.o5m
	else
		echo "Could not download ${url}!"
		exit 1
	fi

done

cd ${baseDir}

echo "Combining the datasets..."
osmconvert -v ${o5mfiles} --out-pbf --timestamp=${lastupdate} -o=combined.osm.pbf
rm -f ${o5mfiles}

echo "Gathering statistics on the combined dataset..."
osmconvert --out-statistics combined.osm.pbf >statistics.txt

r1=0
r2=0

if [ "$osm" = "1" ]; then
	echo "Importing the combined dataset into Postgresql using OpenStreetMap style..."
	osm2pgsql -c --slim -G --hstore -C 9000 --number-processes 8  \
	 --style ${cartoDir}openstreetmap-carto.style --tag-transform-script ${cartoDir}openstreetmap-carto.lua \
	 -d gis combined.osm.pbf
	r1=$?
fi
if [ "$otm" = "1" ]; then
	echo "Importing the combined dataset into Postgresql using OpenTopoMap style..."
	osm2pgsql -c --slim -G --hstore -C 9000 --number-processes 8 \
	 --style ${topoDir}/mapnik/osm2pgsql/opentopomap.style \
	 -d otm combined.osm.pbf
	r2=$?
fi



if [ "$r1" = "0" ] && [ "$r2" = "0" ]; then
	touch -d "${lastupdate}" /var/lib/mod_tile/planet_import_complete
	endtime=$(date +%s)
	echo "Done in $[${endtime}-${starttime}] seconds! All your Maps Belong to Us!"
else
	echo "osm2pgsql did not complete successfully!"
	exit 1
fi

