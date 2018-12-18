#!/bin/bash
# calculate how much disk space each zoom level in each map style is using


echo "Calculating disk space used. This may take some time!"
echo "Size     Path" >disk_usage.txt

find /var/lib/mod_tile -type d  -maxdepth 1 -mindepth 1 |sort |while read b; do
    for i in 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do 
        [ -d $b/$i ] && du -s $b/$i | tee -ia disk_usage.txt 
    done;
done

echo "Done. A copy of this analysis is stored in 'disk_usage.txt'. All your Maps Belong to Us!"
