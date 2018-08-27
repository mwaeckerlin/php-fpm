FROM mwaeckerlin/nginx
MAINTAINER mwaeckerlin
ARG phpversion="7"

ENV MEMORY_LIMIT -1
ENV POST_MAX_SIZE 0
ENV MAX_CHILDREN 20
ENV UPLOAD_MAX_FILESIZE 4G
ENV WEB_ROOT_PATH /var/www

ENV CONTAINERNAME="php-fpm"
ENV VPHP "$phpversion"
USER root
ADD start.sh /start.sh
ADD index.php ${WEB_ROOT_PATH}/index.php
RUN apk add php${VPHP}-fpm \
 && sed -i '/user = nobody/d' /etc/php${VPHP}/php-fpm.d/www.conf \
 && sed -i '/group = nobody/d' /etc/php${VPHP}/php-fpm.d/www.conf \
 && sed -i 's/^listen *=.*/listen = 9000/' /etc/php${VPHP}/php-fpm.d/www.conf \
 && echo "catch_workers_output = yes" >> /etc/php${VPHP}/php-fpm.d/www.conf \
 && echo "access.log = /proc/1/fd/1" >> /etc/php${VPHP}/php-fpm.d/www.conf \
 && echo "php_flag[display_errors] = on" >> /etc/php${VPHP}/php-fpm.d/www.conf \
 && echo "php_admin_value[error_log] = /proc/1/fd/2" >> /etc/php${VPHP}/php-fpm.d/www.conf \
 && echo "php_admin_flag[log_errors] = on" >> /etc/php${VPHP}/php-fpm.d/www.conf \
 && echo 'include_path = ".:/usr/share/php${VPHP}:/usr/share/php${VPHP}/PEAR"' >> /etc/php${VPHP}/php.ini \
 && sed -i 's,.*error_log = .*,error_log = /proc/1/fd/2,' /etc/php${VPHP}/php-fpm.conf \
 && sed -i 's/display_errors = .*/display_errors = stderr/' /etc/php${VPHP}/php.ini \
 && mkdir /run/php \
 && chown -R $WWWUSER /run/php /etc/php${VPHP}
USER $WWWUSER
