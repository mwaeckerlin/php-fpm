FROM mwaeckerlin/very-base as build
RUN ${PKG_INSTALL} php-fpm php-xml php-gd php-session php-json php-ldap php-openssl php-mysqli php-imap php-mbstring
ARG PHP_VERSION=81
RUN $ALLOW_USER /var/log/php${PHP_VERSION} /tmp
RUN mv /usr/sbin/php-fpm${PHP_VERSION} /usr/sbin/php-fpm
COPY php-fpm.conf /etc/php${PHP_VERSION}${PHP_VERSION}/php-fpm.conf
COPY www.conf /etc/php${PHP_VERSION}/php-fpm.d/www.conf
COPY php.ini /etc/php${PHP_VERSION}/php.ini
RUN tar cph \
    /usr/lib/php${PHP_VERSION} /etc/php${PHP_VERSION} /var/log/php${PHP_VERSION} /tmp \
    /usr/sbin/php-fpm \
    $(for f in /usr/sbin/php-fpm /usr/lib/php${PHP_VERSION}/modules/*; do \
    ldd $f | sed -n 's,.* => \([^ ]*\) .*,\1,p'; \
    done 2> /dev/null) 2> /dev/null \
    | tar xpC /root/

FROM mwaeckerlin/scratch
WORKDIR /app
EXPOSE 9000
ENTRYPOINT [ "/usr/sbin/php-fpm", "-F", "-R" ]
COPY --from=build /root /
