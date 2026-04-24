<?php
declare(strict_types=1);
require_once dirname(__DIR__) . '/src/bootstrap.php';
require_once dirname(__DIR__) . '/src/Database.php';

try {
    $pdo = Database::connection();
    $hash = password_hash('admin123', PASSWORD_DEFAULT);
    $stmt = $pdo->prepare("UPDATE users SET password_hash = :hash WHERE email = 'admin@eguru.local'");
    $stmt->execute(['hash' => $hash]);
    echo "Password updated successfully to admin123!";
} catch (Throwable $e) {
    echo "Error: " . $e->getMessage();
}
