<?php

declare(strict_types=1);

final class DoubtAssignmentService
{
    /**
     * @return array{teacher_id:int, score:float, reason:string}|null
     */
    public static function pickTeacherForSubject(PDO $pdo, int $subjectId): ?array
    {
        $maxActive = (int) env_value('MAX_ACTIVE_DOUBTS_PER_TEACHER', '10');
        $ratingWeight = (float) env_value('ASSIGN_RATING_WEIGHT', '0.35');
        $availWeight = (float) env_value('ASSIGN_AVAILABILITY_WEIGHT', '0.35');
        $responseWeight = (float) env_value('ASSIGN_RESPONSE_WEIGHT', '0.30');

        $sql = "
            SELECT u.id,
                (SELECT COALESCE(AVG(rating), 3) FROM teacher_ratings WHERE teacher_id = u.id) AS avg_rating,
                (SELECT COUNT(*) FROM doubts WHERE assigned_teacher_id = u.id AND status IN ('assigned','in_progress')) AS active_count,
                resp.avg_first_response_sec
            FROM users u
            JOIN teacher_subjects ts ON ts.teacher_id = u.id
            LEFT JOIN (
                SELECT d2.assigned_teacher_id AS tid,
                    AVG(TIMESTAMPDIFF(SECOND, d2.created_at, x.first_at)) AS avg_first_response_sec
                FROM doubts d2
                INNER JOIN (
                    SELECT dm.doubt_id, MIN(dm.sent_at) AS first_at
                    FROM doubt_messages dm
                    INNER JOIN doubts d3 ON d3.id = dm.doubt_id AND dm.sender_id = d3.assigned_teacher_id
                    GROUP BY dm.doubt_id
                ) x ON x.doubt_id = d2.id
                WHERE d2.status IN ('resolved','closed')
                  AND d2.resolved_at IS NOT NULL
                  AND d2.resolved_at >= DATE_SUB(UTC_TIMESTAMP(), INTERVAL 30 DAY)
                GROUP BY d2.assigned_teacher_id
            ) resp ON resp.tid = u.id
            WHERE u.role = 'teacher' AND u.status = 'active' AND ts.subject_id = :sid
            GROUP BY u.id
        ";

        $stmt = $pdo->prepare($sql);
        $stmt->execute(['sid' => $subjectId]);
        $teachers = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $bestScore = -1.0;
        $bestId = null;

        foreach ($teachers as $row) {
            $active = (int) $row['active_count'];
            if ($active >= $maxActive) {
                continue;
            }

            $ratingNorm = ((float) $row['avg_rating']) / 5.0;
            $availability = 1.0 / (1 + $active);

            $avgSec = $row['avg_first_response_sec'];
            $avgSec = $avgSec !== null ? (float) $avgSec : 7200.0;
            $responseScore = 1.0 / (1.0 + ($avgSec / 7200.0));

            $score = ($ratingWeight * $ratingNorm) + ($availWeight * $availability) + ($responseWeight * $responseScore);

            if ($score > $bestScore) {
                $bestScore = $score;
                $bestId = (int) $row['id'];
            }
        }

        if ($bestId === null) {
            return null;
        }

        return [
            'teacher_id' => $bestId,
            'score' => round($bestScore, 4),
            'reason' => 'auto_assignment_v2',
        ];
    }
}
