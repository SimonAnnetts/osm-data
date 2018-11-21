#!/bin/bash

# script to prerender tile from zoom level 0 to 16 for the British Isles + Netherlands

exec > >(awk '{print strftime("%Y-%m-%d %H:%M:%S [1] "),$0; fflush();}' |tee -ia render.log)
exec 2> >(awk '{print strftime("%Y-%m-%d %H:%M:%S [2] "),$0; fflush();}' |tee -ia render.log >&2)

starttime=$(date +%s)

for i in 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do

	n=4
	[ $i = 8 ] || [ $i = 12 ] && n=2
	[ $i = 9 ] || [ $i = 10 ] || [ $i = 11 ] && n=1

	echo "Rendering Zoom level ${i} for contoured: "
	render_list_geo -n ${n} -m contoured -x -11 -X 8 -y 48.75 -Y 62.5 -z ${i} -Z ${i}	
	[ $? != 0 ] && echo "Render failed on zoom level ${i} !" && exit 1
	echo "Done!"
	
	echo "Restarting renderd ...."
	pkill renderd
	sleep 3
	while [ -z "$(pgrep renderd)" ]; do sleep 1; done
	sleep 10
	
done

for i in 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do

	n=4
	[ $i = 8 ] || [ $i = 12 ] && n=2
	[ $i = 9 ] || [ $i = 10 ] || [ $i = 11 ] && n=1

	echo "Rendering Zoom level ${i} for uncontoured: "
	render_list_geo -n ${n} -m uncontoured -x -11 -X 8 -y 48.75 -Y 62.5 -z ${i} -Z ${i}
	[ $? != 0 ] && echo "Render failed on zoom level ${i} !" && exit 1
	echo "Done!"
	
	echo "Restarting renderd ...."
	pkill renderd
	sleep 3
	while [ -z "$(pgrep renderd)" ]; do sleep 1; done
	sleep 10
	
done

for i in 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do

	n=4
	[ $i = 8 ] || [ $i = 12 ] && n=2
	[ $i = 9 ] || [ $i = 10 ] || [ $i = 11 ] && n=1

	echo "Rendering Zoom level ${i} for opentopomapc: "
	render_list_geo -n ${n} -m opentopomapc -x -11 -X 8 -y 48.75 -Y 62.5 -z ${i} -Z ${i}	
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
