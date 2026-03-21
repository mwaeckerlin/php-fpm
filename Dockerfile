FROM mwaeckerlin/very-base AS build
# PHP modules, override at build time to reduce / extend.
ARG PHP_MODULES="php-apcu php-bcmath php-curl php-dom php-exif php-fileinfo php-gd php-gmp php-iconv php-imagick php-imap php-intl php-json php-ldap php-mbstring php-mysqli php-opcache php-openssl php-pdo_mysql php-session php-xml php-zip"
RUN ${PKG_INSTALL} php-fpm ${PHP_MODULES}
# work around bug in php-imagick → wrong / missing dependencies
RUN if [[ "$PHP_MODULES" =~ php-imagick ]]; then \
    ${PKG_INSTALL} php$(ls -d /var/log/php* | sed 's,/var/log/php,,')-pecl-imagick; \
    fi
RUN $ALLOW_USER /var/log/php* /tmp
RUN mv /usr/sbin/php-fpm$(ls -d /var/log/php* | sed 's,/var/log/php,,') /usr/sbin/php-fpm
RUN mv /etc/php$(ls -d /var/log/php* | sed 's,/var/log/php,,') /etc/php
COPY php-fpm.conf /etc/php/php-fpm.conf
COPY www.conf /etc/php/php-fpm.d/www.conf
COPY php.ini /etc/php/php.ini
RUN mv /etc/php /etc/php$(ls -d /var/log/php* | sed 's,/var/log/php,,')
RUN tar cph \
    /usr/lib/php* /etc/php* /var/log/php* /tmp \
    /etc/ssl/certs /usr/share/icu \
    /usr/share/ImageMagick* /etc/ImageMagick* /usr/lib/ImageMagick* \
    /etc/fonts /usr/share/fontconfig \
    /usr/sbin/php-fpm \
    $(for f in /usr/sbin/php-fpm /usr/lib/php*/modules/*; do \
    ldd $f | sed -n 's,.* => \([^ ]*\) .*,\1,p'; \
    done 2> /dev/null) 2> /dev/null \
    | tar xpC /root/

FROM mwaeckerlin/scratch
WORKDIR /app
EXPOSE 9000
ENTRYPOINT [ "/usr/sbin/php-fpm", "-F", "-R" ]
COPY --from=build /root /
