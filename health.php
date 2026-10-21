<?php
declare(strict_types=1);

// Healthy once php-fpm answers its ping page (ping.path in www.conf).

require __DIR__ . '/fastcgi.php';

try {
    $answer = trim(fastcgiGet('/ping', '/ping'));
} catch (RuntimeException $e) {
    fwrite(STDERR, $e->getMessage() . "\n");
    exit(1);
}
if ($answer !== 'pong') {
    fwrite(STDERR, "php-fpm answered the ping with «{$answer}» instead of «pong»\n");
    exit(1);
}
exit(0);
