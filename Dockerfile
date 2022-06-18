FROM php:7-fpm-alpine3.15


MAINTAINER edward.finlayson@btinternet.com
LABEL net.technoboggle.authorname="Edward Finlayson" \
     net.technoboggle.authors="edward.finlayson@btinternet.com" \
     net.technoboggle.version="0.1" \
     net.technoboggle.description="This image builds a PHP-fpm server" \
     net.technoboggle.buildDate="${BUILD_DATE}"

#WORKDIR /app
COPY ./install-php-extensions /usr/local/bin/
#ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN apk update
RUN chmod +x /usr/local/bin/install-php-extensions && \
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
        geoip \
        geospatial \
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
        # ldap \
        # lzf \
        mailparse \
        # maxminddb \
        mcrypt \
        memcache \
        memcached \
        mongodb \
        # mosquitto \
        # msgpack \
        mysqli \
        oauth \
        # oci8 \
        # odbc \
        opcache \
        # opencensus \
        # openswoole \
        # parallel \
        # pcntl \
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
        # uploadprogress \
        uuid \
        # vips \
        xdebug \
        # xhprof \
        # xlswriter \
        # xmldiff \
        # xmlrpc \
        # xsl \
        # yac \
        yaml \
        # yar \
        # zephir_parser \
        zip \
        # zookeeper \
        # zstd
        && ls -al /usr/local/lib/php/extensions/no-debug-non-zts-20190902/

EXPOSE 9000
CMD ["php-fpm"]
