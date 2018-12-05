#!/bin/bash

exec > >(awk '{print strftime("%Y-%m-%d %H:%M:%S [1] "),$0; fflush();}')
exec 2> >(awk '{print strftime("%Y-%m-%d %H:%M:%S [2] "),$0; fflush();}' >&2)

starttime=$(date +%s)

echo "Installing some Postgresql functions and updating Railway Station directions..."

psql otm < arealabel.sql
psql otm < stationdirection.sql
psql otm < viewpointdirection.sql
psql otm < pitchicon.sql

endtime=$(date +%s)
echo "Done in $[${endtime}-${starttime}] seconds! All your Maps Belong to Us!"
exit 0