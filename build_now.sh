#!/usr/bin/env sh

owd="$(pwd)"
cd "$(dirname "$0")" || exit

BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
VCS_REF="$(git rev-parse --verify HEAD)"

export BUILD_DATE
export VCS_REF

sed -i.bu -E 's/BUILD_DATE=".*"/BUILD_DATE="'"${BUILD_DATE}"'"/g' env.hcl
sed -i.bu -E 's/VCS_REF=".*"/VCS_REF="'"${VCS_REF}"'"/g' env.hcl

if [ -f env.hcl ]; then
    export $(cat env.hcl | xargs)
fi

if [ -f .perms ]; then
    export $(cat .perms | xargs)
fi

sed -i.bu -E 's/BUILD_DATE=".*"/BUILD_DATE=""/g' env.hcl
sed -i.bu -E 's/VCS_REF=".*"/VCS_REF=""/g' env.hcl

rm -f env.hcl.bu

# Setting File permissions
xattr -c .git
xattr -c .gitignore
xattr -c .dockerignore
xattr -c ./*
find ./ -type f -print0 | xargs -0 chmod 0664
find ./ -type d -print0 | xargs -0 chmod 0775
chmod 0777 ./*.sh
chmod 0666 .gitignore
chmod 0666 .dockerignore
chmod 0777 build_now.sh
chmod 0777 hooks/build
chmod 0777 docker-php-entrypoint

docker login -u="${DOCKER_USER}" -p="${DOCKER_PAT}"

current_builder=$(docker buildx ls | grep -i '\s\*' | head -n1 | awk '{print $1;}')
echo "Current builder is: ${current_builder}, switching to technoboggle_builder."

# The following would be for a local builder
docker buildx create --name technoboggle_builder --use --bootstrap
docker buildx bake -f docker-bake.hcl -f env.hcl --builder technoboggle_builder --no-cache --push
#--platform=linux/arm/v6,linux/arm/v7,linux/arm64/v8,linux/arm64,linux/amd64,linux/386,linux/armhf,linux/s390x,linux/ppc64le

# The following would be for a remote builder
#docker buildx create --driver cloud technoboggle/test
#docker buildx bake -f docker-bake.hcl -f env.hcl --builder cloud-technoboggle-builder --no-cache --push

docker run -it -d --rm -p 9000:9000 --name myphpfpm technoboggle/php-fpm-alpine:"${PHP_VERSION}-${ALPINE_VERSION}"
docker container stop -t 10 myphpfpm

echo "Switching back to builder: ${current_builder}"
docker buildx use "${current_builder}"
docker buildx rm technoboggle_builder

cd "$owd" || exit
