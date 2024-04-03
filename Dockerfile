ARG ALPINE_VERSION="${ALPINE_VERSION}"
ARG PHP_VERSION="${PHP_VERSION}"

FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION}

# Technoboggle Build time arguments.
ARG PHPMYADMIN_VERSION="${PHPMYADMIN_VERSION}"
ARG PHPMYADMIN_SHA="${PHPMYADMIN_SHA}"
ARG MAINTAINER="${MAINTAINER}"
ARG AUTHORNAME="${AUTHORNAME}"
ARG AUTHORS="${AUTHORS}"
ARG VERSION="${VERSION}"
ARG SCHEMAVERSION="${SCHEMAVERSION}"
ARG NAME="${NAME}"
ARG DESCRIPTION="${DESCRIPTION}"
ARG URL="${URL}"
ARG VCS_URL="${VCS_URL}"
ARG VSC_REF="${VSC_REF}"
ARG VENDOR="${VENDOR}"
ARG BUILD_VERSION="${BUILD_VERSION}"
ARG BUILD_DATE="${BUILD_DATE}"

# Labels.
LABEL maintainer=${MAINTAINER}
LABEL net.technoboggle.authorname=${AUTHORNAME} \
      net.technoboggle.authors=${AUTHORS} \
      net.technoboggle.version=${VERSION} \
      net.technoboggle.description=${DESCRIPTION} \
      net.technoboggle.buildDate=${BUILD_DATE}

LABEL org.label-schema.schema-version=${SCHEMAVERSION}
LABEL org.label-schema.build-date=${BUILD_DATE}
LABEL org.label-schema.name=${NAME}
LABEL org.label-schema.description=${DESCRIPTION}
LABEL org.label-schema.url=${URL}
LABEL org.label-schema.vcs-url=${VCS_URL}
LABEL org.label-schema.vcs-ref=${VSC_REF}
LABEL org.label-schema.vendor=${VENDOR}
LABEL org.label-schema.version=${BUILDVERSION}
LABEL org.label-schema.docker.cmd=${DOCKERCMD}

#WORKDIR /app

