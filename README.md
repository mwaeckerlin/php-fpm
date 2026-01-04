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

The following Services are based on this image:
 - [mwaeckerlin/wordpress]
 - [mwaeckerln/mailservice]


## Usage in Own Projects

This is how e.g. the project [mwaeckerlin/wordpress] has been implementend:

An NGINX server Dockerfile is created plus a PHP-FPM Dockerfile, then they are connected and attached to a database in a docker-compose.yaml file. More details on the specficic usage see directly in [mwaeckerlin/wordpress], this documentation here is about *development* of *own* services based on these source images.

[mwaeckerlin/very-base] is a heavy weight build image based on Alpine and containing some helpful setups and variable definitions. Never bring it to production. I use it to prepare the software in image layers in the first build steps. Then in the final step, the produces outoput is copied to the final target in as few steps as possible to avoid unneeded layers and get smaller images.

### Wordpress NGINX Server

This is how I built [mwaeckerlin/wordpress-nginx], see there for all details.

First, starting from [mwaeckerlin/very-base] as build environment, copy the latest `wordpress` sources and extract them to `app` (in my images, sofware is always in `app`).

I remove all PHP files for security. All PHP files must be **present** in NGINX, but they don't need to be available, so I just set them to empty files. This way, NGINX knows that the files exist, even though it has no access to the content. This is additional security.

The user may upload files to `/app/wp-content`, so the definition `${ALLOW_USER}` allows the final user in the container to write the files in `wp-content`. `${ALLOW-USER}` is defined in [mwaeckerlin/scratch], see there for all available definitions. All my projects inherit the non privileged `${RUN_USER}` and some helpful definitions from there.

That's all! Inherit from [mwaeckerlin/nginx] and copy the build targets. All necessary settings, such as `CMD`, `ENV`, `USER`, `WORKDIR` are already defined in that base image.

```Dockerfile
FROM mwaeckerlin/very-base AS wordpress
WORKDIR /app
ADD https://wordpress.org/latest.tar.gz /tmp/wordpress.tar.gz
RUN tar xzf /tmp/wordpress.tar.gz --strip-components=1
RUN find . -name '*.php' -exec sh -c "rm {} && touch {}" \; # Remove all PHP files for security
RUN ${ALLOW_USER} wp-content

FROM mwaeckerlin/nginx
COPY --from=wordpress /app /app
```


### Wordpress PHP-FPM Server

This is how I built [mwaeckerlin/wordpress-php-fpm], see there for all details.

