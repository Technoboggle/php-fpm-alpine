#!/usr/bin/env sh

owd="$(pwd)"
cd "$(dirname "$0")" || exit

phpfpm_ver="8.2.8"
alpine_ver="3.18"

# Setting File permissions
xattr -c .git
xattr -c .gitignore
xattr -c .dockerignore
xattr -c ./*
chmod 0666 ./*
find "$(pwd)" -type d -exec chmod ugo+x {} \;
find "$(pwd)" -type f -exec chmod ugo=wr {} \;
find "$(pwd)" -type f \( -iname \*.sh -o -iname \*.py \) -exec chmod ugo+x {} \;
chmod 0666 .gitignore
chmod 0666 .dockerignore
chmod 0777 docker-php-entrypoint
chmod 0777 docker-php-ext-configure
chmod 0777 docker-php-ext-enable
chmod 0777 docker-php-ext-install
chmod 0777 docker-php-source

curl -sSLf -o install-php-extensions https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions
chmod +x install-php-extensions

current_builder=$(docker buildx ls | grep -i '\*' | head -n1 | awk '{print $1;}')

docker buildx create --name tb_builder --use --bootstrap

docker login -u="technoboggle" -p="dckr_pat_FhwkY2NiSssfRBW2sJP6zfkXsjo"

docker buildx build -f Dockerfile --platform linux/arm64,linux/amd64,linux/386 \
    -t technoboggle/php-fpm-alpine:"$phpfpm_ver-$alpine_ver" \
    --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    --build-arg VCS_REF="$(git rev-parse --verify HEAD)" \
    --build-arg BUILD_VERSION=0.05 \
    --force-rm \
    --no-cache \
    --push .

#--progress=plain

rm -f install-php-extensions

docker run -it -d --rm -p 9000:9000 --name myphp technoboggle/php-fpm-alpine:"$phpfpm_ver-$alpine_ver"
#docker tag technoboggle/php-fpm-alpine:"$phpfpm_ver-$alpine_ver" technoboggle/php-fpm-alpine:latest
#docker login
#docker push technoboggle/php-fpm-alpine:"$phpfpm_ver-$alpine_ver"
#docker push technoboggle/php-fpm-alpine:latest
docker container stop -t 10 myphp

docker buildx use "${current_builder}"
docker buildx rm tb_builder

cd "$owd" || exit
