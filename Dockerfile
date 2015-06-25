FROM ubuntu
MAINTAINER mwaeckerlin

RUN apt-get update -y          
RUN apt-get install -y php5-fpm php5-mysql
RUN sed -i 's/^listen *=.*/listen = 9000/' /etc/php5/fpm/pool.d/www.conf
#RUN echo "clear_env = no" >> /etc/php5/fpm/php-fpm.conf

EXPOSE 9000
CMD env | sed "/LS_COLORS/d;s/\([^=]*\)=\(.*\)/env['\1']='\2'/" > /etc/php5/fpm/pool.d/env.conf && php5-fpm -F
