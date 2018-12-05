#!/bin/bash

echo "Installing some postgresql functions..."

psql otm < arealabel.sql
psql otm < stationdirection.sql
psql otm < viewpointdirection.sql
psql otm < pitchicon.sql
