FROM mwaeckerlin/very-base AS build
RUN ${PKG_INSTALL} php-fpm php-xml php-gd php-session php-json php-ldap php-openssl php-mysqli php-imap php-mbstring
RUN $ALLOW_USER /var/log/php* /tmp
RUN mv /usr/sbin/php-fpm$(ls -d /var/log/php* | sed 's,/var/log/php,,') /usr/sbin/php-fpm
RUN mv /etc/php$(ls -d /var/log/php* | sed 's,/var/log/php,,') /etc/php
COPY php-fpm.conf /etc/php/php-fpm.conf
COPY www.conf /etc/php/php-fpm.d/www.conf
COPY php.ini /etc/php/php.ini
RUN mv /etc/php /etc/php$(ls -d /var/log/php* | sed 's,/var/log/php,,')
RUN tar cph \
    /usr/lib/php* /etc/php* /var/log/php* /tmp \
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
