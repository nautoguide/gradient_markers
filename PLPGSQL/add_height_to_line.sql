-- Function: ng_research.add_height_to_line(geometry, text, integer)

CREATE OR REPLACE FUNCTION ng_research.add_height_to_line(
    geometry_param geometry,
    dem_table_param text,
    steps_param integer)
  RETURNS geometry AS
$BODY$
DECLARE

	return_geometry geometry;
BEGIN


EXECUTE
	$SQL$
	WITH measured_line AS (

     --Sample along the line
	  SELECT ST_AddMeasure($1, 0, ST_Length($1)) as lm_geom,
		 generate_series(0, CEIL(ST_Length($1))::INT, $2)    as i
          UNION
	 --Important to get the last point on the line
	  SELECT ST_AddMeasure($1, 0, ST_Length($1)) as lm_geom,
	         ST_Length($1) as i

	), points_2d AS (
        --Create a set of points
		SELECT ST_Transform(ST_GeometryN(ST_LocateAlong(lm_geom,i),1),4326) AS point_geometry
		FROM measured_line ORDER BY i ASC


	), dem_points AS (
        --Add height to points
		SELECT point_geometry,
			ST_Value(rast,1, point_geometry) as height
		FROM $SQL$ || dem_table_param ||$SQL$, points_2d
		WHERE ST_Intersects(rast,  point_geometry)

	), points_3d AS (
        --Construct 3D points
		SELECT ST_TRANSFORM(ST_SETSRID(ST_MakePoint(ST_X(point_geometry), ST_Y(point_geometry),height),4326),ST_SRID($1)) as point_geometry_3d
		FROM dem_points
	)
    --Make the line
	SELECT ST_MakeLine(point_geometry_3d) FROM points_3d
	$SQL$

	INTO return_geometry
	USING geometry_param, steps_param;

RETURN return_geometry;

END;
$BODY$
  LANGUAGE plpgsql