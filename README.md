# Docker Image for serving PHP

This image is about 34.1MB in size and has no shell, so it is small, fast and secure.

Serves PHP 8.1 [FPM] when attached to [mwaeckerlin/nginx] and optionally connects to [mysql]. Used to serve a PHP project.

## Ports

Port `9000` exposes PHP-FPM. This port should not be exposed.

## Configuration

Mount the same PHP apllication directory to [mwaeckerlin/nginx] and [mwaeckerlin/php-fpm] in path `/app`.

See `docker-compose.yml` for a simple example:

- run `docker-compose build` to build the example
- run `docker-compose up` to start the example
- browse to [http://localhost:8080/] to view the example
- stop with key `ctrl+c`

## MySQL

A [mysql] instance or any other database can be linked as, e.g. `mysql`, respectively, so as a convention, the hostname of the [mysql] server shall be `mysql`. But since you will have to configure MySQL in your PHP application, it can be anything else, as long as it is correctly configured. So details depend on the usage.

[mwaeckerlin]: https://marc.wäckerlin.ch/privat/kontakt "contact author Marc Wäckerlin"
[mysql]: https://hub.docker.com/_/mysql "get the image from docker hub"
[mwaeckerlin/php-fpm]: https://hub.docker.com/r/mwaeckerlin/php-fpm "get the image from docker hub"
[mwaeckerlin/nginx]: https://hub.docker.com/r/mwaeckerlin/nginx "get the image from docker hub"
[mwaeckerlin/roundcube]: https://hub.docker.com/r/mwaeckerlin/roundcube "get the image from docker hub"
[fpm]: https://php-fpm.org/ "FastCGI Process Manager"
