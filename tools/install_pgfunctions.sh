#!/bin/bash
# this runs as a sub-script called from osm_populate.sh

starttime=$(date +%s)

echo "Installing some Postgresql functions and updating Railway Station directions..."

psql otm < arealabel.sql
psql otm < stationdirection.sql
psql otm < viewpointdirection.sql
psql otm < pitchicon.sql

endtime=$(date +%s)
echo "Done in $[${endtime}-${starttime}] seconds! All your Maps Belong to Us!"
exit 0