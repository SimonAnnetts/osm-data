#!/bin/bash

# script to prerender tile from zoom level 0 to 16 for the British Isles + Netherlands

function printUsage() {
	cat <<EOF
Usage: osm_render_tiles -z [zoom levels] -m [map names]
	-z	a comma separated list of zoom levels
	-m	a comma separated list of map names as defined in renderd.conf
EOF
}

starttime=$(date +%s)

OPTIND=1         # Reset in case getopts has been used previously in the shell.
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
echo "zoom_levels=$zoom_levels map_names=$map_names"

for i in $zoom_levels; do
	n=4
	[ $i = 8 ] || [ $i = 12 ] && n=2
	[ $i = 9 ] || [ $i = 10 ] || [ $i = 11 ] && n=1

	for j in $map_names; do
		bb="-x -11 -X 8 -y 48.75 -Y 62.5"
		[ -n "$(echo ${j}|grep 27700)" ] && bb="-x -11 -X 2 -y 48.75 -Y 62.5"

		echo "Rendering Zoom level ${i} for ${j}: "
		./render_list_geo.sh -n ${n} -m "${j}" ${bb} -z ${i} -Z ${i} -f
		[ $? != 0 ] && echo "Render failed on zoom level ${i} for ${j} !" && exit 1
		echo "Done!"
	
		echo "Restarting renderd ...."
		pkill renderd
		sleep 3
		while [ -z "$(pgrep renderd)" ]; do sleep 1; done
		sleep 20
	done
	
done

endtime=$(date +%s)
echo "Done in $[${endtime}-${starttime}] seconds! All your Maps Belong to Us!"
