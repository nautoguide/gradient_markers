-- Function: ng_research.contour_interpolate(geometry, character varying, character varying)

-- DROP FUNCTION ng_research.contour_interpolate(geometry, character varying, character varying);

CREATE OR REPLACE FUNCTION ng_research.contour_interpolate(
    geometry_param geometry,
    contour_table_param character varying,
    elevation_field_param character varying DEFAULT 'elevation'::character varying)
  RETURNS geometry AS
$BODY$
DECLARE
	return_geometry_var GEOMETRY;
BEGIN
	EXECUTE $SQL$

        --Interpolate the height based upon the distance of point from closest contour
		SELECT ST_Makepoint(
				    ST_X($1),
				    ST_Y($1),
				    ROUND((lag(elevation) over () + (elevation - lag(elevation) over() )  * (lag(distance) over() / (distance + lag(distance) over())))::NUMERIC,2)
				    )
		FROM (
		    --Find 2 closest contours to the point and distance from point to contour
			SELECT
				$SQL$||elevation_field_param||$SQL$ AS elevation,
				ST_Distance($1,wkb_geometry) as distance
			FROM $SQL$|| contour_table_param ||$SQL$
			ORDER BY $1 <-> wkb_geometry
			LIMIT 2
		) FOO
		OFFSET 1
	$SQL$
	INTO return_geometry_var
	USING ST_TRANSFORM(geometry_param, 27700);

	RETURN ST_SETSRID(return_geometry_var,ST_SRID(geometry_param));
END;
$BODY$
  LANGUAGE plpgsql;