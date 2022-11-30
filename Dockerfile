FROM osgeo/gdal:ubuntu-small-3.6.0 AS builder
LABEL maintainer Camptocamp "info@camptocamp.com"
SHELL ["/bin/bash", "-o", "pipefail", "-cux"]

RUN --mount=type=cache,target=/var/cache,sharing=locked \
    --mount=type=cache,target=/root/.cache \
    apt-get update \
    && apt-get upgrade --assume-yes \
    && DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes --no-install-recommends bison \
        flex python3-lxml libfribidi-dev swig \
        cmake librsvg2-dev colordiff libpq-dev libpng-dev libjpeg-dev libgif-dev libgeos-dev libgd-dev \
        libfreetype6-dev libfcgi-dev libcurl4-gnutls-dev libcairo2-dev libxml2-dev \
        libxslt1-dev python3-dev php-dev libexempi-dev lcov lftp ninja-build git curl \
        clang libprotobuf-c-dev protobuf-c-compiler libharfbuzz-dev libcairo2-dev librsvg2-dev \
    && ln -s /usr/local/lib/libproj.so.* /usr/local/lib/libproj.so

ARG MAPSERVER_BRANCH=main
ARG MAPSERVER_REPO=https://github.com/mapserver/mapserver

RUN git config --global http.postBuffer 1048576000 && git clone ${MAPSERVER_REPO} --branch=${MAPSERVER_BRANCH} --depth=100 /src

COPY checkout_release /tmp
RUN cd /src \
    && /tmp/checkout_release ${MAPSERVER_BRANCH}

#COPY instantclient /tmp/instantclient

ARG WITH_ORACLE=OFF

RUN --mount=type=cache,target=/var/cache,sharing=locked \
    --mount=type=cache,target=/root/.cache \
    (if test "${WITH_ORACLE}" = "ON"; then \
       apt-get update && \
       apt-get install --assume-yes --no-install-recommends \
       libarchive-tools libaio-dev && \
       mkdir -p /usr/local/lib && \
       cd /usr/local/lib && \
       (for i in /tmp/instantclient/*.zip; do bsdtar --strip-components=1 -xvf "$i"; done) && \
       ln -s libnnz19.so /usr/local/lib/libnnz18.so; \
     fi )

WORKDIR /src/build
RUN if test "${WITH_ORACLE}" = "ON"; then \
      export ORACLE_HOME=/usr/local/lib; \
    fi; \
    cmake .. \
    -GNinja \
    -DCMAKE_C_FLAGS="-O2 -DPROJ_RENAME_SYMBOLS" \
    -DCMAKE_CXX_FLAGS="-O2 -DPROJ_RENAME_SYMBOLS" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DWITH_CLIENT_WMS=1 \
    -DWITH_CLIENT_WFS=1 \
    -DWITH_OGCAPI=1 \
    -DWITH_KML=1 \
    -DWITH_SOS=1 \
    -DWITH_XMLMAPFILE=1 \
    -DWITH_POINT_Z_M=1 \
    -DWITH_CAIRO=1 \
    -DWITH_RSVG=1 \
    -DUSE_PROJ=1 \
    -DUSE_WFS_SVR=1 \
    -DUSE_OGCAPI_SVR=1 \
    -DWITH_ORACLESPATIAL=${WITH_ORACLE}

RUN ninja install \
    && if test "${WITH_ORACLE}" = "ON"; then rm -rf /usr/local/lib/sdk; fi

FROM osgeo/gdal:ubuntu-small-3.6.0 AS runner
LABEL maintainer jjrom "jerome.gasperi@gmail.com"
SHELL ["/bin/bash", "-o", "pipefail", "-cux"]

# Let's copy a few of the settings from /etc/init.d/apache2
ENV MS_MAP_PATTERN=^\\/etc\\/mapserver\\/([^\\.][-_A-Za-z0-9\\.]+\\/{1})*([-_A-Za-z0-9\\.]+\\.map)$

# Add packages
RUN --mount=type=cache,target=/var/cache,sharing=locked \
    --mount=type=cache,target=/root/.cache \
    apt-get update && apt-get upgrade -y && apt-get install -y \
    xz-utils \
    software-properties-common \
    curl \
    inetutils-syslogd \
    fcgiwrap \
    spawn-fcgi \
    nginx \
    libfribidi0 librsvg2-2 libpng16-16 libgif7 libfcgi0ldbl \
    libxslt1.1 libprotobuf-c1 libcap2-bin libaio1 glibc-tools \
    && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Add S6 supervisor (for graceful stop)
ADD https://github.com/just-containers/s6-overlay/releases/download/v3.1.2.1/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v3.1.2.1/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
	tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && \
	rm -rf /tmp/*.tar.xz
ENTRYPOINT [ "/init" ]

RUN mkdir --parent /etc/mapserver

COPY --from=builder /usr/local/bin /usr/local/bin/
COPY --from=builder /usr/local/lib /usr/local/lib/
COPY --from=builder /usr/local/share/mapserver /usr/local/share/mapserver/
COPY --from=builder /src/share/ogcapi/templates/html-bootstrap4 /usr/local/share/mapserver/ogcapi/templates/html-bootstrap4/
COPY --from=builder /usr/local/bin/mapserv /usr/lib/cgi-bin/mapserv
RUN ldconfig

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

# Copy NGINX service script
COPY ./app/start-nginx.sh /etc/services.d/nginx/run
RUN chmod 755 /etc/services.d/nginx/run

# Copy FCGIWRAP service script
COPY ./app/start-fcgiwrap.sh /etc/services.d/fcgiwrap/run
RUN chmod 755 /etc/services.d/fcgiwrap/run

# Copy map scripts
COPY ./app/map_manager /usr/lib/cgi-bin/map_manager

# Copy NGINX configuration
COPY ./app/container_root/etc/nginx /etc/nginx

# Copy run.d configuration
COPY ./app/container_root/cont-init.d /etc/cont-init.d

# Map directory
RUN mkdir /data

# Mapserver >= 8 must provide a config file
COPY ./mapserver.conf /etc/mapserver.conf

WORKDIR /etc/mapserver


