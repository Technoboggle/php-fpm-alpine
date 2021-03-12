#####################################################################
# use the following commands to build image and upload to dockerhub #
```
#####################################################################


# Setting File permissions
xattr -c .git
xattr -c *
chmod 0666 *
chmod 0777 *.sh
chmod 0777 docker-php-entrypoint
chmod 0777 docker-php-ext-configure
chmod 0777 docker-php-ext-enable
chmod 0777 docker-php-ext-install
chmod 0777 docker-php-source

docker build -f build-php.Dockerfile -t technoboggle/php-fpm-alpine:8.0.0-3.13.2 .
docker run -it -d -p 8000:80 --rm --name myphp-fpm technoboggle/php-fpm-alpine:8.0.0-3.13.2
docker tag technoboggle/php-fpm-alpine:8.0.0-3.13.2 technoboggle/php-fpm-alpine:8.0.0-3.13.2
docker tag technoboggle/php-fpm-alpine:8.0.0-3.13.2 technoboggle/php-fpm-alpine:latest
docker login
docker push technoboggle/php-fpm-alpine:8.0.0-3.13.2
docker push technoboggle/php-fpm-alpine:latest
docker container stop -t 10 myphp-fpm
#####################################################################
```
