# Minimalistic Secure Docker Image for PHP Server

This image is about 39.7MB in size and has no shell, so it is small, fast and secure.

Serves PHP [FPM] when attached to [mwaeckerlin/nginx] and optionally connects to [mysql]. Used to serve a PHP project.

This is the most lean and secure image for PHP servers:
 - extremely small size, minimalistic dependencies
 - no shell, only the server command
 - small attack surface
 - starts as non root user

## Ports

Port `9000` exposes PHP-FPM. This port should not be exposed.

## Configuration

Mount or fill in the same PHP application directory to [mwaeckerlin/nginx] and [mwaeckerlin/php-fpm] at `/app` (e.g. a volume on `/app/wp-content` for WordPress). Both containers need the same mount so uploads/plugins/theme files stay consistent.

See `docker-compose.yml` for a simple example:

- run `docker-compose build` to build the example
- run `docker-compose up` to start the example
- browse to [http://localhost:8080/] to view the example
- stop with key `ctrl+c`

## MySQL

A [mysql] instance or any other database can be linked as, e.g. `mysql`, respectively, so as a convention, the hostname of the [mysql] server shall be `mysql`. But since you will have to configure MySQL in your PHP application, it can be anything else, as long as it is correctly configured. So details depend on the usage.

## Examples

The following Services are based on thois image:
 - [mwaeckerlin/wordpress]
 - [mwaeckerln/mailservice]


[mwaeckerlin]: https://marc.wäckerlin.ch/privat/kontakt "contact author Marc Wäckerlin"
[mysql]: https://hub.docker.com/_/mysql "get the image from docker hub"
[mwaeckerlin/php-fpm]: https://hub.docker.com/r/mwaeckerlin/php-fpm "get the image from docker hub"
[mwaeckerlin/nginx]: https://hub.docker.com/r/mwaeckerlin/nginx "get the image from docker hub"
[mwaeckerlin/roundcube]: https://hub.docker.com/r/mwaeckerlin/roundcube "get the image from docker hub"
[fpm]: https://php-fpm.org/ "FastCGI Process Manager"
[mwaeckerlin/wordpress]: https://github.com/mwaeckerlin/wordpress "Secure Minimalistc Wordpress"
[mwaeckerln/mailservice]: https://github.com/mwaeckerlin/mailservice "Postfix Admin in my Mailservice Package"