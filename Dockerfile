FROM mwaeckerlin/ubuntu-base
MAINTAINER mwaeckerlin

ENV MEMORY_LIMIT 128M
ENV POST_MAX_SIZE 20M
ENV UPLOAD_MAX_FILESIZE 10M
ENV WEB_ROOT_PATH /var/www

RUN apt-get update && apt-get install -y php-fpm php-patchwork-utf8 php-mbstring php-imagick php-mysqlnd php-gnupg php-ldap mysql-client
RUN sed -i 's/^listen *=.*/listen = 9000/' /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i 's,^.*access.log *=.*,access.log = /proc/self/fd/1,' /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i 's,^.*error_log *=.*,error_log = /proc/self/fd/2,' /etc/php/7.0/fpm/php-fpm.conf
RUN echo "catch_workers_output = yes" >>  /etc/php/7.0/fpm/pool.d/www.conf

RUN mkdir /run/php
ADD start.php-fpm.sh /start.php-fpm.sh

EXPOSE 9000
CMD /start.php-fpm.sh
