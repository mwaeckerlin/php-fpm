# Changelog

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
