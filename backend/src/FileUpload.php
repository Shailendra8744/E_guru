<?php

declare(strict_types=1);

final class FileUpload
{
    /**
     * @param array{name:string,type:string,tmp_name:string,error:int,size:int} $file
     * @return array{path:string, public_url:string}
     */
    public static function save(array $file, string $subdir, array $allowedMime, int $maxBytes): array
    {
        if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
            throw new RuntimeException('Upload failed');
        }
        if (($file['size'] ?? 0) > $maxBytes) {
            throw new RuntimeException('File too large');
        }
        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mime = $finfo->file($file['tmp_name']) ?: '';
        if (!in_array($mime, $allowedMime, true)) {
            throw new RuntimeException('Invalid file type');
        }

        $publicRoot = dirname(__DIR__) . '/public';
        $targetDir = $publicRoot . '/' . trim($subdir, '/');
        if (!is_dir($targetDir)) {
            if (!mkdir($targetDir, 0755, true) && !is_dir($targetDir)) {
                throw new RuntimeException('Cannot create upload directory');
            }
        }

        $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
        $ext = $ext ? '.' . preg_replace('/[^a-zA-Z0-9]/', '', $ext) : '';
        $basename = bin2hex(random_bytes(16)) . $ext;
        $fullPath = $targetDir . '/' . $basename;
        if (!move_uploaded_file($file['tmp_name'], $fullPath)) {
            throw new RuntimeException('Cannot store file');
        }

        $publicUrl = '/' . trim($subdir, '/') . '/' . $basename;
        
        $appPublicUrl = rtrim(env_value('APP_PUBLIC_URL', ''), '/');
        $absoluteUrl = $appPublicUrl ? $appPublicUrl . $publicUrl : $publicUrl;

        return ['path' => $publicUrl, 'public_url' => $absoluteUrl];
    }
}
