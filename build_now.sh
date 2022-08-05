#!/usr/bin/env sh

owd="`pwd`"
cd "$(dirname "$0")"

phpfpm_ver="8.1.8"
alpine_ver="3.16.1"

# Setting File permissions
xattr -c .git
xattr -c .gitignore
xattr -c .dockerignore
xattr -c *
chmod 0666 *
chmod 0666 .gitignore
chmod 0666 .dockerignore
chmod 0777 docker-php-entrypoint
chmod 0777 docker-php-ext-configure
chmod 0777 docker-php-ext-enable
chmod 0777 docker-php-ext-install
chmod 0777 docker-php-source

curl -sSLf -o install-php-extensions https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions
chmod +x install-php-extensions

docker build -f Dockerfile -t technoboggle/php-fpm-alpine:"$phpfpm_ver-$alpine_ver" --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') --build-arg VCS_REF="`git rev-parse --verify HEAD`" --build-arg BUILD_VERSION=0.05 --force-rm --no-cache .
#--progress=plain 

docker run -it -d --rm -p 9000:9000 --name myphp technoboggle/php-fpm-alpine:"$phpfpm_ver-$alpine_ver"
docker tag technoboggle/php-fpm-alpine:"$phpfpm_ver-$alpine_ver" technoboggle/php-fpm-alpine:latest
docker login
docker push technoboggle/php-fpm-alpine:"$phpfpm_ver-$alpine_ver"
docker push technoboggle/php-fpm-alpine:latest
#docker container stop -t 10 myphp

cd "$owd"
