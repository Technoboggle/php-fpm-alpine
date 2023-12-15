FROM php:8.2-fpm-alpine3.18

# Technoboggle Build time arguments.
ARG BUILD_DATE
ARG VCS_REF
ARG BUILD_VERSION

ENV ALPINE_VERSION 3.18
ENV PHPFPM_VERSION 8.2.8

# Labels.
LABEL maintainer="edward.finlayson@btinternet.com"
LABEL net.technoboggle.authorname="Edward Finlayson" \
      net.technoboggle.authors="edward.finlayson@btinternet.com" \
      net.technoboggle.version="0.1" \
      net.technoboggle.description="This image builds a PHP-FPM server on Alpine" \
      net.technoboggle.buildDate="${BUILD_DATE}"

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date="${BUILD_DATE}"
LABEL org.label-schema.name="Technoboggle/php-fpm-alpine"
LABEL org.label-schema.description="Technoboggle lightweight php-fpm node"
LABEL org.label-schema.url="http://technoboggle.com/"
LABEL org.label-schema.vcs-url="https://github.com/Technoboggle/php-fpm"
LABEL org.label-schema.vcs-ref="$VCS_REF"
LABEL org.label-schema.vendor="WSO2"
LABEL org.label-schema.version="$BUILD_VERSION"
LABEL org.label-schema.docker.cmd="docker run -it -d -p 16379:6379 --rm --name myredis technoboggle/php-fpm-alpine:${PHPFPM_VERSION}-${ALPINE_VERSION}"

#WORKDIR /app
COPY ./install-php-extensions /usr/local/bin/
#ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN apk add --upgrade curl libcurl && \
    apk update && \
    chmod +x /usr/local/bin/install-php-extensions && \
    chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions \
        # amqp
        # apcu \
        # apcu_bc \
        # ast \
        bcmath \
        # blackfire \
        bz2 \
        # calendar \
        # cmark \
        # csv \
        # dba \
        # decimal \
        # ds \
        enchant \
        # ev \
        # event \
        # excimer \
        # exif \
        # ffi \
        gd \
        # gearman \
        # geoip \
        # geospatial \
        gettext \
        # gmagick \
        # gmp \
        # gnupg \
        # grpc \
        # http \
        igbinary \
        imagick \
        imap \
        # inotify \
        # intl \
        # ioncube_loader \
        # jsmin \
        # json_post \
        ldap \
        # lzf \
        mailparse \
        # maxminddb \
        mcrypt \
        memcache \
        memcached \
        mongodb \
        # mosquitto \
        msgpack \
        mysqli \
        oauth \
        # oci8 \
        # odbc \
        opcache \
        # opencensus \
        # openswoole \
        # parallel \
        pcntl \
        # pcov \
        # pdo_dblib \
        # pdo_firebird \
        pdo_mysql \
        # pdo_oci \
        # pdo_odbc \
        # pdo_pgsql \
        # pgsql \
        # propro \
        # protobuf \
        pspell \
        # raphf \
        # rdkafka \
        redis \
        # seaslog \
        # shmop \
        # smbclient \
        # snmp \
        # snuffleupagus \
        soap \
        sockets \
        # solr \
        # sourceguardian \
        # spx \
        # sqlsrv \
        ssh2 \
        # stomp \
        # swoole \
        # sysvmsg \
        # sysvsem \
        # sysvshm \
        tidy \
        timezonedb \
        # uopz \
        uploadprogress \
        uuid \
        # vips \
        xdebug-3.2.0 \
        # xhprof \
        xlswriter \
        xmldiff \
        xmlrpc \
        xsl \
        # yac \
        yaml \
        # yar \
        # zephir_parser \
        zip
        # zookeeper \
        # zstd

EXPOSE 9000
CMD ["php-fpm"]
