--ADD Z Values to road network
DROP TABLE IF EXISTS ng_research.su_roads_3d;
SELECT id,ng_research.add_height_to_line_contour_v3(wkb_geometry, 'ng_research.terrain_50_contour', 'prop_value') as wkb_geometry INTO ng_research.su_roads_3d
FROM ng_research.su_roads
WHERE wkb_geometry && 'BOX(405677 176736,408207 178054)'::BOX2D;

CREATE INDEX su_roads_3d_idx ON ng_research.su_roads_3d using GIST (wkb_geometry);

--CREATE Gradients
DROP TABLE IF EXISTS ng_research.su_gradients_all;
WITH CTE AS (

	SELECT  id,
		wkb_geometry
		FROM ng_research.su_roads_3d

), LINEMERGE AS (

	SELECT ST_LINEMERGE(R.wkb_geometry) as wkb_geometry
	FROM ng_research.su_roads_3d R,CTE
	WHERE R.id != CTE.id
	AND ST_Intersects(R.wkb_geometry, CTE.wkb_geometry)
) SELECT (ng_research.gradient_finder(wkb_geometry,0.14,0.17)).* INTO ng_research.su_gradients_all FROM LINEMERGE;

CREATE INDEX su_gradients_all_idx ON ng_research.su_gradients_all using GIST (wkb_geometry);

--SPACE Gradients
DROP TABLE IF EXISTS ng_research.su_gradients_final;

SELECT 	(ng_research.gradient_spacer('ng_research.su_gradients_all', 500)).* INTO ng_research.su_gradients_final;
