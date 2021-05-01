# Step 1/26
FROM alpine:3.13.5
# Step 2/26
MAINTAINER edward.finlayson@btinternet.com

# dependencies required for running "phpize"
# these get automatically installed and removed by "docker-php-ext-*" (unless they're already installed)
# Step 3/26
ENV PHPIZE_DEPS \
    autoconf \
    dpkg-dev dpkg \
    file \
    g++ \
    gcc \
    libc-dev \
    make \
    cmake \
    pkgconf \
    re2c

# persistent / runtime deps
# Step 4/26
RUN apk add --update --no-cache musl>1.2.2_pre2-r0 musl-dev>1.2.2_pre2-r0 \
    ca-certificates \
    curl \
    shadow \
    tar \
    xz \
# https://github.com/docker-library/php/issues/494
    openssl

# User credentials nginx to run as
ENV USER_ID=82 \
    GROUP_ID=82 \
    USER_NAME=www-data \
    GROUP_NAME=www-data

# ensure www-data user exists
# Step 5/26
RUN set -eux; \
#  addgroup -g 82 -S www-data; \
#  adduser -u 82 -D -S -G www-data www-data
  groupadd -r -g "$GROUP_ID" "$GROUP_NAME" && \
  useradd -r -u "$USER_ID" -g "$GROUP_ID" -c "$GROUP_NAME" -d /srv/www -s /sbin/nologin "$USER_NAME"
# 82 is the standard uid/gid for "www-data" in Alpine
# https://git.alpinelinux.org/aports/tree/main/apache2/apache2.pre-install?h=3.9-stable
# https://git.alpinelinux.org/aports/tree/main/lighttpd/lighttpd.pre-install?h=3.9-stable
# https://git.alpinelinux.org/aports/tree/main/nginx/nginx.pre-install?h=3.9-stable
# Step 6/26
ENV PHP_INI_DIR /usr/local/etc/php
# Step 7/26
RUN set -eux; \
  mkdir -p "$PHP_INI_DIR/conf.d"; \
# allow running as an arbitrary user (https://github.com/docker-library/php/issues/743)
  [ ! -d /srv/www ]; \
  mkdir -p /srv/www; \
  chown www-data:www-data /srv/www; \
  chmod 777 /srv/www

# Step 8/26
ENV PHP_EXTRA_CONFIGURE_ARGS --enable-fpm --with-fpm-user="$USER_NAME" --with-fpm-group="$GROUP_NAME" --disable-cgi

# Apply stack smash protection to functions using local buffers and alloca()
# Make PHP's main executable position-independent (improves ASLR security mechanism, and has no performance impact on x86_64)
# Enable optimization (-O2)
# Enable linker optimization (this sorts the hash buckets to improve cache locality, and is non-default)
# https://github.com/docker-library/php/issues/272
# -D_LARGEFILE_SOURCE and -D_FILE_OFFSET_BITS=64 (https://www.php.net/manual/en/intro.filesystem.php)
# Step 9/26
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
# Step 10/26
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
# Step 11/26
ENV PHP_LDFLAGS="-Wl,-O1 -pie"

# Step 12/26
ENV GPG_KEYS 1729F83938DA44E27BA0F4D3DBDB397470D12172 BFDDD28642824F8118EF77909B67A5C12229118F

# Step 13/26
ENV PHP_VERSION 8.0.3
# Step 14/26
ENV PHP_URL="https://www.php.net/distributions/php-8.0.5.tar.xz" PHP_ASC_URL="https://www.php.net/distributions/php-8.0.5.tar.xz.asc"
# Step 15/26
ENV PHP_SHA256="5dd358b35ecd5890a4f09fb68035a72fe6b45d3ead6999ea95981a107fd1f2ab"
# Step 16/26
RUN apk update --no-cache; \
  set -eux; \
  \
  apk add --no-cache --virtual .fetch-deps gnupg; \
  \
  mkdir -p /usr/src; \
  cd /usr/src; \
  \
  curl -fsSL -o php.tar.xz "$PHP_URL"; \
  \
  if [ -n "$PHP_SHA256" ]; then \
    echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -; \
  fi; \
  \
  if [ -n "$PHP_ASC_URL" ]; then \
    curl -fsSL -o php.tar.xz.asc "$PHP_ASC_URL"; \
    export GNUPGHOME="$(mktemp -d)"; \
    for key in $GPG_KEYS; do \
      gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
    done; \
    gpg --batch --verify php.tar.xz.asc php.tar.xz; \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME"; \
  fi; \
  \
  apk del --no-network .fetch-deps
