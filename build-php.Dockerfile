FROM alpine:3.12.3
MAINTAINER edward.finlayson@btinternet.com

# dependencies required for running "phpize"
# these get automatically installed and removed by "docker-php-ext-*" (unless they're already installed)
ENV PHPIZE_DEPS \
    autoconf \
    dpkg-dev dpkg \
    file \
    g++ \
    gcc \
    libc-dev \
    make \
    pkgconf \
    re2c

# persistent / runtime deps
RUN apk add --no-cache \
    ca-certificates \
    curl \
    tar \
    xz \
# https://github.com/docker-library/php/issues/494
    openssl

# ensure www-data user exists
RUN set -eux; \
  addgroup -g 82 -S www-data; \
  adduser -u 82 -D -S -G www-data www-data
# 82 is the standard uid/gid for "www-data" in Alpine
# https://git.alpinelinux.org/aports/tree/main/apache2/apache2.pre-install?h=3.9-stable
# https://git.alpinelinux.org/aports/tree/main/lighttpd/lighttpd.pre-install?h=3.9-stable
# https://git.alpinelinux.org/aports/tree/main/nginx/nginx.pre-install?h=3.9-stable

ENV PHP_INI_DIR /usr/local/etc/php
RUN set -eux; \
  mkdir -p "$PHP_INI_DIR/conf.d"; \
# allow running as an arbitrary user (https://github.com/docker-library/php/issues/743)
  [ ! -d /var/www/html ]; \
  mkdir -p /var/www/html; \
  chown www-data:www-data /var/www/html; \
  chmod 777 /var/www/html

# Apply stack smash protection to functions using local buffers and alloca()
# Make PHP's main executable position-independent (improves ASLR security mechanism, and has no performance impact on x86_64)
# Enable optimization (-O2)
# Enable linker optimization (this sorts the hash buckets to improve cache locality, and is non-default)
# https://github.com/docker-library/php/issues/272
# -D_LARGEFILE_SOURCE and -D_FILE_OFFSET_BITS=64 (https://www.php.net/manual/en/intro.filesystem.php)
ENV PHP_EXTRA_CONFIGURE_ARGS="--enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --disable-cgi" \
    PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64" \
    PHP_CPPFLAGS="$PHP_CFLAGS" \
    PHP_LDFLAGS="-Wl,-O1 -pie" \
    GPG_KEYS="1729F83938DA44E27BA0F4D3DBDB397470D12172 BFDDD28642824F8118EF77909B67A5C12229118F" \
    PHP_VERSION="8.0.0" \
    PHP_URL="https://www.php.net/distributions/php-8.0.0.tar.xz" \
    PHP_ASC_URL="https://www.php.net/distributions/php-8.0.0.tar.xz.asc" \
    PHP_SHA256="b5278b3eef584f0c075d15666da4e952fa3859ee509d6b0cc2ed13df13f65ebb"
#RUN apk update

RUN apk update; \
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

COPY docker-php-source /usr/local/bin/

RUN set -eux; \
  apk add --no-cache \
    libmcrypt \
    libpng-dev \
    libssh2 \
    libssh2-dev \
    libpng \
    libjpeg-turbo \
; \
  apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    autoconf \
    argon2-dev \
    aspell-dev \
    bison \
    bzip2-dev \
    coreutils \
    curl-dev \
    freetype \
    freetype-dev \
    jpeg-dev \
    jpeg \
    krb5 \
    krb5-dev \
    libmcrypt-dev \
    libedit-dev \
    libjpeg-turbo-dev\
    libxml2-dev \
    libressl-dev \
    libsodium-dev \
    libzip-dev \
    linux-headers \
    oniguruma-dev \
    openssl-dev \
    sqlite-dev \
    zlib-dev \
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
    --enable-ftp \
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
    \
# in PHP 7.4+, the pecl/pear installers are officially deprecated (requiring an explicit "--with-pear")
# This causes the build process to throw: configure: WARNING: The --with-pear option is deprecated 
# but his is a non-fatal warning, while deprecated the switch still works.
    --with-pear \
    \
    --enable-bcmath \
    --with-bz2 \
    --with-curl \
    --enable-calendar \
#    --with-freetype-dir=/usr \
#    --with-png \
#    --with-xpm-dir=/usr \
#    --enable-gd-native-ttf \
#    --with-t1lib=/usr \
#    --without-gdbm \
#    --with-gettext \
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
#    --with-system-tzdata \
    --without-readline \
    --enable-shmop \
    --enable-soap \
    --enable-sockets \
    --enable-xmlreader \
    --enable-xmlwriter \
    --with-zip=shared \
    --with-zlib \
#    --with-gmp=shared \
#    --enable-dba=shared \
#    --with-db4=/usr \
#    --with-gdbm=/usr \
#    --with-tcadb=/usr \
#    --with-ldap-sasl \
#    --with-xsl=shared,/usr \
#    --enable-json=shared \
#    --with-mcrypt=shared,/usr \
#    --with-tidy=shared,/usr \
#    --with-unixODBC=shared,/usr \
\
# bundled pcre does not support JIT on s390x
# https://manpages.debian.org/stretch/libpcre3-dev/pcrejit.3.en.html#AVAILABILITY_OF_JIT_SUPPORT
    $(test "$gnuArch" = 's390x-linux-musl' && echo '--without-pcre-jit') \
    \
    ${PHP_EXTRA_CONFIGURE_ARGS:-} \
  ; \
  make -j "$(nproc)"; \
  find -type f -name '*.a' -delete; \
  make install; \
  find /usr/local/bin /usr/local/sbin -type f -perm +0111 -exec strip --strip-all '{}' + || true; \
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
  \
# update pecl channel definitions https://github.com/docker-library/php/issues/443
  pecl update-channels; \
  pecl install mcrypt; \
  pecl install mongodb; \
  pecl install redis; \
#  pecl install -f ssh2-1.2; \
  pecl install xdebug; \
  apk del --no-network .build-deps; \
  \
  rm -rf /tmp/pear ~/.pearrc; \
  \
# smoke test
  php --version

COPY docker-php-ext-* docker-php-entrypoint /usr/local/bin/
# sodium was built as a shared module (so that it can be replaced later if so desired), so let's enable it too (https://github.com/docker-library/php/issues/598)
RUN apk update; \
    docker-php-ext-enable sodium; \
    docker-php-ext-enable mcrypt; \
    docker-php-ext-enable mongodb; \
    docker-php-ext-install opcache; \
    docker-php-ext-enable redis; \
#    docker-php-ext-enable ssh2; \
    docker-php-ext-enable xdebug; \
    docker-php-ext-enable zip

ENTRYPOINT ["docker-php-entrypoint"]
WORKDIR /var/www/html

RUN set -eux; \
  cd /usr/local/etc; \
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
STOPSIGNAL SIGQUIT

EXPOSE 9000
CMD ["php-fpm"]