Then, again starting from [mwaeckerlin/very-base] as build environment, I do the exact same steps as above, because the file layout must be exactly the same. All files not needed by PHP are served from NGINX (that's why I can zero the PHP files there, but not here), where all PHP files and their dependencies come from this image. That's hoiw work is split between NGINX and PHP-FPM.

Here on the PHP backend, the run-user may not only write to `wp-content`, where external files are uploaded through the web browser, but configuration is written here. That's why I added `wp-secrets` as path to store salts and passwords that are internally created automatically, unless the user optionally specifies them in envoironment variables.

To achieve all this and to adapt runtime environment settings from `docker-compose.yaml` into the container, I created a [`wp-config.php`](https://github.com/mwaeckerlin/wordpress-php-fpm/blob/master/wp-config.php) file that reads the envioronment and uses the given variables or useful defaults at container start and handles the secrets file `wp-secrets/wp-secrets.php`. Therefore I don't need any entrypoint shell script. Since we don't have a shell, we cannot use shell scrips at all. This is an important security feature, since shell scripts in Docker containers are a high risk. An intruder in the container could use them to gain more access.

The secrets file is created at the very first run of the container. It then creates random default values for session and cookie secrets, as well as random salt for secrets. Therefore you should then store `wp-secrets` as well as `wp-content` in persistent volumes.

Also here, in the final step, I introduce all environment variables, copy the build targets from `/app` and that's it. Everything else, all the security, comes for free thank's to my well desiged base images.

```Dockerfile
FROM mwaeckerlin/very-base AS wordpress
WORKDIR /app
ADD https://wordpress.org/latest.tar.gz /tmp/wordpress.tar.gz
RUN tar xzf /tmp/wordpress.tar.gz --strip-components=1
RUN mkdir wp-secrets
RUN ${ALLOW_USER} wp-content wp-secrets
COPY wp-config.php wp-config.php

FROM mwaeckerlin/php-fpm
ENV WORDPRESS_DB_HOST "mysql"
ENV WORDPRESS_DB_PORT "3306"
ENV WORDPRESS_DB_NAME "wordpress"
ENV WORDPRESS_DB_USER "wordpress"
ENV WORDPRESS_DB_PASSWORD "wordpress"
ENV WORDPRESS_DB_CHARSET "utf8mb4"
ENV WORDPRESS_DB_COLLATE ""
ENV WORDPRESS_TABLE_PREFIX "wp_"
ENV WORDPRESS_AUTH_KEY "change-me"
ENV WORDPRESS_SECURE_AUTH_KEY "change-me"
ENV WORDPRESS_LOGGED_IN_KEY "change-me"
ENV WORDPRESS_NONCE_KEY "change-me"
ENV WORDPRESS_AUTH_SALT "change-me"
ENV WORDPRESS_SECURE_AUTH_SALT "change-me"
ENV WORDPRESS_LOGGED_IN_SALT "change-me"
ENV WORDPRESS_NONCE_SALT "change-me"
ENV WORDPRESS_HOME ""
ENV WORDPRESS_SITEURL ""
ENV WORDPRESS_DEBUG "false"
COPY --from=wordpress /app /app
```

### Composing Wordpress

Finally everything is glued together in a `docker-compose.yaml` file. You'll find a better, more secure example at [mwaeckerlin/wordpress]. Just here for the basics, without segregated networks:

The two Dockerfiles explained above correspond to [mwaeckerlin/wordpress-nginx] and [mwaeckerlin/wordpress-php-fpm] here.

Entrypoint to the outside world is [mwaeckerlin/wordpress-nginx], here mapped to port `8123`. That's the image build from the Dockerfile specified above. It must have an persitent volume to `wp-content`, and the same volume must be shared with [mwaeckerlin/wordpress-php-fpm], because they must see the same files, as explained above.

The PHP processes are driven by [mwaeckerlin/wordpress-php-fpm] which needs access to the same `wp-content` volume as well as to a persistent `wp-secrets` volume. Minimum definition is a secret SQL database password and the `WORDPRESS_DB_HOST` (if it's not `mysql`).

As database yo may connect e.g. [mysql] or [mariadb]. Others could work too, but may require changes in the `wp-config.php` (not tested). The database needs to be configured, here with password plus default values for the database and user name. The database also needs a persistant volume.

Since the user must be upload (therefore write) files at runtime to `wp-content` and `wp-secrets` must be written at first start, those volumes need to get write access. This is done by mounting them below `/app` in [mwaeckerlin/allow-write-access].

```yaml
services:
  wordpress-nginx:
    image: mwaeckerlin/wordpress-nginx
    ports:
      - "8123:8080"
    volumes:
      - wp-content:/app/wp-content

  wordpress-php-fpm:
    image: mwaeckerlin/wordpress-php-fpm
    environment:
      WORDPRESS_DB_PASSWORD: ThisIsMandaToryToBeSet
      WORDPRESS_DB_HOST: wordpress-db
    volumes:
      - wp-content:/app/wp-content
      - wp-secrets:/app/wp-secrets

  wordpress-db:
    image: mariadb
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: ThisIsMandaToryToBeSet
      MYSQL_RANDOM_ROOT_PASSWORD: yes
    volumes:
      - db-data:/var/lib/mysql
    networks:
      - db-network

  wp-access-fix:
    image: mwaeckerlin/allow-write-access
    volumes:
      - wp-content:/app/wp-content
      - wp-secrets:/app/wp-secrets

volumes:
  wp-content:
  wp-secrets:
  db-data:
```


[mwaeckerlin]: https://marc.wäckerlin.ch/privat/kontakt "contact author Marc Wäckerlin"
[mysql]: https://hub.docker.com/_/mysql "get the mysql image from docker hub"
[mariadb]: https://hub.docker.com/_/mariadb "get the mariadb image from docker hub"
[mwaeckerlin/php-fpm]: https://hub.docker.com/r/mwaeckerlin/php-fpm "get the image from docker hub"
[mwaeckerlin/nginx]: https://github.com/mwaeckerlin/nginx "see the sources and documentation in my github project"
[mwaeckerlin/very-base]: https://github.com/mwaeckerlin/very-base "see the sources and documentation in my github project"
[mwaeckerlin/scratch] https://github.com/mwaeckerlin/scratch "nearly empty scratch image, just with some users, groups and definitions that are always needed"
[mwaeckerlin/roundcube]: https://github.com/mwaeckerlin/roundcube "see the sources and documentation in my github project"
[fpm]: https://php-fpm.org/ "FastCGI Process Manager"
[mwaeckerlin/wordpress]: https://github.com/mwaeckerlin/wordpress "Secure Minimalistc Wordpress"
[mwaeckerlin/wordpress-nginx]: https://github.com/mwaeckerlin/wordpress-nginx "Secure Minimalistc Wordpress NGINX Server"
[mwaeckerlin/wordpress-fpm-php]: https://github.com/mwaeckerlin/wordpress-fpm-php "Secure Minimalistc Wordpress FPM-PHP Server"
[mwaeckerlin/allow-write-access]: https://github.com/mwaeckerlin/allow-write-access "Fix Write Access in a Docker Volume"
[mwaeckerln/mailservice]: https://github.com/mwaeckerlin/mailservice "Postfix Admin in my Mailservice Package"