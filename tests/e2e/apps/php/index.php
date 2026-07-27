<?php
// Front controller: any unknown route lands here. Echo the original request
// URI so the e2e test can verify client-side-style routing through PHP.
header('Content-Type: text/plain');
echo 'FRONT=' . ($_SERVER['REQUEST_URI'] ?? '') . "\n";
