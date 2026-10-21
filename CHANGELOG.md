# Changelog

- 2026-10-22 **1.2.10**
    - The PHP limits and the number of PHP processes are environment variables: `MEMORY_LIMIT`, `UPLOAD_MAX_FILESIZE`, `POST_MAX_SIZE`, `MAX_FILE_UPLOADS`, `MAX_EXECUTION_TIME`, `MAX_INPUT_TIME`, `MAX_CHILDREN`, with the values of before as defaults; a derived image no longer has to replace `php.ini`

- 2026-10-21 **1.2.9**
    - The modules `pcntl` and `bz2` are back in the default set; Nextcloud recommends both, `occ` uses `pcntl` for signals and the app updates use `bz2` to unpack. `pcntl` had been missing since 2018
    - The image reports its health to Docker: `HEALTHCHECK` runs `/usr/local/bin/health.php`, which asks the ping page `/ping` of php-fpm over FastCGI; the client `/usr/local/bin/fastcgi.php` is there for derived images too

- 2026-10-21 **1.2.8**
    - Every build takes the latest release of `install-php-extensions` instead of a fixed version with a fixed checksum

- 2026-10-21 **1.2.7**
    - The build tries the PHP modules up to ten times: pecl.php.net answered the download of apcu with 504 Gateway Timeout on the day of the PHP security release, and the whole build stopped

- 2026-10-21 **1.2.6**
    - PHP comes from the official image `php:fpm-alpine` instead of the PHP packages of Alpine: a PHP security release reaches the image within hours, where the Alpine packages took up to a day; every module is compiled against that PHP, and all modules of 1.2.5 load
    - The image carries the PHP CLI at `/usr/bin/php`, with the same modules and configuration as php-fpm; images built on it no longer copy a CLI of their own
    - `PHP_MODULES` names PHP modules as `install-php-extensions` knows them instead of Alpine packages; `PHP_IMAGE` selects another PHP branch

- 2026-10-21 **1.2.5**
    - Fatal error backtraces are off, locked in the pool: the advisory of CVE-2026-109619 names them as the producer of the confirmed remote code execution on PHP 8.5; the only complete fix is PHP 8.5.12

- 2026-10-21 **1.2.4**
    - Session upload progress is off, the mitigation named with the leaked details of the remote code execution announced as CVE-2026-109618 and CVE-2026-109619, locked in the pool so a `.user.ini` cannot switch it on again, until the fixed PHP release reaches the Alpine packages

- 2026-09-26 **1.2.3**
    - The test suite installs its Python packages without a warning

- 2026-09-26 **1.2.2**
    - The image is published for amd64 and arm64 under one tag, built and published automatically on every change and every week

- 2026-07-27 **1.2.1**
    - New end to end test suite runs the image together with mwaeckerlin/nginx and verifies the complete pairing without any extra configuration: PHP execution, front controller routing, HTTPS signalling from the proxy, hidden PHP signature and hardened session cookies
        - these combination tests moved here from the nginx project, whose suite now runs entirely without PHP
    - Feature and test registers added (FEATURES.md, TESTS.md) with an automatic guard: every feature must have a test, and no test may be skipped

- 2026-07-17 **1.2.0**
    - Error messages are never delivered to the client anymore, only written to the container log — previously the image showed PHP errors including paths and internals in the browser (information leak); applications can no longer re-enable this by accident
        - automatically safeguarded by a new configuration contract test
    - PHP no longer reveals itself in the HTTP header (signature disabled)
    - Sessions hardened out of the box: session fixation protection active, session cookie inaccessible to JavaScript and only sent on same-site navigation
    - The process refuses to start as root — the image always runs as an unprivileged user
    - Documentation added: deliberate security trade-offs (visible environment variables, large upload limits, internal port) are now described with rationale
    - README states the role explicitly: runtime image for the final build stage, never a build image

- 2026-07-14 **1.1.0**
    - The shipped image is now automatically verified to contain no shell and no scripting language — an attacker who reaches code execution in the container finds no tool to pivot with

- 2026-07-09 **1.0.1**
    - Fix TLS certificate verification. The image now ships OpenSSL's default CA file (/etc/ssl/cert.pem), which was dropped by the selective copy into the final scratch image — only /etc/ssl/certs was included, but not the cert.pem entry point OpenSSL reads by default. As a result any PHP connection with verify_peer failed with "unknown ca" (e.g. IMAP/SMTP over TLS in webmail). Derived images (rainloop/SnappyMail, postfixadmin) need a rebuild to pick this up.
