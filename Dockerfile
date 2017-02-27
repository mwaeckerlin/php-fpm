FROM ubuntu
MAINTAINER mwaeckerlin
ENV TERM xterm

ENV MEMORY_LIMIT 128M
ENV POST_MAX_SIZE 20M
ENV UPLOAD_MAX_FILESIZE 10M
VOLUME /usr/share/nginx/html

RUN apt-get update -y          
RUN apt-get install -y php-fpm php-patchwork-utf8 php-mbstring php-mysqlnd php-gnupg php-ldap mysql-client
RUN sed -i 's/^listen *=.*/listen = 9000/' /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i 's,^.*access.log *=.*,access.log = /proc/self/fd/1,' /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i 's,^.*error_log *=.*,error_log = /proc/self/fd/2,' /etc/php/7.0/fpm/php-fpm.conf
RUN echo "catch_workers_output = yes" >>  /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i 's,\(memory_limit *= *\).*,\1'${MEMORY_LIMIT}',' /etc/php/7.0/fpm/php.ini
RUN sed -i 's,\(post_max_size *= *\).*,\1'${POST_MAX_SIZE}',' /etc/php/7.0/fpm/php.ini
RUN sed -i 's,\(upload_max_filesize *= *\).*,\1'${UPLOAD_MAX_FILESIZE}',' /etc/php/7.0/fpm/php.ini
RUN mkdir /run/php

EXPOSE 9000
CMD ( echo "[www]"; env | sed -n "s/\([^=]*\)=\(.*\)/env[\1]='\2'/p" ) > /etc/php/7.0/fpm/pool.d/env.conf && php-fpm7.0 -F
