-- Function: ng_research.add_height_to_line_contour(geometry, text, text)

-- DROP FUNCTION ng_research.add_height_to_line_contour(geometry, text, text);

CREATE OR REPLACE FUNCTION ng_research.add_height_to_line_contour(
    geometry_param geometry,
    contour_table text,
    elevation_field text)
  RETURNS geometry AS
$BODY$
DECLARE
	geometry_ret_var geometry;
BEGIN

	geometry_param := ST_SETSRID(geometry_param,27700);
	EXECUTE $SQL$
	  WITH CTE AS (
		SELECT (ST_Dump(ST_Intersection($1,c1.wkb_geometry))).geom as geometry,
			$SQL$||elevation_field||$SQL$ AS prop_value
		FROM $SQL$||contour_table||$SQL$ C1
		WHERE  ST_INTERSECTS($1, C1.wkb_geometry)

	  ), Z_POINTS AS (

	  SELECT ST_MAKEPOINT(ST_X(geometry),ST_Y(geometry), prop_value) as point FROM CTE
	  ORDER BY ST_LINELOCATEPOINT(ST_LIneMerge($1),geometry) ASC

	  ), START_POINT AS (
		SELECT ST_MAKEPOINT(ST_X(ST_StartPoint(ST_LineMerge($1))),
				    ST_Y(ST_StartPoint(ST_LineMerge($1))),
				    prop_value + min(distance) over () / sum(distance) over() * ABS(prop_value - lag(prop_value) over())) as point
				    FROM
		(
		 SELECT C1.prop_value,
			ST_Distance(ST_StartPoint(ST_LineMerge($1)), C1.wkb_geometry) as distance
		  FROM $SQL$||contour_table||$SQL$ C1
		  ORDER BY wkb_geometry <-> ST_StartPoint(ST_LineMerge($1))
		  LIMIT 2
		) AS FOO

	  ), END_POINT AS (
		SELECT ST_MAKEPOINT(ST_X(ST_EndPoint(ST_LineMerge($1))),
				    ST_Y(ST_EndPoint(ST_LineMerge($1))),
				    prop_value + min(distance) over () / sum(distance) over() * ABS(prop_value - lag(prop_value) over())) as point
				    FROM
		(
		SELECT C1.prop_value,
		       ST_Distance(ST_EndPoint(ST_LineMerge($1)), C1.wkb_geometry) as distance
		  FROM $SQL$||contour_table||$SQL$ C1
		  ORDER BY wkb_geometry <-> ST_EndPoint(ST_LineMerge($1))
		  LIMIT 2
		) AS FOO

	  ) SELECT  ST_Makeline(point) as wkb_geometry  FROM (SELECT * FROM START_POINT UNION SELECT * FROM Z_POINTS UNION SELECT * FROM END_POINT) AS FOO
		$SQL$
		INTO geometry_ret_var
		USING geometry_param;


	RETURN geometry_ret_var;

END;
$BODY$
  LANGUAGE plpgsql;