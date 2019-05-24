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

    http://localhost:8282/

The response should be

    No query information to decode. QUERY_STRING is set, but empty.

Or with real data (assuming you mount the local map directory)

    http://localhost:8282/?map=/map/generic.map&layers=GTOPO30_SAMPLE%20airports&mode=map&map_imagetype=png&mapext=14.9688+-10.0312+65.0312+40.0312&imgext=14.9688+-10.0312+65.0312+40.0312&map_size=800+800&imgx=400&imgy=400&imgxy=800+800

    http://localhost:8282/?map=/map/raster.map&layers=tif&mode=map&map_imagetype=png&mapext=3964972.86+3964267.08+4042892.87+4040903.33&imgext=3964972.86+3964267.08+4042892.87+4040903.33&map_size=800+800&imgx=400&imgy=400&imgxy=800+800

    http://localhost:8282/?map=/map/raster.map&service=WMS&request=GetMap&layers=tif&format=image/png&transparent=true&version=1.1.1&srs=EPSG:3857&bbox=3964972.86,3964267.08,4042892.87,4040903.33&width=800&height=800


    http://localhost:8282/?map=/map/raster.map&width=72&height=36&layer=tif&version=1.1.1&service=WMS&format=image/png&request=GetLegendGraphic

    url:'https://services.sentinel-hub.com/ogc/wms/cf180083-b3ce-e15e-d0d1-37045122b93c',
			type:'WMS',
			zIndex:300,
			layerOptions:{
				layers:'TRUE_COLOR',
				style:'',
				preset:'CUSTOM',
				format:'image/jpeg',
				transparent:true,
				version:'1.1.1',
				name:'sentinel2',
				srs:'EPSG:3857',
				preview:1,
				bgcolor:'dddddd',
				WARNINGS:'NO',
				showLogo:false,
				attribution:'&copy; Sentinel Layer',
				maxcc:100,
				detectRetina:true