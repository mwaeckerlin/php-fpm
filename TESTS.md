# Tests

Register of all tests, grouped by kind and sorted by the [FEATURES.md](FEATURES.md) number each test covers. `npm test` runs everything; the guard `tests/docs-contract.sh` fails when a feature has no test entry here or when any test carries a skip/xfail marker — tests are never skipped.

The e2e stack (`tests/e2e/`) runs this image **together with mwaeckerlin/nginx** and tests the real pairing — nginx is a sibling project and consumed as a prebuilt image (a locally built one takes precedence over the hub version). The nginx-only behaviour (static, SPA, languages, PHP optionality) is tested in the nginx project, which runs entirely without PHP.

## End-to-end

pytest runs against the real compose stack.

- **F1** `tests/e2e/test_php.py` › test_php_executes — a PHP script is executed and answers over the full nginx→FastCGI path.
- **F2** `tests/e2e/test_php.py` › test_front_controller_fallback — an unknown route reaches `index.php` with the original URI.
- **F2** `tests/e2e/test_php.py` › test_static_asset_in_php_app — a static asset is served by nginx, not routed through PHP.
- **F2** `tests/e2e/test_php.py` › test_missing_php_file_returns_404 — a PHP file that exists nowhere answers 404.
- **F4** `tests/e2e/test_php.py` › test_no_php_signature_header — no `X-Powered-By` in the response.
- **F5** `tests/e2e/test_php.py` › test_session_cookie_hardened — the session cookie carries `HttpOnly` and `SameSite=Lax`.
- **F6** `tests/e2e/test_php.py` › test_https_empty_on_plain_http — plain HTTP does not report HTTPS to the application.
- **F6** `tests/e2e/test_php.py` › test_https_on_with_forwarded_proto_https — a TLS terminating proxy sets `HTTPS=on`.
- **F6** `tests/e2e/test_php.py` › test_https_empty_with_forwarded_proto_http — a spoofed `X-Forwarded-Proto: http` cannot downgrade.

## Image contract

- **F1** `tests/config-contract.sh` › module_imagick — the conditional imagick install step really ran.
- **F3** `tests/config-contract.sh` › display_errors_off, display_startup_errors_off — errors are never displayed to clients.
- **F3** `tests/config-contract.sh` › log_errors_on — errors still reach the container log.
- **F7** `tests/image-contract.sh` › no sh, no bash, no busybox, no perl — the shipped image is headless.

## Workflow contract

- **F8** `tests/workflow-contract.sh` of `mwaeckerlin/scratch` — the reusable workflow selects exactly the images a repository publishes; this repository calls it from `.github/workflows/docker.yml`.