# Step 17/26
COPY docker-php-source /usr/local/bin/
# Step 18/26
RUN chmod +x /usr/local/bin/docker-php-source; \
  set -eux; \
  apk add --update --no-cache \
    libmcrypt \
    libpng-dev \
    libssh2 \
    libssh2-dev \
    libpng \
    libbz2 \
    libjpeg-turbo \
    libxml2 \
    libxml2-dev \
    openssl \
    openssl-dev \
    gettext \
    gettext-dev \
    gmp-dev \
    icu \
    libzip-dev \
    bzip2 \
    bzip2-dev \
    zip \
    freetype \
    freetype-dev \
  ;\
  \
  apk add --update --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    autoconf \
    argon2-dev \
    aspell-dev \
    bison \
    coreutils \
    curl-dev \
    jpeg-dev \
    jpeg \
    krb5 \
    krb5-dev \
    libmcrypt-dev \
    libedit-dev \
    libjpeg-turbo-dev\
    libressl-dev \
    libsodium-dev \
    libzip-dev \
    linux-headers \
    oniguruma-dev \
    sqlite-dev \
    freetds \
    freetds-dev \
    icu-dev \
    imap-dev \
    libxslt-dev \
    libgcrypt-dev \
    libwebp-dev \
    libxpm-dev \
    tidyhtml-dev \
    zlib-dev \
    mlocate \
  ; \
  \
  export CFLAGS="$PHP_CFLAGS" \
    CPPFLAGS="$PHP_CPPFLAGS" \
    LDFLAGS="$PHP_LDFLAGS" \
  ; \
  docker-php-source extract; \
  cd /usr/src/php; \
  gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
  ./configure \
    --build="$gnuArch" \
    --sysconfdir=/usr/local/etc \
    --with-config-file-path="$PHP_INI_DIR" \
    --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
    \
# make sure invalid --configure-flags are fatal errors instead of just warnings
    --enable-option-checking=fatal \
    \
# https://github.com/docker-library/php/issues/439
    --with-mhash \
    \
# https://github.com/docker-library/php/issues/822
    --with-pic \
    \
# --enable-ftp is included here because ftp_ssl_connect() needs ftp to be compiled statically (see https://github.com/docker-library/php/issues/236)
    --enable-ftp=shared \
# --enable-mbstring is included here because otherwise there's no way to get pecl to use it properly (see https://github.com/docker-library/php/issues/195)
    --enable-mbstring \
# --enable-mysqlnd is included here because it's harder to compile after the fact than extensions are (since it's a plugin for several extensions, not an extension in itself)
    --enable-mysqlnd \
# https://wiki.php.net/rfc/argon2_password_hash (7.2+)
    --with-password-argon2 \
# https://wiki.php.net/rfc/libsodium
    --with-sodium=shared \
# always build against system sqlite3 (https://github.com/php/php-src/commit/6083a387a81dbbd66d6316a3a12a63f06d5f7109)
    --with-pdo-sqlite=/usr \
    --with-sqlite3=/usr \
    \
    --enable-bcmath \
    --with-bz2=shared \
    --with-curl=shared \
    --enable-calendar=shared \
    --enable-ctype=shared \
    --with-freetype \
    --with-xpm \
    --without-gdbm \
    --with-gettext \
    --enable-ftp \
    --enable-gd \
    --with-jpeg \
    --with-iconv \
#    --enable-exif \
    --with-kerberos \
    --with-libedit \
    --with-libxml \
    --enable-xml \
    --with-mhash \
    --enable-opcache \
    --with-openssl \
    --enable-pcntl \
    --enable-phar \
    --with-pspell \
    --without-readline \
    --enable-shmop \
    --enable-soap \
    --enable-sockets \
    --enable-xmlreader \
    --enable-xmlwriter \
    --with-zip=shared \
    --with-zlib \
    \
# in PHP 7.4+, the pecl/pear installers are officially deprecated (requiring an explicit "--with-pear")
# This causes the build process to throw: configure: WARNING: The --with-pear option is deprecated 
# but his is a non-fatal warning, while deprecated the switch still works.
    --with-pear \
    --with-gmp=shared \
    --enable-dom \
    --enable-fileinfo=shared \
    --with-imap=shared \
    --with-imap-ssl \
    --with-ldap-sasl \
    --with-xsl=shared,/usr \
    --with-tidy=shared,/usr \
    \
    \
    --with-system-ciphers \
    --enable-pcntl=shared \
    --with-pdo-sqlite=shared,/usr \
    --enable-posix=shared \
    --with-pspell=shared \
    --without-readline \
    --enable-session \
    --enable-shmop=shared \
    --enable-simplexml=shared \
    --enable-sockets=shared \
    --with-sqlite3=shared,/usr \
    --enable-sysvmsg=shared \
    --enable-sysvsem=shared \
    --enable-sysvshm=shared \
    --with-tidy=shared \
    --enable-tokenizer=shared \
    --with-zlib \
    --with-zlib-dir=/usr \
    --enable-fpm \
    --enable-embed \
