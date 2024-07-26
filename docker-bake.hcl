# docker-bake.hcl
group "default" {
    targets = ["app"]
}

target "app" {
    context = "."
    dockerfile = "Dockerfile"
    tags = ["technoboggle/php-fpm-alpine:${PHP_VERSION}-${ALPINE_VERSION}", "technoboggle/php-fpm-alpine:${PHP_VERSION}", "technoboggle/php-fpm-alpine:latest"]
    args = {
        ALPINE_VERSION = "${ALPINE_VERSION}"
        PHP_VERSION = "${PHP_VERSION}"

        MAINTAINER = "${MAINTAINER}"
        AUTHORNAME = "${AUTHORNAME}"
        AUTHORS = "${AUTHORS}"
        VERSION = "${VERSION}"

        SCHEMAVERSION = "${SCHEMAVERSION}"
        NAME = "${NAME}"
        DESCRIPTION = "${DESCRIPTION}"
        URL = "${URL}"
        VCS_URL = "${VCS_URL}"
        BUILD_LOCALLY = "${BUILD_LOCALLY}"
        VENDOR = "${VENDOR}"
        BUILDVERSION = "${BUILD_VERSION}"
        BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    }
    #platforms = ["linux/amd64", "linux/arm64"]
    # platforms = ["linux/amd64", "linux/arm/v6", "linux/arm/v7", "linux/arm64/v8", "linux/arm64", "linux/armhf", "linux/386", "linux/ppc64le"]
    platforms = ["linux/arm/v6","linux/arm/v7","linux/arm64/v8","linux/amd64","linux/386","linux/s390x","linux/ppc64le"]
    push = true
    cache = false
    progress = "plain"
}
