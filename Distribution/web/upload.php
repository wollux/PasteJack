<?php
/**
 * PasteJack Release Upload Endpoint
 *
 * Receives DMG + appcast.xml during release workflow.
 * Deploy to: https://pastejack.app/api/upload.php
 *
 * Usage from release script:
 *   curl -X POST https://pastejack.app/api/upload.php \
 *     -H "Authorization: Bearer YOUR_UPLOAD_TOKEN" \
 *     -F "dmg=@.build/PasteJack-1.0.0.dmg" \
 *     -F "appcast=@appcast.xml" \
 *     -F "version=1.0.0"
 */

// ── Config ──────────────────────────────────────────────────────────────
$UPLOAD_TOKEN  = getenv('PASTEJACK_UPLOAD_TOKEN') ?: 'CHANGE_ME_TO_A_SECURE_TOKEN';
$DOWNLOADS_DIR = __DIR__ . '/../downloads';
$APPCAST_PATH  = __DIR__ . '/../appcast.xml';
$MAX_DMG_SIZE  = 200 * 1024 * 1024; // 200 MB

// ── Auth ────────────────────────────────────────────────────────────────
header('Content-Type: application/json');

$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
if ($authHeader !== "Bearer $UPLOAD_TOKEN") {
    http_response_code(401);
    die(json_encode(['error' => 'Unauthorized']));
}

// ── Validate request ────────────────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    die(json_encode(['error' => 'POST only']));
}

$version = $_POST['version'] ?? '';
if (!preg_match('/^\d+\.\d+\.\d+$/', $version)) {
    http_response_code(400);
    die(json_encode(['error' => 'Invalid version format (expected: X.Y.Z)']));
}

// ── Handle DMG upload ───────────────────────────────────────────────────
if (!isset($_FILES['dmg']) || $_FILES['dmg']['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    die(json_encode(['error' => 'Missing or failed DMG upload']));
}

if ($_FILES['dmg']['size'] > $MAX_DMG_SIZE) {
    http_response_code(413);
    die(json_encode(['error' => 'DMG too large (max 200 MB)']));
}

// Verify it looks like a DMG (magic bytes)
$handle = fopen($_FILES['dmg']['tmp_name'], 'rb');
$magic = fread($handle, 4);
fclose($handle);
// DMG files can start with various signatures; just check it's not obviously wrong
$ext = strtolower(pathinfo($_FILES['dmg']['name'], PATHINFO_EXTENSION));
if ($ext !== 'dmg') {
    http_response_code(400);
    die(json_encode(['error' => 'File must be a .dmg']));
}

// Create downloads dir if needed
if (!is_dir($DOWNLOADS_DIR)) {
    mkdir($DOWNLOADS_DIR, 0755, true);
}

$dmgFilename = "PasteJack-{$version}.dmg";
$dmgPath = "{$DOWNLOADS_DIR}/{$dmgFilename}";

if (!move_uploaded_file($_FILES['dmg']['tmp_name'], $dmgPath)) {
    http_response_code(500);
    die(json_encode(['error' => 'Failed to save DMG']));
}

chmod($dmgPath, 0644);
$dmgSha256 = hash_file('sha256', $dmgPath);
$dmgSize = filesize($dmgPath);

// ── Handle appcast.xml upload ───────────────────────────────────────────
if (isset($_FILES['appcast']) && $_FILES['appcast']['error'] === UPLOAD_ERR_OK) {
    $appcastContent = file_get_contents($_FILES['appcast']['tmp_name']);

    // Basic XML validation
    libxml_use_internal_errors(true);
    $xml = simplexml_load_string($appcastContent);
    if ($xml === false) {
        // Don't fail the whole upload, just warn
        $appcastWarning = 'appcast.xml is not valid XML — skipped';
    } else {
        // Backup old appcast
        if (file_exists($APPCAST_PATH)) {
            copy($APPCAST_PATH, $APPCAST_PATH . '.bak');
        }
        file_put_contents($APPCAST_PATH, $appcastContent);
        chmod($APPCAST_PATH, 0644);
    }
}

// ── Response ────────────────────────────────────────────────────────────
$response = [
    'ok'       => true,
    'version'  => $version,
    'dmg'      => [
        'filename' => $dmgFilename,
        'url'      => "https://pastejack.app/downloads/{$dmgFilename}",
        'sha256'   => $dmgSha256,
        'size'     => $dmgSize,
    ],
    'appcast'  => isset($appcastWarning) ? $appcastWarning : 'updated',
];

echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n";
