#!/bin/bash
# script to expire openstreetmap tiles and rebuild
# version 0.1 simonannetts@esdm.co.uk 2018-11-07

exec > >(awk '{print strftime("%Y-%m-%d %H:%M:%S "),$0; fflush();}')
exec 2> >(awk '{print strftime("%Y-%m-%d %H:%M:%S Error: "),$0; fflush();}' >&2)

starttime=$(date +%s)
baseDir=~/osm-data/

# get a list of the datasets we need to update based on the directories present
datasets=$(find -mindepth 2 -maxdepth 2 -type d | awk 'BEGIN{FS="/"}{printf $2 "/" $3 " "}'
expirelists=$(find -mindepth 2 -maxdepth 2 -type d | awk 'BEGIN{FS="/"}{printf $2 "/" $3 "expire.list "}'

uncontoured=0
contoured=0

cat ${expirelists} |uniq >expire.list

if [ -f expire.list ]; then
        echo "Expiring old map tiles in [uncontoured] that updates may have changed..."
        render_expired --map=uncontoured --num-threads=8 --min-zoom=10 --max-zoom=18 <expire.list
        [ $? = 0 ] && uncontoured=1
        #echo "Expiring old map tiles in [contoured] that updates may have changed..."
        #render_expired --map=contoured --num-threads=8 --min-zoom=10 --max-zoom=18 <expire.list
        #[ $? = 0 ] && contoured=1
fi

endtime=$(date +%s)
echo "Done in $[${endtime}-${starttime}] seconds! All your Maps belong to Us!"
