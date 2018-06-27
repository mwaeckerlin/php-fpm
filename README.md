Docker Image for PHP FPM service
================================

Runs on port 9000 to be connected to `mwaeckerin/nginx` and optional `mysql`, e.g,:

```
docker run -d --restart unless-stopped \
           --name php-instance \
           -v /path/to/serve:/var/www \
           --link mysql-instance:mysql
           mwaeckerlin/php-fpm
docker run -d --restart unless-stopped \
           --name nginx-instance «
           -v /path/to/serve:/var/lib/nginx/html \
           --link php-instance:php \
           mwaeckerlin/nginx
```