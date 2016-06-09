CREATE OR REPLACE FUNCTION ng_research.gradient_spacer(gradient_table_param character varying, spacing_param integer)
RETURNS TABLE(wkb_geometry geometry, gradient double precision, azimuth double precision, chevron_type character varying, id BIGINT) AS

$$
BEGIN

RETURN QUERY
	EXECUTE $SQL$
		WITH
		     clusters(wkb_geometry) AS
		     (
		       SELECT ST_CollectionExtract(unnest(ST_ClusterWithin(wkb_geometry,$1)),1)
		       FROM $SQL$|| gradient_table_param ||$SQL$
		     ),
		     cl1(clusterid,wkb_geometry) AS
		     (
		      SELECT row_number() OVER (),
			     (ST_Dump(wkb_geometry)).geom as wkb_geometry
		      FROM clusters
		      ),
		      parts(gradient,clusterid, wkb_geometry) AS
		      (
		       SELECT gradient, clusterid, NG.wkb_geometry,azimuth,chevron_type
		       FROM $SQL$|| gradient_table_param ||$SQL$ NG, cl1
		       WHERE ST_Intersects(NG.wkb_geometry, cl1.wkb_geometry)
		      )
		      SELECT DISTINCT ON (clusterid) wkb_geometry,gradient,azimuth,chevron_type,clusterid

		      FROM parts
		      ORDER BY clusterid, gradient DESC
		 $SQL$
		 USING spacing_param;
	RETURN;
END;
$$
LANGUAGE PLPGSQL;