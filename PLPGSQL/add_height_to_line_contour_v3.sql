CREATE OR REPLACE FUNCTION ng_research.add_height_to_line_contour_v3(
    geometry_param geometry,
    contour_table text,
    elevation_field text,
    resample_distance integer DEFAULT 50)
  RETURNS geometry AS
$BODY$
DECLARE
	geometry_ret_var geometry;
	resampled_line_var geometry;
BEGIN

--Resample the line to get a point ever N metres, note well our assumption is EPSG 27700

EXECUTE $SQL$
	WITH measured_line AS (


	  SELECT ST_AddMeasure($1, 0, ST_Length($1)) as lm_geom,
		 generate_series(0, CEIL(ST_Length($1))::INT, $2)    as i
          UNION
	 --Important to get the last point on the line
	  SELECT ST_AddMeasure($1, 0, ST_Length($1)) as lm_geom,
	         ST_Length($1) as i 
          
	), points_2d AS (

		SELECT ST_GeometryN(ST_LocateAlong(lm_geom,i),1) AS point_geometry 
		FROM measured_line ORDER BY i ASC
	

	)
	SELECT ST_MakeLine(point_geometry) FROM points_2d 
	$SQL$ INTO resampled_line_var 
	USING ST_TRANSFORM(geometry_param,27700), resample_distance;
	


EXECUTE $SQL$
	  WITH CTE AS (
		SELECT (ST_Dump(ST_Intersection($1,c1.wkb_geometry))).geom as geometry,
			$SQL$||elevation_field||$SQL$ AS prop_value
		FROM $SQL$||contour_table||$SQL$ C1
		WHERE  ST_INTERSECTS($1, C1.wkb_geometry)

	  ), Z_POINTS AS (

	  SELECT * FROM(
			--SELECT ST_SETSRID(ST_MAKEPOINT(ST_X(geometry),ST_Y(geometry), prop_value),ST_SRID($1)) as point FROM CTE
			--UNION 
			SELECT ST_SETSRID(ng_research.contour_interpolate((ST_DUMPPOINTS($1)).geom,$2,$3),ST_SRID($1)) as point
			) FOO
	  ORDER BY ST_LINELOCATEPOINT(ST_LIneMerge($1),point) ASC

	  )
	  SELECT  ST_Makeline(point) as wkb_geometry  FROM Z_POINTS
	  --ORDER BY ST_LINELOCATEPOINT(ST_LIneMerge($1),point) ASC
	  	$SQL$
      		INTO geometry_ret_var
		USING ST_TRANSFORM(resampled_line_var,27700),contour_table,elevation_field;

	RAISE NOTICE 'ROAD DONE';
	RETURN geometry_ret_var;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION ng_research.add_height_to_line_contour_v3(geometry, text, text, integer)
  OWNER TO postgres;
