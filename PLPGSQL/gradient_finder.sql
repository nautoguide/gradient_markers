-- Function: ng_research.gradient_finder(geometry, double precision, double precision)

-- DROP FUNCTION ng_research.gradient_finder(geometry, double precision, double precision);

CREATE OR REPLACE FUNCTION ng_research.gradient_finder(
    IN geometry_param geometry,
    IN single_chevron_param double precision DEFAULT 0.14,
    IN double_chevron_param double precision DEFAULT 0.20)
  RETURNS TABLE(wkb_geometry geometry, gradient double precision, azimuth double precision, chevron_type character varying) AS
$BODY$
DECLARE
	r record;
	previous_point geometry (pointz,27700);
	dx numeric;
	dy numeric;
BEGIN
	--Naughty hard coded SRID
	geometry_param := ST_SETSRID(geometry_param,27700);

	--Iterate through geometry to discover gradients
	FOR r in SELECT * from ST_DumpPoints(geometry_param) as point LOOP

		--First point so don't bother calculating gradient
		IF previous_point IS NULL THEN previous_point := r.geom; CONTINUE; END IF;

			dx := ST_Distance(previous_point,r.geom);
			dy := ST_Z(r.geom) - ST_Z(previous_point);
			wkb_geometry := r.geom;
			gradient := Round(dy/dx, 2) * 100;
			azimuth := ST_Azimuth(r.geom,previous_point)* 180 / pi();

			CASE WHEN  ABS(dy/dx) >= double_chevron_param AND dx > 30 THEN
				chevron_type := 'double';
				RETURN NEXT;
			     WHEN ABS(dy/dx) >= single_chevron_param AND dx > 30 THEN
				chevron_type := 'single';
				RETURN NEXT;
			ELSE
			END CASE;
		previous_point := r.geom;

	END LOOP;
END;
$BODY$
  LANGUAGE plpgsql;