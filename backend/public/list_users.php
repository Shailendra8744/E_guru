<?php
declare(strict_types=1);
require_once dirname(__DIR__) . '/src/bootstrap.php';
require_once dirname(__DIR__) . '/src/Database.php';
header('Content-Type: application/json');

try {
    $pdo = Database::connection();
    $stmt = $pdo->query('SELECT email, role, status FROM users LIMIT 10');
    echo json_encode(['users' => $stmt->fetchAll()]);
} catch (Throwable $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
