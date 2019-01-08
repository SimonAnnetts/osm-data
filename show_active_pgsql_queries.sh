#!/bin/bash

# show the currently running pgsql queries

psql -P pager -x -c "SELECT pid, now() - query_start as runtime, usename, datname, waiting, state, query FROM  pg_stat_activity WHERE now() - query_start > '2 minutes'::interval and state = 'active'  ORDER BY runtime DESC;" -d gis
