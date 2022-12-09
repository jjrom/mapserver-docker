FROM camptocamp/mapserver:latest

ENV MS_DEBUGLEVEL=0 \
    MS_ERRORFILE=stderr \
    MAPSERVER_CONFIG_FILE=/etc/mapserver.conf \
    MAX_REQUESTS_PER_PROCESS=1000 \
    MIN_PROCESSES=1 \
    MAX_PROCESSES=5 \
    BUSY_TIMEOUT=300 \
    IDLE_TIMEOUT=300 \
    IO_TIMEOUT=40 \
    GET_ENV=env

# OGC API support
COPY ./build/etc/apache2/conf-enabled/mapserver.conf /etc/apache2/conf-enabled/mapserver.conf
COPY ./build/etc/mapserver/share /etc/mapserver/share

# Map and data directory
RUN mkdir /map
RUN mkdir /data

# Mapserver >= 8 must provide a config file
COPY ./mapserver.conf /etc/mapserver.conf

WORKDIR /etc/mapserver


