# Features

Numbered register of every end-user visible feature; a number is never reused. Every feature is covered by tests listed in [TESTS.md](TESTS.md); the guard `tests/docs-contract.sh` fails when a feature has no test.

- **F1 — PHP application server.** Serves PHP applications from `/app` over FastCGI on port 9000, with a rich default module set (APCu, GD, imagick, intl, mysqli, opcache, …) that can be reduced or extended at build time via the `PHP_MODULES` build argument.
- **F2 — Zero-config pairing with mwaeckerlin/nginx.** Give both containers the same `/app` and everything works out of the box: nginx forwards PHP requests to this image (default backend `php-fpm:9000`), unknown routes reach the `index.php` front controller (e.g. WordPress permalinks), static assets stay with nginx, and PHP files that exist nowhere answer 404.
- **F3 — Errors never reach the client.** `display_errors` is forced off at pool level so an application cannot re-enable it; everything is logged to the container log with full `E_ALL` reporting instead.
- **F4 — PHP does not advertise itself.** The `X-Powered-By` signature is disabled — responses do not reveal PHP or its version.
- **F5 — Hardened sessions out of the box.** Session fixation protection (strict mode), the session cookie is inaccessible to JavaScript (`HttpOnly`) and only sent on same-site navigation (`SameSite=Lax`).
- **F6 — Proxy HTTPS state respected.** The application sees `HTTPS=on` exactly when the connection is TLS terminated (natively or signalled via `X-Forwarded-Proto: https` by the proxy); a client-supplied `X-Forwarded-Proto: http` can never downgrade it.
- **F7 — Headless minimal production image.** No shell and no interpreter besides php-fpm itself, always runs as an unprivileged user and refuses to start as root.
- **F8 — Published for amd64 and arm64.** Every push builds the image natively for both architectures and publishes it under one tag on Docker Hub, with the reusable workflow of `mwaeckerlin/scratch`.
