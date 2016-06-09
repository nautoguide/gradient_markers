-- Function: ng_research.add_height_to_line_contour_v2(geometry, text, text)

-- DROP FUNCTION ng_research.add_height_to_line_contour_v2(geometry, text, text);

CREATE OR REPLACE FUNCTION ng_research.add_height_to_line_contour_v2(
    geometry_param geometry,
    contour_table text,
    elevation_field text)
  RETURNS geometry AS
$BODY$
DECLARE
	geometry_ret_var geometry;
BEGIN

	EXECUTE $SQL$
	  WITH CTE AS (
		SELECT (ST_Dump(ST_Intersection($1,c1.wkb_geometry))).geom as geometry,
			$SQL$||elevation_field||$SQL$ AS prop_value
		FROM $SQL$||contour_table||$SQL$ C1
		WHERE  ST_INTERSECTS($1, C1.wkb_geometry)

	  ), Z_POINTS AS (

	  SELECT * FROM(
			SELECT ST_SETSRID(ST_MAKEPOINT(ST_X(geometry),ST_Y(geometry), prop_value),ST_SRID($1)) as point FROM CTE
			UNION
			SELECT ST_SETSRID(ng_research.contour_interpolate((ST_DUMPPOINTS($1)).geom,$2),ST_SRID($1),elevation_field) as point
			) FOO
	  ORDER BY ST_LINELOCATEPOINT(ST_LIneMerge($1),point) ASC

	  )
	  SELECT  ST_Makeline(point) as wkb_geometry  FROM Z_POINTS
	  --ORDER BY ST_LINELOCATEPOINT(ST_LIneMerge($1),point) ASC
	  	$SQL$
      		INTO geometry_ret_var
		USING ST_TRANSFORM(geometry_param,27700),contour_table;


	RETURN geometry_ret_var;
END;
$BODY$
  LANGUAGE plpgsql;