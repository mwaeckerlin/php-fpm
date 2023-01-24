FROM mwaeckerlin/very-base as build
RUN ${PKG_INSTALL} php-fpm php-xml php-gd php-session php-json php-ldap php-openssl php-mysqli php-imap php-mbstring
RUN echo /var/log/php81
RUN $ALLOW_USER /var/log/php81 /tmp
COPY php-fpm.conf /etc/php8181/php-fpm.conf
COPY www.conf /etc/php81/php-fpm.d/www.conf
COPY php.ini /etc/php81/php.ini
RUN tar cph \
    /usr/lib/php81 /etc/php81 /var/log/php81 /tmp \
    $(which php-fpm81) \
    $(for f in $(which php-fpm81) /usr/lib/php81/modules/*; do \
    ldd $f | sed -n 's,.* => \([^ ]*\) .*,\1,p'; \
    done 2> /dev/null) 2> /dev/null \
    | tar xpC /root/

FROM mwaeckerlin/scratch
WORKDIR /app
EXPOSE 9000
ENTRYPOINT [ "/usr/sbin/php-fpm81", "-F", "-R" ]
COPY --from=build /root /
