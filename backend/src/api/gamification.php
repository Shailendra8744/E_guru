<?php

function handle_gamification_routes($method, $path, $pdo) {
    if ($method === 'GET' && ($path === '/api/v1/leaderboard' || $path === '/leaderboard')) {
        $stmt = $pdo->prepare("SELECT id, full_name, email, role, xp FROM users WHERE role = 'student' ORDER BY xp DESC LIMIT 20");
        $stmt->execute();
        json_response(['items' => $stmt->fetchAll()]);
        exit;
    }
}

function award_xp($pdo, $userId, $amount) {
    $stmt = $pdo->prepare("UPDATE users SET xp = xp + :amount WHERE id = :id");
    $stmt->execute(['amount' => $amount, 'id' => $userId]);
}
