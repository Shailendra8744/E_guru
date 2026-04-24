<?php

declare(strict_types=1);

final class Pagination
{
    public const DEFAULT_PAGE = 1;
    public const DEFAULT_PER_PAGE = 20;
    public const MAX_PER_PAGE = 100;

    /**
     * @return array{page:int, per_page:int, offset:int, limit:int}
     */
    public static function fromQuery(array $get): array
    {
        $page = max(1, (int) ($get['page'] ?? self::DEFAULT_PAGE));
        $perPage = (int) ($get['per_page'] ?? self::DEFAULT_PER_PAGE);
        if ($perPage < 1) {
            $perPage = self::DEFAULT_PER_PAGE;
        }
        $perPage = min($perPage, self::MAX_PER_PAGE);
        $offset = ($page - 1) * $perPage;

        return [
            'page' => $page,
            'per_page' => $perPage,
            'offset' => $offset,
            'limit' => $perPage,
        ];
    }

    /**
     * @return array{page:int, per_page:int, total:int, total_pages:int}
     */
    public static function meta(int $total, int $page, int $perPage): array
    {
        $totalPages = $perPage > 0 ? (int) ceil($total / $perPage) : 0;

        return [
            'page' => $page,
            'per_page' => $perPage,
            'total' => $total,
            'total_pages' => $totalPages,
        ];
    }
}
