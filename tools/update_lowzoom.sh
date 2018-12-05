#!/bin/bash

ipaddress=$(ip addr show eth1|awk '/inet /{print $2}' |awk 'BEGIN{FS="/"}{print $1}')

/bin/echo -n "Please provide the password for postgres user 'osm':"
read password

[ -z "$password" ] && echo "I need the postgres 'osm' user's password in order to set up some database Views!" && exit 1

# water
echo "Simplifying water polygons..."
psql -d otm -c "CREATE OR REPLACE VIEW lowzoom_water AS SELECT ST_SimplifyPreserveTopology(way,150) AS way,name,\"natural\",waterway,way_area FROM planet_osm_polygon WHERE (\"natural\" = 'water' OR waterway = 'riverbank' OR water='lake' OR landuse IN ('basin','reservoir')) AND way_area > 50000;"
psql -d lowzoom -c "DROP TABLE IF EXISTS water;"
psql -d lowzoom -c "CREATE TABLE IF NOT EXISTS water (way geometry(Geometry,900913), name text, \"natural\" text, waterway text, way_area real);"
psql -d lowzoom -c "INSERT INTO water SELECT * FROM dblink('hostaddr=${ipaddress} dbname=otm user=osm password=${password}','SELECT * FROM lowzoom_water') AS t(way geometry(Geometry,900913), name text, \"natural\" text, waterway text, way_area real);"
psql -d lowzoom -c "CREATE INDEX water_way_idx ON water USING GIST (way);"


# landuse
echo "Simplifying landuse polygons..."
psql -d otm -c "CREATE OR REPLACE VIEW lowzoom_landuse AS SELECT ST_SimplifyPreserveTopology(way,150) AS way,landuse,\"natural\" FROM planet_osm_polygon WHERE landuse = 'forest' OR \"natural\" = 'wood' AND way_area > 50000;"
psql -d lowzoom -c "DROP TABLE IF EXISTS landuse;"
psql -d lowzoom -c "CREATE TABLE IF NOT EXISTS landuse (way geometry(Geometry,900913), landuse text, \"natural\" text);"
psql -d lowzoom -c "INSERT INTO landuse SELECT * FROM dblink('hostaddr=${ipaddress} dbname=otm user=osm password=${password}','SELECT * FROM lowzoom_landuse') AS t(way geometry(Geometry,900913), landuse text, \"natural\" text);"
psql -d lowzoom -c "CREATE INDEX landuse_way_idx ON landuse USING GIST (way);"
	
	
# roads
echo "Simplifying roads..."
psql -d otm -c "CREATE OR REPLACE VIEW lowzoom_roads AS SELECT ST_SimplifyPreserveTopology(way,100) AS way,highway,ref FROM planet_osm_line WHERE highway IN ('motorway','trunk','primary','secondary','tertiary','motorway_link','trunk_link','primary_link','secondary_link','tertiary_link');"
psql -d lowzoom -c "DROP TABLE IF EXISTS roads;"
psql -d lowzoom -c "CREATE TABLE IF NOT EXISTS roads (way geometry(LineString,900913), highway text, ref text);"
psql -d lowzoom -c "INSERT INTO roads SELECT * FROM dblink('hostaddr=${ipaddress} dbname=otm user=osm password=${password}','SELECT * FROM lowzoom_roads') AS t(way geometry(LineString,900913), highway text, ref text);"
psql -d lowzoom -c "CREATE INDEX roads_way_idx ON roads USING GIST (way);"


# borders
echo "Simplifying borders..."
psql -d otm -c "CREATE OR REPLACE VIEW lowzoom_borders AS SELECT ST_SimplifyPreserveTopology(way,150) AS way,boundary,admin_level FROM planet_osm_line WHERE boundary = 'administrative' AND admin_level IN ('2','4','5','6');"
psql -d lowzoom -c "DROP TABLE IF EXISTS borders;"
psql -d lowzoom -c "CREATE TABLE IF NOT EXISTS borders (way geometry(LineString,900913), boundary text, admin_level text);"
psql -d lowzoom -c "INSERT INTO borders SELECT * FROM dblink('hostaddr=${ipaddress} dbname=otm user=osm password=${password}','SELECT * FROM lowzoom_borders') AS t(way geometry(LineString,900913), boundary text, admin_level text);"
psql -d lowzoom -c "CREATE INDEX borders_way_idx ON borders USING GIST (way);"


