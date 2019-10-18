# mapserver-docker
Docker image for [mapserver](https://mapserver.org) 7.0.7

(*OUTPUT=PNG OUTPUT=JPEG OUTPUT=KML SUPPORTS=PROJ SUPPORTS=AGG SUPPORTS=FREETYPE SUPPORTS=CAIRO SUPPORTS=SVG_SYMBOLS SUPPORTS=RSVG SUPPORTS=ICONV SUPPORTS=FRIBIDI SUPPORTS=WMS_SERVER SUPPORTS=WMS_CLIENT SUPPORTS=WFS_SERVER SUPPORTS=WFS_CLIENT SUPPORTS=WCS_SERVER SUPPORTS=SOS_SERVER SUPPORTS=FASTCGI SUPPORTS=THREADS SUPPORTS=GEOS INPUT=JPEG INPUT=POSTGIS INPUT=OGR INPUT=GDAL INPUT=SHAPEFILE*)

## Installation 

### From dockerhub

    docker pull jjrom/mapserver

### Build from source
Launch the following command and go for a coffee break

    docker build -t jjrom/mapserver:1.0 -t jjrom/mapserver:latest .

## Start container

Using docker-compose (edit config.env to change default environment values)

    docker-compose up -d

Using docker

    docker run -d -p 8282:80 -v `pwd`/map:/map jjrom/mapserver

## Access container via http
Open the following URL:

    http://localhost:8282/wms

The response should be

    No query information to decode. QUERY_STRING is set, but empty.

Or with real data (assuming you mount the local map directory)

    http://localhost:8282/wms/generic?layers=GTOPO30_SAMPLE%20airports&mode=map&map_imagetype=png&mapext=14.9688+-10.0312+65.0312+40.0312&imgext=14.9688+-10.0312+65.0312+40.0312&map_size=800+800&imgx=400&imgy=400&imgxy=800+800

    http://localhost:8282/wms/geojson?layers=countries,geojson&mode=map&map_imagetype=png&mapext=-90+-180+90+180&width=800&height=800

## Post mapfile

    curl -X POST --data-binary -H "Authorization: Bearer SetYourTokenHere" -d@./map/generic.map localhost:8282/map/12345.map

## Delete mapfile

    curl -X DELETE -H "Authorization: Bearer SetYourTokenHere" localhost:8282/map/12345.map