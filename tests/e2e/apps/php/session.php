<?php
// Starts a session so the e2e test can inspect the session cookie flags.
session_start();
header('Content-Type: text/plain');
echo "SESSION\n";
