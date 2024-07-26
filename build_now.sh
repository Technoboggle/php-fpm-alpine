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

DOCKERCMD='docker run -it -d --rm -p 9000:9000 --name myphpfpm technoboggle/php-fpm-alpine:'"${PHP_VERSION//\"/}-${ALPINE_VERSION//\"/}"

sed -i.bu -E 's#DOCKERCMD=".*"#DOCKERCMD="'"${DOCKERCMD//\"/}"'"#g' env.hcl

export DOCKERCMD

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

output=$(docker buildx ls | grep -v '^ ')
result=$(echo "$output" | awk '{print $1}' | grep -E '^\S+\*($|\s\*)' | head -n 1)
current_builder=$(echo "$result" | sed 's/[ *]*$//')
echo "Current builder is: ${current_builder}."

docker login -u="${DOCKER_USER}" -p="${DOCKER_PAT}"

# Values to match against
match_values="false FALSE N n"

# Remove any double quotes from BUILD_LOCALLY
BUILD_LOCALLY=$(echo "$BUILD_LOCALLY" | tr -d '"')

# Function to check if a variable is in a list
value_in_list() {
    local value=$1
    local list=$2
    for item in $list; do
        if [ "$item" = "$value" ]; then
            return 0 # found
        fi
    done
    return 1 # not found
}

# Check BUILD_LOCALLY and run appropriate code
if [ -z "$BUILD_LOCALLY" ] || value_in_list "$BUILD_LOCALLY" "$match_values"; then
    # echo "BUILD_LOCALLY is unset, empty, or matches a value in the match list"
    echo "Building remotely"
    docker buildx create --driver cloud technoboggle/production
    docker buildx use cloud-technoboggle-production
else
    # echo "BUILD_LOCALLY does not match any values in the match list"
    echo "Building locally"
    docker buildx create --name technoboggle_builder --use --bootstrap
    docker buildx use "technoboggle_builder"
fi

docker buildx bake -f env.hcl  -f docker-bake.hcl --no-cache --push

sed -i.bu -E 's/BUILD_DATE=".*"/BUILD_DATE=""/g' env.hcl
sed -i.bu -E 's/VCS_REF=".*"/VCS_REF=""/g' env.hcl
sed -i.bu -E 's/DOCKERCMD=".*"/DOCKERCMD=""/g' env.hcl

rm -f env.hcl.bu

echo "Running the container, using the following command:"
echo "  ${DOCKERCMD}"
echo
eval $DOCKERCMD

docker container stop -t 10 myphpfpm

echo "Switching back to builder: ${current_builder}"
docker buildx use "${current_builder}"
docker buildx rm technoboggle_builder

cd "$owd" || exit
