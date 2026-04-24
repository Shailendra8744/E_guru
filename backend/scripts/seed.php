<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/src/bootstrap.php';
require_once dirname(__DIR__) . '/src/Database.php';

$seedDir = dirname(__DIR__) . '/database/seeds';
$files = glob($seedDir . '/*.sql') ?: [];
sort($files);

$pdo = Database::connection();
foreach ($files as $file) {
    $sql = file_get_contents($file);
    if (!$sql) {
        continue;
    }
    echo "Running " . basename($file) . PHP_EOL;
    $pdo->exec($sql);
}
echo "Seeds complete." . PHP_EOL;
