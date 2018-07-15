Docker Image for Ngingx and PHP
===============================

Implements [mwaeckerlin/nginx], adds PHP [FPM] and optionally connect to [mysql]. Used to serve a PHP project.


Ports
-----

Port `8080` exposes a full nginx PHP service.

PHP [FPM] service internally uses port `9000`. This port should not be exposed.


Configuration
-------------

Configuration is done with the following environment variables:

 - [FPM] server related variables:

    - `MEMORY_LIMIT`: Maximum amount of memory a script may allocate, e.g. `128M`, should be larher than `POST_MAX_SIZE`. Defaults to `-1` (no limit).
    
    - `POST_MAX_SIZE`: Maximum size of POST data, must be larger than `UPLOAD_MAX_FILESIZE`, e.g. `20M`. Defaults to `0` (no check).
    
    - `MAX_CHILDREN`: Set maximum number of child processes, defaults to `20`.
    
    - `UPLOAD_MAX_FILESIZE`: Set maximum size of uploaded files. Defaults to `4G`.
    
 - PHP related variables (see also [mwaeckerlin/nginx]):

    - `WEB_ROOT_PATH`: Sets the path to the web files, defaults to `/var/www`.
 
    - `WEB_ROOT`: Path in the url, e.g. to access nginx on http://localhost:8080/mypath, set `-e ENV_WEB_ROOT=/mypath`. Defaults to `/`.
 
    - `MAX_BODY_SIZE`: Set maximum size of http client request body, defaults to `0` (no check).
 
    - `AUTOINDEX`: Flag whether a directory index should be created automatically when no index file exists. Default: `off`.
 
    - `ERROR_PAGE`: Optional rules to setup an error page. Empty by default.
 
    - `LOCATION_ROOT_RULES`: Optional additional rules that are copied inside the location rule. Empty by default.


Data Path
---------

The files in `WEB_ROOT_PATH` are served by the webserver. You can either copy your web application data there, mount a volume to `WEB_ROOT_PATH` or set a different `WEB_ROOT_PATH` and provide your web application data there.


MySQL
-----

A [mysql] instance or any other database can be linked as, e.g. `mysql`, respectively, so as a convention, the hostname of the [mysql] server shall be `mysql`. But since you will have to configure MySQL in your PHP application, it can be anything else, as long as it is correctly configured. So details depend on the usage.


Build Arguments
---------------

At build, PHP version can be chosen using `phpversion` which defaults to `7`. Theoretically, `5` would be possible too, but that's not yet fully supported. Contact [mwaeckerlin] or open a ticket if you need it.


Examples
--------


### Inherit And Add Data

The image [mwaeckerlin/roundcube] just inherits from this [mwaeckerlin/php-fpm] image and adds the Roundcube web application. Have a look on that project to see, wo easy you can create a web application from this image.


### Web Application With MySQL Database

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



[mwaeckerlin]:           https://marc.wäckerlin.ch/privat/kontakt     "contact author Marc Wäckerlin"
[mysql]:                 https://hub.docker.com/_/mysql               "get the image from docker hub"
[mwaeckerlin/php-fpm]:   https://hub.docker.com/r/mwaeckerlin/php-fpm "get the image from docker hub"
[mwaeckerlin/nginx]:     https://hub.docker.com/r/mwaeckerlin/nginx   "get the image from docker hub"
[mwaeckerlin/roundcube]: https://hub.docker.com/r/mwaeckerlin/nginx   "get the image from docker hub"
[FPM]:                   https://php-fpm.org/                         "FastCGI Process Manager"