# railways
echo "Simplifying railways..."
psql -d otm -c "CREATE OR REPLACE VIEW lowzoom_railways AS SELECT ST_SimplifyPreserveTopology(way,50) AS way,railway,\"service\",tunnel FROM planet_osm_line WHERE (\"service\" IS NULL AND railway IN ('rail','light_rail'));"
psql -d lowzoom -c "DROP TABLE IF EXISTS railways;"
psql -d lowzoom -c "CREATE TABLE IF NOT EXISTS railways (way geometry(LineString,900913), railway text, \"service\" text, tunnel text);"
psql -d lowzoom -c "INSERT INTO railways SELECT * FROM dblink('hostaddr=${ipaddress} dbname=otm user=osm password=${password}','SELECT * FROM lowzoom_railways') AS t(way geometry(LineString,900913), railway text, \"service\" text, tunnel text);"
psql -d lowzoom -c "CREATE INDEX railways_way_idx ON railways USING GIST (way);"
	
	
# cities and towns
echo "Simplifying cities and towns..."
psql -d otm -c "CREATE OR REPLACE VIEW lowzoom_cities AS SELECT way,admin_level,name,capital,place,population::integer FROM planet_osm_point WHERE place IN ('city','town') AND (population IS NULL OR population SIMILAR TO '[[:digit:]]+') AND (population IS NULL OR population::integer > 5000);"
psql -d lowzoom -c "DROP TABLE IF EXISTS cities;"
psql -d lowzoom -c "CREATE TABLE IF NOT EXISTS cities (way geometry(Point,900913), admin_level text, name text, capital text, place text, population integer);"
psql -d lowzoom -c "INSERT INTO cities SELECT * FROM dblink('hostaddr=${ipaddress} dbname=otm user=osm password=${password}','SELECT * FROM lowzoom_cities') AS t(way geometry(Point,900913), admin_level text, name text, capital text, place text, population integer);"
psql -d lowzoom -c "CREATE INDEX cities_way_idx ON cities USING GIST (way);"


# water polygon labels
echo "Create lines for labels of water polygons..."
psql -d otm -c "CREATE OR REPLACE VIEW lowzoom_lakelabel    AS SELECT arealabel(osm_id,way) AS way,name,'lakeaxis'::text    AS label,way_area FROM planet_osm_polygon WHERE (\"natural\" = 'water' OR water='lake' OR landuse IN ('basin','reservoir')) AND name IS NOT NULL;"
psql -d otm -c "CREATE OR REPLACE VIEW lowzoom_baylabel     AS SELECT arealabel(osm_id,way) AS way,name,'bayaxis'::text     AS label,way_area FROM planet_osm_polygon WHERE  \"natural\" = 'bay' AND name IS NOT NULL;"
psql -d otm -c "CREATE OR REPLACE VIEW lowzoom_straitplabel AS SELECT arealabel(osm_id,way) AS way,name,'straitaxis'::text  AS label,way_area FROM planet_osm_polygon WHERE  \"natural\" = 'strait' AND name IS NOT NULL;"
psql -d otm -c "CREATE OR REPLACE VIEW lowzoom_straitllabel AS SELECT ST_LineMerge(longway) AS way,name,'straitaxis'::text AS label,len*len/10 as way_area FROM (SELECT ST_Collect(way) AS longway,SUM(ST_Length(way)) AS len,MAX(name) AS name FROM planet_osm_line WHERE \"natural\"='strait' AND name is NOT NULL GROUP BY osm_id) AS t;"
psql -d otm -c "CREATE OR REPLACE VIEW lowzoom_glacierlabel AS SELECT arealabel(osm_id,way) AS way,name,'glacieraxis'::text AS label,way_area FROM planet_osm_polygon WHERE  \"natural\" = 'glacier' AND name IS NOT NULL;"
psql -d lowzoom -c "DROP TABLE IF EXISTS lakelabels;"
psql -d lowzoom -c "CREATE TABLE IF NOT EXISTS lakelabels (way geometry(LineString,3857), name text, label text, lake_area real);"
psql -d lowzoom -c "INSERT INTO lakelabels SELECT * FROM dblink('hostaddr=${ipaddress} dbname=otm user=osm password=${password}','SELECT * FROM lowzoom_lakelabel')    AS t(way geometry(LineString,3857), name text, label text, way_area real);"
psql -d lowzoom -c "INSERT INTO lakelabels SELECT * FROM dblink('hostaddr=${ipaddress} dbname=otm user=osm password=${password}','SELECT * FROM lowzoom_baylabel')     AS t(way geometry(LineString,3857), name text, label text, way_area real);"
psql -d lowzoom -c "INSERT INTO lakelabels SELECT * FROM dblink('hostaddr=${ipaddress} dbname=otm user=osm password=${password}','SELECT * FROM lowzoom_straitplabel') AS t(way geometry(LineString,3857), name text, label text, way_area real);"
psql -d lowzoom -c "INSERT INTO lakelabels SELECT * FROM dblink('hostaddr=${ipaddress} dbname=otm user=osm password=${password}','SELECT * FROM lowzoom_straitllabel') AS t(way geometry(LineString,3857), name text, label text, way_area real);"
psql -d lowzoom -c "INSERT INTO lakelabels SELECT * FROM dblink('hostaddr=${ipaddress} dbname=otm user=osm password=${password}','SELECT * FROM lowzoom_glacierlabel') AS t(way geometry(LineString,3857), name text, label text, way_area real);"
psql -d lowzoom -c "CREATE INDEX lakelabels_way_idx ON lakelabels USING GIST (way);"

