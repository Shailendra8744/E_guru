<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/src/bootstrap.php';
require_once dirname(__DIR__) . '/src/Database.php';

$migrationDir = dirname(__DIR__) . '/database/migrations';
$files = glob($migrationDir . '/*.sql') ?: [];
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
echo "Migrations complete." . PHP_EOL;