# Create the php-fpm user and group with the correct UID and GID to match the host
RUN if [ id "82" >/dev/null 2>&1; ]; then deluser --remove-home www-data; if [ $(getent group www-data) ]; then delgroup www-data; addgroup -g 1000 -S www-data; else addgroup -g 1000 -S www-data; fi; adduser -u 1000 -D -S -G www-data www-data; else if [ $(getent group www-data) ]; then delgroup www-data; addgroup -g 1000 -S www-data; else addgroup -g 1000 -S www-data; fi; adduser -u 1000 -D -S -G www-data www-data; fi; \
    \
    # Create the php-fpm log directory
    mkdir -p /var/log/php-fpm; \
    chown -R www-data:www-data /var/log/php-fpm; \
    # Create the php-fpm run directory
    mkdir -p /var/run/php-fpm; \
    chown -R www-data:www-data /var/run/php-fpm; \
    # Create the php-fpm conf directory
    mkdir -p /usr/local/etc/php-fpm.d; \
    chown -R www-data:www-data /usr/local/etc/php-fpm.d; \
    # Create the php-fpm root directory
    mkdir -p /var/www/html; \
    chown -R www-data:www-data /var/www/html && \
    \
    apk update --no-cache && \
    apk upgrade --no-cache && \
    \
    # persistent / runtime deps
    set -eux; \
	apk add --no-cache --upgrade \
		ca-certificates \
		curl \
	 ; \
	# The following add command is an attempt to install libxml2-dev
    # package in order to solve the security vulnerability: CVE-2024-25062
    apk add --no-cache --upgrade \
    libxml2=="2.12.6-r0" \
    libxml2-dev=="2.12.6-r0" \
    libxslt \
    libxml2-utils=="2.12.6-r0" \
    c-ares=="1.27.0-r0" \
    --repository https://dl-cdn.alpinelinux.org/alpine/edge/main/ \
    --allow-untrusted && \
    # The following add command is an attempt to install curl & libcurl
    # package in order to solve the security vulnerability: CVE-2024-0853
    \
    apk add --no-cache --upgrade \
    curl \
    curl-dev \
    libcurl \
    --repository https://dl-cdn.alpinelinux.org/alpine/edge/main/ \
    --allow-untrusted; \
    \
	apk add --no-cache --upgrade \
        php83-apache2 \
        php83-bcmath \
        php83-bz2 \
        php83-calendar \
        php83-cgi \
        #php83-ctype \
        #php83-curl \
        php83-dba \
        php83-dbg \
        php83-dev \
        #php83-dom \
        php83-embed \
        php83-enchant \
        php83-exif \
        php83-ffi \
        #php83-fileinfo \
        php83-ftp \
        php83-gd \
        php83-gettext \
        php83-gmp \
        #php83-iconv \
        php83-imap \
        php83-intl \
        php83-ldap \
        #php83-mbstring \
        #php83-mysqlnd \
        php83-mysqli \
        php83-odbc \
        php83-opcache \
        #php83-openssl \
        php83-pcntl \
        #php83-pdo \
        php83-pdo_dblib \
        php83-pdo_mysql \
        php83-pdo_odbc \
        php83-pdo_pgsql \
        #php83-pdo_sqlite \
        php83-pear \
        php83-pgsql \
        #php83-phar \
        php83-phpdbg \
        php83-posix \
        php83-pspell \
        #php83-session \
        #php83-simplexml \
        #php83-sodium \
        php83-snmp \
        php83-soap \
        php83-shmop \
        php83-sockets \
        #php83-sqlite3 \
        php83-sysvmsg \
        php83-sysvsem \
        php83-sysvshm \
        php83-tidy \
        #php83-tokenizer \
        php83-pecl-opentelemetry \
        #php83-xml \
        php83-xmlreader \
        php83-xmlwriter \
        php83-xsl \
        php83-pecl-ssh2 \
        #php83-pecl-imagick \
        #php83-pecl-imagick-dev \
        php83-zip \
        php83-pecl-zstd \
        php83-pecl-event \
        php83-pecl-amqp \
        php83-pecl-ds \
        php83-pecl-xdebug \
        php83-pecl-xhprof \
        php83-pecl-xhprof-assets \
        php83-pecl-rdkafka \
        php83-pecl-maxminddb \
        php83-pecl-igbinary \
        #php83-pecl-grpc \
        #php83-pecl-swoole \
        #php83-pecl-swoole-dev \
        php83-pecl-yaml \
        php83-pecl-msgpack \
        php83-pecl-pcov \
        php83-pecl-psr \
        php83-pecl-redis \
        php83-pecl-smbclient \
        php83-pecl-uploadprogress-doc \
        php83-pecl-couchbase \
        php83-pecl-luasandbox \
        php83-pecl-mailparse \
        php83-pecl-memcache \
        php83-pecl-memcached \
        php83-pecl-apcu \
        php83-pecl-ast \
        php83-pecl-brotli \
        php83-pecl-mongodb \
	 ; \
    rm -rf /var/lib/apt/lists/*

# Install extensions
RUN curl -sSL https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o - | sh -s \
    # apcu \
    # csv \
    # ev \
    # event \
    geospatial \
    gmagick \
    # gnupg \
    # http \
    inotify \
    # ion \
    json_post \
    # jsonpath \
    lz4 \
    # lzf \
    maxminddb \
    odbc \
    opentelemetry \
    pkcs11 \
    # protobuf \
    # raphf \
    # rdkafka \
    # seasclick \
    # seaslog \
    smbclient \
    # snappy \
    # solr \
    # sqlsrv \
    # stomp \
    # uopz \
    uuid \
    xhprof \
    # yac \
    yaml \
    zmq;

# Copy main script
COPY docker-php-entrypoint /docker-entrypoint.sh

ENTRYPOINT [ "/docker-entrypoint.sh" ]

#EXPOSE 9000
CMD ["php-fpm"]
