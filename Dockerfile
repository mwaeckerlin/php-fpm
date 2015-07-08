FROM ubuntu
MAINTAINER mwaeckerlin

ENV MEMORY_LIMIT 128M
ENV POST_MAX_SIZE 20M
ENV UPLOAD_MAX_FILESIZE 10M

RUN apt-get update -y          
RUN apt-get install -y php5-fpm php5-mysqlnd php5-gnupg
RUN sed -i 's/^listen *=.*/listen = 9000/' /etc/php5/fpm/pool.d/www.conf
RUN sed -i 's,^.*access.log *=.*,access.log = /var/log/php5-fpm.log,' /etc/php5/fpm/pool.d/www.conf
RUN echo "catch_workers_output = yes" >>  /etc/php5/fpm/pool.d/www.conf
RUN sed -i 's,\(memory_limit *= *\).*,\1'${MEMORY_LIMIT}',' /etc/php5/fpm/php.ini
RUN sed -i 's,\(post_max_size *= *\).*,\1'${POST_MAX_SIZE}',' /etc/php5/fpm/php.ini
RUN sed -i 's,\(upload_max_filesize *= *\).*,\1'${UPLOAD_MAX_FILESIZE}',' /etc/php5/fpm/php.ini

EXPOSE 9000
CMD ( echo "[www]"; env | sed -n "/MYSQL/{s/\([^=]*\)=\(.*\)/env[\1]='\2'/p}" ) > /etc/php5/fpm/pool.d/env.conf && php5-fpm -F
