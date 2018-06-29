FROM mwaeckerlin/nginx
MAINTAINER mwaeckerlin
ARG phpversion="7"

ENV MEMORY_LIMIT 128M
ENV POST_MAX_SIZE 20M
ENV MAX_CHILDREN 20
ENV UPLOAD_MAX_FILESIZE 10M
ENV WEB_ROOT_PATH /var/www

ARG php5pkgs="php5 php5-pgsql php5-zip php5-cgi php5-embed php5-xmlrpc php5-dbg php5-sysvshm php5-mysql php5-imap php5-doc php5-zlib php5-calendar php5-pdo_dblib php5-dba php5-mysqli php5-odbc php5-soap php5-shmop php5-wddx php5-cli php5-suhosin php5-fpm php5-phpdbg php5-bz2 php5-sockets php5-pdo_mysql php5-sysvmsg php5-pspell php5-iconv php5-dev php5-ftp php5-gettext php5-mssql php5-mcrypt php5-exif php5-xmlreader php5-gd php5-xml php5-pcntl php5-pear php5-pdo_pgsql php5-phar php5-apcu php5-ctype php5-intl php5-pdo php5-openssl php5-common php5-sysvsem php5-posix php5-pdo_sqlite php5-dom php5-curl php5-xsl php5-ldap php5-pdo_odbc php5-json php5-enchant php5-bcmath php5-opcache php5-sqlite3 php5-gmp php5-snmp"

ARG php7pkgs="php7-intl php7-openssl php7-dba php7-sqlite3 php7-pear php7-tokenizer php7-phpdbg xapian-bindings-php7 php7-litespeed php7-gmp php7-pdo_mysql php7-pcntl php7-common php7-oauth php7-xsl php7 php7-fpm php7-imagick php7-mysqlnd php7-enchant php7-pspell php7-redis php7-snmp php7-doc php7-fileinfo php7-mbstring php7-dev php7-pear-mail_mime php7-xmlrpc php7-embed php7-xmlreader php7-pear-mdb2_driver_mysql php7-pdo_sqlite php7-pear-auth_sasl2 php7-exif php7-recode php7-opcache php7-ldap php7-posix php7-pear-net_socket php7-session php7-gd php7-gettext php7-mailparse php7-json php7-xml php7-iconv php7-sysvshm php7-curl php7-shmop php7-odbc php7-phar php7-pdo_pgsql php7-imap php7-pear-mdb2_driver_pgsql php7-pdo_dblib php7-pgsql php7-pdo_odbc php7-xdebug php7-zip php7-cgi php7-ctype php7-amqp php7-mcrypt php7-wddx php7-pear-net_smtp php7-bcmath php7-calendar php7-tidy php7-dom php7-sockets php7-zmq php7-memcached php7-soap php7-apcu php7-sysvmsg php7-imagick-dev php7-ssh2 php7-ftp php7-sysvsem php7-pear-net_idna2 php7-pdo php7-pear-auth_sasl php7-bz2 php7-mysqli php7-pear-net_smtp-doc php7-simplexml php7-xmlwriter"

ENV CONTAINERNAME="php-fpm"
ENV VPHP "$phpversion"
USER root
ADD start.sh /start.sh
RUN apk add php${VPHP}-fpm $( \
        if test ${VPHP} -eq 5; then \
          echo $php5pkgs; \
        elif test ${VPHP} -eq 7; then \
          echo $php7pkgs; \
        fi) && \
    sed -i '/user = nobody/d' /etc/php7/php-fpm.d/www.conf && \
    sed -i '/group = nobody/d' /etc/php7/php-fpm.d/www.conf && \
    sed -i 's/^listen *=.*/listen = 9000/' /etc/php7/php-fpm.d/www.conf && \
    echo "catch_workers_output = yes" >> /etc/php7/php-fpm.d/www.conf && \
    echo "access.log = /proc/1/fd/1" >> /etc/php7/php-fpm.d/www.conf && \
    echo "php_flag[display_errors] = on" >> /etc/php7/php-fpm.d/www.conf && \
    echo "php_admin_value[error_log] = /proc/1/fd/2" >> /etc/php7/php-fpm.d/www.conf && \
    echo "php_admin_flag[log_errors] = on" >> /etc/php7/php-fpm.d/www.conf && \
    echo 'include_path = ".:/usr/share/php7:/usr/share/php7/PEAR"' >> /etc/php7/php.ini && \
    sed -i 's,.*error_log = .*,error_log = /proc/1/fd/2,' /etc/php7/php-fpm.conf && \
    sed -i '/display_errors = .*/display_errors = stderr/' /etc/php7/php.ini && \
    mkdir /run/php && \
    chown -R $WWWUSER /run/php /etc/php7
USER $WWWUSER
