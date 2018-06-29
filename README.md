Docker Image for PHP FPM service
================================

Runs PHP [FPM] service on port `9000` to be connected from [mwaeckerlin/nginx] and optionally connect to [mysql], e.g,:

```bash
docker run -d --restart unless-stopped \
           --name mysql-instance \
           mysql
docker run -d --restart unless-stopped \
           --name php-instance \
           -v /path/to/serve:/var/www \
           --link mysql-instance:mysql
           mwaeckerlin/php-fpm
docker run -d --restart unless-stopped \
           --name nginx-instance \
           -e WEB_ROOT_PATH=/var/www \
           -v /path/to/serve:/var/www \
           --link php-instance:php \
           mwaeckerlin/nginx
```

Ports
-----

PHP [FPM] service is vailable on port `9000`.


Environment Variables
---------------------

 - PHP related variables
    - `MEMORY_LIMIT` set memory limit, defaults to `128M`
    - `POST_MAX_SIZE` set maximum post size, must match to nginx configuration, defaults to `20M`
    - `UPLOAD_MAX_FILESIZE` set maximum size of uploaded files, must match to nginx configuration, defaults to `10M`
 - [FPM] server related variables
    - `MAX_CHILDREN` set maximum number of child processes, defaults to `20`


Data Path
---------

Data path is given by the [mwaeckerlin/nginx] web root path. So [mwaeckerlin/nginx] and [mwaeckerlin/php-fpm] should mount the same web application path to the same location. Another possibility is to mount PHP file only to [mwaeckerlin/php-fpm] and html and other static files only to [mwaeckerlin/nginx].


MySQL
-----

A [mysql] instance or any other database can be linked as, e.g. `mysql`, respectively, so as a convention, the hostname of the [mysql] server shall be `mysql`. But since you will have to configure MySQL in your PHP application, it can be anything else, as long as it is correctly configured. So details depend on the usage.


Build Arguments
---------------

At build, PHP version can be chosen using `phpversion` which defaults to `7`. Theoretically, `5` would be possible too, but that's not yet fully supported. Contact [mwaeckerlin] if you need it.



[mwaeckerlin]:         https://marc.wäckerlin.ch/privat/kontakt     "contact author Marc Wäckerlin"
[mysql]:               https://hub.docker.com/_/mysql               "get the image from docker hub"
[mwaeckerlin/php-fpm]: https://hub.docker.com/r/mwaeckerlin/php-fpm "get the image from docker hub"
[mwaeckerlin/nginx]:   https://hub.docker.com/r/mwaeckerlin/nginx   "get the image from docker hub"
[FPM]:                 https://php-fpm.org/                         "FastCGI Process Manager"
