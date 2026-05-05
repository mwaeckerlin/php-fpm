FROM mwaeckerlin/very-base AS build
# PHP modules, override at build time to reduce / extend.
ARG PHP_MODULES="php-apcu php-bcmath php-ctype php-curl php-dom php-exif php-fileinfo php-gd php-gmp php-iconv php-imagick php-imap php-intl php-json php-ldap php-mbstring php-mysqli php-opcache php-openssl php-pdo_mysql php-posix php-session php-simplexml php-sodium php-xml php-xmlreader php-xmlwriter php-zip"
RUN ${PKG_INSTALL} php-fpm ${PHP_MODULES}
RUN PHP_VERSION="$(ls -d /var/log/php* | sed 's,/var/log/php,,')" && \
    ${PKG_INSTALL} "php${PHP_VERSION}-pecl-apcu" "php${PHP_VERSION}-sysvsem"
# work around bug in php-imagick → wrong / missing dependencies
RUN if [[ "$PHP_MODULES" =~ php-imagick ]]; then \
    ${PKG_INSTALL} php$(ls -d /var/log/php* | sed 's,/var/log/php,,')-pecl-imagick imagemagick-svg librsvg; \
    fi
RUN $ALLOW_USER /var/log/php* /tmp
RUN mv /usr/sbin/php-fpm$(ls -d /var/log/php* | sed 's,/var/log/php,,') /usr/sbin/php-fpm
RUN mv /etc/php$(ls -d /var/log/php* | sed 's,/var/log/php,,') /etc/php
COPY php-fpm.conf /etc/php/php-fpm.conf
COPY www.conf /etc/php/php-fpm.d/www.conf
COPY php.ini /etc/php/php.ini
RUN mv /etc/php /etc/php$(ls -d /var/log/php* | sed 's,/var/log/php,,')
RUN tar cph \
    /usr/lib/php* /etc/php$(ls -d /var/log/php* | sed 's,/var/log/php,,') /var/log/php* /tmp \
    /etc/ssl/certs /etc/ssl/openssl.cnf /etc/ssl/ct_log_list.cnf /usr/share/icu \
    /usr/share/ImageMagick* /etc/ImageMagick* /usr/lib/ImageMagick* \
    /etc/fonts /usr/share/fontconfig \
    /usr/sbin/php-fpm \
    $(for f in /usr/sbin/php-fpm /usr/lib/php*/modules/* /usr/lib/ImageMagick*/modules*/coders/*.so; do \
    ldd $f | sed -n 's,.* => \([^ ]*\) .*,\1,p'; \
    done 2> /dev/null) 2> /dev/null \
    | tar xpC /root/

FROM mwaeckerlin/scratch
WORKDIR /app
EXPOSE 9000
ENTRYPOINT [ "/usr/sbin/php-fpm", "-F", "-R", "-O" ]
COPY --from=build /root /
