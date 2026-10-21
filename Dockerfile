ARG PHP_IMAGE=php:fpm-alpine
FROM ${PHP_IMAGE} AS build
RUN apk upgrade --no-cache --purge --clean-protected
# PHP modules, override at build time to reduce / extend.
ARG PHP_MODULES="apcu bcmath exif gd gmp imagick intl ldap mysqli pdo_mysql sysvsem zip"
ADD --chmod=0755 --checksum=sha256:3f49c71fa66c79b8b2b96bc0ce92885dafd7946f3b5a46f545b390d6f1617e2c \
    https://github.com/mlocati/docker-php-extension-installer/releases/download/2.12.0/install-php-extensions \
    /usr/local/bin/install-php-extensions
# PHP's Makefile has a variable PHP_MODULES of its own; pecl.php.net times out under load
RUN modules="${PHP_MODULES}" && unset PHP_MODULES \
    && for attempt in 1 2 3 4 5 6 7 8 9 10; do install-php-extensions ${modules} && exit 0; sleep 90; done; exit 1
RUN case " $PHP_MODULES " in *" imagick "*) apk add --no-cache imagemagick-svg librsvg ;; esac
RUN rm -f /usr/local/etc/php-fpm.d/*.conf /usr/local/etc/php-fpm.conf.default
COPY php-fpm.conf /usr/local/etc/php-fpm.conf
COPY www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php.ini /usr/local/etc/php/php.ini
RUN ln -s /usr/local/sbin/php-fpm /usr/sbin/php-fpm && ln -s /usr/local/bin/php /usr/bin/php
RUN tar cph \
    /usr/local/sbin/php-fpm /usr/local/bin/php /usr/local/lib/php /usr/local/etc/php \
    /usr/local/etc/php-fpm.conf /usr/local/etc/php-fpm.d /tmp \
    /etc/ssl/certs /etc/ssl/cert.pem /etc/ssl/openssl.cnf /etc/ssl/ct_log_list.cnf /usr/share/icu \
    /usr/share/ImageMagick* /etc/ImageMagick* /usr/lib/ImageMagick* \
    /etc/fonts /usr/share/fontconfig \
    $(for f in /usr/local/sbin/php-fpm /usr/local/bin/php /usr/local/lib/php/extensions/*/*.so /usr/lib/ImageMagick*/modules*/coders/*.so; do \
    ldd $f | sed -n 's,.* => \([^ ]*\) .*,\1,p'; \
    done 2> /dev/null) 2> /dev/null \
    | tar xpC /root/
RUN tar cp /usr/sbin/php-fpm /usr/bin/php | tar xpC /root/

FROM mwaeckerlin/scratch
ENV CONTAINERNAME="php-fpm"
WORKDIR /app
EXPOSE 9000
# no -R: the image runs as ${RUN_USER}; refusing to start as root is intended
ENTRYPOINT [ "/usr/sbin/php-fpm", "-F", "-O" ]
COPY --from=build /root /
