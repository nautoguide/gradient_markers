
#Load SRTM data
raster2pgsql -d -s 4326 -I  srtm_36_02.tif ng_research.srtm_dem | psql -d nautoguide


#Create contours from SRTM
gdal_contour -a elevation srtm_36_02.tif srtm_36_02.shp -i 10.0
