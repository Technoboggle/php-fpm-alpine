#####################################################################
# use the following commands to build image and upload to dockerhub #
```
#####################################################################


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

# Get extenstion installer if missing ot not recent version
curl -sSLf -o install-php-extensions https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions
chmod +x install-php-extensions


#continueing with build
docker build -f Dockerfile -t technoboggle/php-fpm-alpine:8.1.8-3.15 --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') --build-arg VCS_REF=7aa4f4fed2822afd7ae0f083526aaba6ea502ca9 --build-arg BUILD_VERSION=0.05 --no-cache --progress=plain .

in the above pay special attenttion to the values to be updated which are:
  7aa4f4fed2822afd7ae0f083526aaba6ea502ca9  = git commit SHA key (this can be found with: git rev-parse --verify HEAD )
  0.05                                      = current version of this image


docker run -it -d -p 8000:80 --rm --name myphp-fpm technoboggle/php-fpm-alpine:7.4.28-3.15
docker tag technoboggle/php-fpm-alpine:7.4.28-3.15 technoboggle/php-fpm-alpine:7.4.28-3.15
docker tag technoboggle/php-fpm-alpine:7.4.28-3.15 technoboggle/php-fpm-alpine:latest
docker login
docker push technoboggle/php-fpm-alpine:7.4.28-3.15
docker push technoboggle/php-fpm-alpine:latest
docker container stop -t 10 myphp-fpm
#####################################################################
```
docker image prune --filter label=stage=builder

