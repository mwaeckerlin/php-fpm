FROM mwaeckerlin/very-base as build
RUN ${PKG_INSTALL} php-fpm php-xml php-gd php-session php-json php-ldap php7-openssl php7-mysqli php7-imap php7-mbstring
RUN $ALLOW_USER /var/log/php7
COPY php-fpm.conf /etc/php7/php-fpm.conf
COPY www.conf /etc/php7/php-fpm.d/www.conf
RUN tar cp \
    /usr/lib/php7 /etc/php7 /var/log/php7 \
    $(which php-fpm7) \
    $(for f in $(which php-fpm7) /usr/lib/php7/modules/*; do \
    ldd $f | sed -n 's,.* => \([^ ]*\) .*,\1,p'; \
    done 2> /dev/null) 2> /dev/null \
    | tar xpC /root/
RUN tar cp \
    $(find /root -type l ! -exec test -e {} \; -exec echo -n "{} " \; -exec readlink {} \; | sed 's,/root\(.*\)/[^/]* \(.*\),\1/\2,') 2> /dev/null \
    | tar xpC /root/

FROM mwaeckerlin/scratch
WORKDIR /app
COPY --from=build /root /
EXPOSE 9000
ENTRYPOINT [ "/usr/sbin/php-fpm7", "-F", "-R" ]
