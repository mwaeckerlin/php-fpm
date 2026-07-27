<?php
// Probe that reports the effective HTTPS state nginx forwarded to FastCGI.
// Outputs exactly "HTTPS=<value>" so the test can grep it unambiguously.
header('Content-Type: text/plain');
echo 'HTTPS=' . ($_SERVER['HTTPS'] ?? '') . "\n";