##    --with-litespeed build_alias=x86_64-alpine-linux-musl host_alias=x86_64-alpine-linux-musl \
    \
# bundled pcre does not support JIT on s390x
# https://manpages.debian.org/stretch/libpcre3-dev/pcrejit.3.en.html#AVAILABILITY_OF_JIT_SUPPORT
    $(test "$gnuArch" = 's390x-linux-musl' && echo '--without-pcre-jit') \
    \
    ${PHP_EXTRA_CONFIGURE_ARGS:-} \
  ; \
  make -j "$(nproc)"; \
  CONFFILE="/etc/php-fpm.conf.default"; \
  if [ -f "$CONFFILE" ]; then \
    cp -f "$CONFFILE" /usr/local/etc/; \
  fi ; \
  find -type f -name '*.a' -delete; \
  make install; \
  \
  echo ""; \
  echo ""; \
  echo "[ ###################################### 303 ]"; \
  echo ""; \
  echo ""; \
  \
  find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true; \
  \
  echo ""; \
  echo ""; \
  echo "[ ###################################### 311 ]"; \
  echo ""; \
  echo ""; \
  \
  make clean; \
  \
# https://github.com/docker-library/php/issues/692 (copy default example "php.ini" files somewhere easily discoverable)
  cp -v php.ini-* "$PHP_INI_DIR/"; \
  \
  cd /; \
  docker-php-source delete; \
  \
  runDeps="$( \
    scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
      | tr ',' '\n' \
      | sort -u \
      | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
  )"; \
  apk add --no-cache $runDeps; \
# update pecl channel definitions https://github.com/docker-library/php/issues/443
  pecl update-channels; \
  pecl install mcrypt; \
  pecl install mongodb; \
  pecl install -o -f redis; \
#  pecl install -f ssh2-1.2; \
  pecl install xdebug; \
  \
  apk del --no-network .build-deps; \
  \
  rm -rf /tmp/pear ~/.pearrc;

# smoke test
#  php --version

# Step 19/26
COPY docker-php-ext-* docker-php-entrypoint /usr/local/bin/

# sodium was built as a shared module (so that it can be replaced later if so desired), so let's enable it too (https://github.com/docker-library/php/issues/598)
# Step 20/26
RUN chmod +x /usr/local/bin/docker-php-entrypoint; \
    chmod +x /usr/local/bin/docker-php-ext*; \
    apk add --no-cache bash; \
    docker-php-ext-install bz2 opcache mysqli pdo pdo_mysql soap xml; \
    docker-php-ext-enable sodium mcrypt mongodb zip redis.so xdebug xml soap;

# Step 21/26
ENTRYPOINT ["docker-php-entrypoint"]
# Step 21/26
WORKDIR /srv/www

# Step 23/26
RUN set -eux; \
  cd /usr/local/etc; \
#  CONFFILE="/etc/php-fpm.conf.default"; \
#  if [ -f "$CONFFILE" ]; then \
#    cp -f "$CONFFILE" /usr/local/etc/; \
#  fi ; \
  if [ -d php-fpm.d ]; then \
    # for some reason, upstream's php-fpm.conf.default has "include=NONE/etc/php-fpm.d/*.conf"
    sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null; \
    cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
  else \
    # PHP 5.x doesn't use "include=" by default, so we'll create our own simple config that mimics PHP 7+ for consistency
    mkdir php-fpm.d; \
    cp php-fpm.conf.default php-fpm.d/www.conf; \
    { \
      echo '[global]'; \
      echo 'include=etc/php-fpm.d/*.conf'; \
    } | tee php-fpm.conf; \
  fi; \
  { \
    echo '[global]'; \
    echo 'error_log = /proc/self/fd/2'; \
    echo; echo '; https://github.com/docker-library/php/pull/725#issuecomment-443540114'; echo 'log_limit = 8192'; \
    echo; \
    echo '[www]'; \
    echo '; if we send this to /proc/self/fd/1, it never appears'; \
    echo 'access.log = /proc/self/fd/2'; \
    echo; \
    echo 'clear_env = no'; \
    echo; \
    echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
    echo 'catch_workers_output = yes'; \
    echo 'decorate_workers_output = no'; \
  } | tee php-fpm.d/docker.conf; \
  { \
    echo '[global]'; \
    echo 'daemonize = no'; \
    echo; \
    echo '[www]'; \
    echo 'listen = 9000'; \
  } | tee php-fpm.d/zz-docker.conf

# Override stop signal to stop process gracefully
# https://github.com/php/php-src/blob/17baa87faddc2550def3ae7314236826bc1b1398/sapi/fpm/php-fpm.8.in#L163
# Step 24/26
STOPSIGNAL SIGQUIT

# Step 25/26
EXPOSE 9000
# Step 16/26
CMD ["php-fpm"]
