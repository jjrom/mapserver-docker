FROM jjrom/s6-overlay:focal-1.0.0
LABEL maintainer="jerome.gasperi@gmail.com"

#ENV DEBIAN_FRONTEND=noninteractive

# Add packages
RUN apt-get update && \
    apt-get install -y \
    software-properties-common \
    curl \
    inetutils-syslogd \
    cgi-mapserver \
    mapserver-bin \
    fcgiwrap \
    spawn-fcgi \
    nginx && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

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
RUN mkdir /map


