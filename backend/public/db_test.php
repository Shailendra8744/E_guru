<?php

declare(strict_types=1);

// Include necessary bootstrap and database files
require_once dirname(__DIR__) . '/src/bootstrap.php';
require_once dirname(__DIR__) . '/src/Database.php';

// Return output as JSON for easy reading
header('Content-Type: application/json');

try {
    // Attempt connecting to the database
    $pdo = Database::connection();
    
    // Check if PDO provides server info to confirm connection success
    echo json_encode([
        'status' => 'success',
        'message' => 'Database connection successful!',
        'server_version' => $pdo->getAttribute(PDO::ATTR_SERVER_VERSION),
        'server_info' => $pdo->getAttribute(PDO::ATTR_SERVER_INFO)
    ], JSON_PRETTY_PRINT);
    
} catch (PDOException $e) {
    // connection error
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'Database connection failed.',
        'error' => $e->getMessage()
    ], JSON_PRETTY_PRINT);
    
} catch (Throwable $e) {
    // general error
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'An unexpected error occurred.',
        'error' => $e->getMessage()
    ], JSON_PRETTY_PRINT);
}
