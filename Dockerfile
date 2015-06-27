FROM ubuntu
MAINTAINER mwaeckerlin

RUN apt-get update -y          
RUN apt-get install -y php5-fpm php5-mysqlnd
RUN sed -i 's/^listen *=.*/listen = 9000/' /etc/php5/fpm/pool.d/www.conf
RUN sed -i 's,^.*access.log *=.*,access.log = /var/log/php5-fpm.log,' /etc/php5/fpm/pool.d/www.conf
RUN echo "catch_workers_output = yes" >>  /etc/php5/fpm/pool.d/www.conf

EXPOSE 9000
CMD ( echo "[www]"; env | sed -n "/MYSQL/{s/\([^=]*\)=\(.*\)/env[\1]='\2'/p}" ) > /etc/php5/fpm/pool.d/env.conf && php5-fpm -F
