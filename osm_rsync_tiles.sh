#!/bin/bash

# script to prerender tiles for selected zoom levels and map styles for the British Isles + Netherlands
# if the map style contains the name 27700 then we only render the British Isles.

function printUsage() {
	cat <<EOF
Usage: osm_rsync_tiles.sh -z [zoom levels] -m [map names] -s [server list] -t [tile store]
	-z	a comma separated list of zoom level(s)
	-m	a comma separated list of map name(s) as defined in renderd.conf
    -s  a comma separated list of tile store server(s)
    -t  a single named or numbered base tile store on the remote server(s)
EOF
}

starttime=$(date +%s)
zoom_levels=""
maps_names=""
servers=""
tile_store=""
while [[ $# -gt 0 ]];  do
	argument="$1" 
	case $argument in
		-z) zoom_levels=$(echo "$2"| sed 's/,/ /g'); shift 2;;
		-m) map_names=$(echo "$2"| sed 's/,/ /g'); shift 2;;
        -s) servers=$(echo "$2"| sed 's/,/ /g'); shift 2;;
        -t) tile_store="$2"; shift 2;;
		-*) echo "Unknown argument: \"$argument\""; printUsage; exit 1;;
		*) break;;
	esac
done

# prefix all output from now on with timestamps
exec > >(awk '{print strftime("%Y-%m-%d %H:%M:%S [1] "),$0; fflush();}' |tee -ia render.log)
exec 2> >(awk '{print strftime("%Y-%m-%d %H:%M:%S [2] "),$0; fflush();}' |tee -ia render.log >&2)
echo "Starting tile transfer for servers=${servers} zoom_levels=${zoom_levels} and map_names=${map_names}"

srcDir=/var/lib/mod_tile
destDir=/var/lib/mod_tile_${tile_store}
for s in $servers; do

    for i in $zoom_levels; do

        for j in $map_names; do
            echo "Starting tile transfer for zoom level ${i} and map style ${j} to server ${s}..."
            istarttime=$(date +%s)

            ssh ${s} "mkdir -p ${destDir}/${j}/${i} 2>/dev/null" && rsync -e ssh -uav --delete ${srcDir}/${j}/${i}/* ${s}:/${destDir}/${j}/${i}/
            [ $? != 0 ] && echo "Tile transfer failed on zoom level ${i} and map style ${j} to server ${s}!" && exit 1
        
            iendtime=$(date +%s)
            echo "Done tile transfer for zoom level ${i} and map style ${j} to server ${s} in $[${iendtime}-${istarttime}] seconds! All your Maps Belong to Us!"
        done
        
    done

done

endtime=$(date +%s)
echo "Done all requested maps and zoomlevels and servers in $[${endtime}-${starttime}] seconds! All your Maps Belong to Us!"
