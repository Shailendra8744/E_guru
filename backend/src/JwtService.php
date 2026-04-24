<?php

declare(strict_types=1);

final class JwtService
{
    public static function encode(array $payload, int $ttlSeconds): string
    {
        $header = ['alg' => 'HS256', 'typ' => 'JWT'];
        $now = time();
        $payload['iat'] = $now;
        $payload['exp'] = $now + $ttlSeconds;

        $head = self::base64UrlEncode((string) json_encode($header));
        $body = self::base64UrlEncode((string) json_encode($payload));
        $secret = (string) env_value('JWT_SECRET', '');
        $sig = hash_hmac('sha256', "{$head}.{$body}", $secret, true);
        return "{$head}.{$body}." . self::base64UrlEncode($sig);
    }

    public static function decode(string $token): ?array
    {
        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            return null;
        }
        [$head, $body, $sig] = $parts;
        $secret = (string) env_value('JWT_SECRET', '');
        $expected = self::base64UrlEncode(hash_hmac('sha256', "{$head}.{$body}", $secret, true));
        if (!hash_equals($expected, $sig)) {
            return null;
        }
        $payload = json_decode((string) self::base64UrlDecode($body), true);
        if (!is_array($payload) || !isset($payload['exp']) || (int) $payload['exp'] < time()) {
            return null;
        }
        return $payload;
    }

    private static function base64UrlEncode(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }

    private static function base64UrlDecode(string $value): string
    {
        return base64_decode(strtr($value, '-_', '+/')) ?: '';
    }
}
