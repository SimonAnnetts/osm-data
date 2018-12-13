#!/bin/bash

# script to prerender tiles for selected zoom levels and map styles for the British Isles + Netherlands
# if the map style contains the name 27700 then we only render the British Isles.

function printUsage() {
	cat <<EOF
Usage: osm_render_tiles -z [zoom levels] -m [map names]
	-z	a comma separated list of zoom levels
	-m	a comma separated list of map names as defined in renderd.conf
EOF
}

starttime=$(date +%s)
zoom_levels=""
maps_names=""
while [[ $# -gt 0 ]];  do
	argument="$1" 
	case $argument in
		-z) zoom_levels=$(echo "$2"| sed 's/,/ /g'); shift 2;;
		-m) map_names=$(echo "$2"| sed 's/,/ /g'); shift 2;;
		-*) echo "Unknown argument: \"$argument\""; printUsage; exit 1;;
		*) break;;
	esac
done

# prefix all output from now on with timestamps
exec > >(awk '{print strftime("%Y-%m-%d %H:%M:%S [1] "),$0; fflush();}' |tee -ia render.log)
exec 2> >(awk '{print strftime("%Y-%m-%d %H:%M:%S [2] "),$0; fflush();}' |tee -ia render.log >&2)
echo "Starting rendering for zoom_levels=${zoom_levels} and map_names={$map_names}"

for i in $zoom_levels; do

	for j in $map_names; do
		echo "Starting rendering zoom level ${i} for map style ${j}..."
		istarttime=$(date +%s)

		is27700=0
		[ -n "$(echo ${j}|grep 27700)" ] && is27700=1

		# number of threads to use (depends on zoomlevel, complexity and memory usgae)
		n=4
		if [ ${is27700} ]; then
			[ $i = 3 ] || [ $i = 7 ] && n=2
			[ $i = 4 ] || [ $i = 5 ] || [ $i = 6 ] && n=1
			# our 27700 map is square with bounds [-350000, -100000, 1050000, 1300000] and origin at tile 0, 2^$i
			X=$(echo "2^${i}-1"|bc)
			Y=$(echo "2^${i}-1"|bc)
			bb="-x 0 -X ${X} -y 0 -Y ${Y}"
			render_list -a -l 99 -n ${n} -m "${j}" ${bb} -z ${i} -Z ${i} -f
			[ $? != 0 ] && echo "Rendering failed on zoom level ${i} for map style ${j} !" && exit 1
		else
			[ $i = 8 ] || [ $i = 12 ] && n=2
			[ $i = 9 ] || [ $i = 10 ] || [ $i = 11 ] && n=1
			# read our bounding box list from file
			cat bboxes_900913.txt |grep -v '#' |while read bb; do
				if [ -n ${bb} ]; then
					./render_list_geo.sh -n ${n} -m "${j}" ${bb} -z ${i} -Z ${i} -f
					[ $? != 0 ] && echo "Rendering failed on zoom level ${i} for map style ${j} !" && exit 1
				fi
			done
		fi
		
		iendtime=$(date +%s)
		echo "Done rendering zoom level ${i} for map style ${j} in $[${iendtime}-${istarttime}] seconds! All your Maps Belong to Us!"
	
		echo "Restarting renderd ...."
		pkill renderd
		sleep 3
		while [ -z "$(pgrep renderd)" ]; do sleep 1; done
		sleep 20
	done
	
done

endtime=$(date +%s)
echo "Done all requested maps and zoomlevels in $[${endtime}-${starttime}] seconds! All your Maps Belong to Us!"
