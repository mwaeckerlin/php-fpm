2026-07-09  Marc Wäckerlin

	* 1.0.1: Fix TLS certificate verification. The image now ships OpenSSL's
	  default CA file (/etc/ssl/cert.pem), which was dropped by the selective
	  copy into the final scratch image — only /etc/ssl/certs was included, but
	  not the cert.pem entry point OpenSSL reads by default. As a result any PHP
	  connection with verify_peer failed with "unknown ca" (e.g. IMAP/SMTP over
	  TLS in webmail). Derived images (rainloop/SnappyMail, postfixadmin) need a
	  rebuild to pick this up.
