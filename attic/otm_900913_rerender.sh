#!/bin/bash

# script to rerender tile from passed in zoom levels for the British Isles + Netherlands

exec > >(awk '{print strftime("%Y-%m-%d %H:%M:%S [1] "),$0; fflush();}' |tee -ia render.log)
exec 2> >(awk '{print strftime("%Y-%m-%d %H:%M:%S [2] "),$0; fflush();}' |tee -ia render.log >&2)

starttime=$(date +%s)

for i in $*; do

	n=4
	[ $i = 8 ] || [ $i = 12 ] && n=2
	[ $i = 9 ] || [ $i = 10 ] || [ $i = 11 ] && n=1

	echo "Rendering Zoom level ${i} for 900913-otm-c: "
	./render_list_geo.sh -n ${n} -m "900913-otm-c" -x -11 -X 8 -y 48.75 -Y 62.5 -z ${i} -Z ${i}	-f
	[ $? != 0 ] && echo "Render failed on zoom level ${i} !" && exit 1
	echo "Done!"

	echo "Rendering Zoom level ${i} for 900913-otm-u: "
	./render_list_geo.sh -n ${n} -m "900913-otm-u" -x -11 -X 8 -y 48.75 -Y 62.5 -z ${i} -Z ${i} -f
	[ $? != 0 ] && echo "Render failed on zoom level ${i} !" && exit 1
	echo "Done!"
	
	echo "Restarting renderd ...."
	pkill renderd
	sleep 3
	while [ -z "$(pgrep renderd)" ]; do sleep 1; done
	sleep 10
	
done

endtime=$(date +%s)
echo "Done in $[${endtime}-${starttime}] seconds! All your Maps Belong to Us!"
