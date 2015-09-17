<?php

/**
 * Examples
 *
 * http://localhost:8000/?type=playlist&name=精選
 * http://localhost:8000/?type=playlist&name=優勝
 * http://localhost:8000/?type=album&name=&artist=周杰倫&style=流行樂&year=2006
 * http://localhost:8000/?type=album&name=張學友
 * http://localhost:8000/?type=song&artist=王力宏
 * http://localhost:8000/?type=song&artist=張學友
 * http://localhost:8000/
 */

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=utf-8;");
header("Cache-Control: no-cache");
header("Pragma: no-cache");

$db = new PDO('sqlite:' . __DIR__ . '/../database/example.sqlite');
$status = -1;
$message = '';
$data = array();

function getParam($name)
{
    return array_key_exists($name, $_GET) ? $_GET[$name] : null;
}

if (getParam('type') === 'playlist') {

    $sql = "SELECT * FROM playlist";
    if (getParam('name')) {
        $sql .= sprintf(" WHERE name LIKE '%%%s%%'", getParam('name'));
    }
    $query = $db->query($sql);
    $playlists = $query->fetchAll(PDO::FETCH_ASSOC);

    if ($playlists) {
        foreach ($playlists as &$playlist) {
            $sql = sprintf("SELECT song.id, song.name FROM song
JOIN artist ON song.artist_id = artist.id
JOIN playlist_song ON playlist_song.song_id = song.id
JOIN playlist ON playlist_song.playlist_id = playlist.id
AND playlist.id = '%s'", $playlist['id']);
            $query = $db->query($sql);
            $playlist['songs'] = $query->fetchAll(PDO::FETCH_ASSOC);
        }

        $data = $playlists;
    } else {
        $status = 0;
        $message = 'not found';
    }
} elseif (getParam('type') === 'album') {

    $sql = "SELECT album.*, artist.name AS artist_name FROM album JOIN artist ON artist.id = album.artist_id";
    $parts = array();
    if (getParam('name')) {
        $parts[] = sprintf("album.name LIKE '%%%s%%'", getParam('name'));
    }
    if (getParam('artist')) {
        $parts[] = sprintf("artist.name LIKE '%%%s%%'", getParam('artist'));
    }
    if (getParam('style')) {
        $parts[] = sprintf("album.style LIKE '%%%s%%'", getParam('style'));
    }
    if (getParam('year')) {
        $parts[] = sprintf("album.year = '%s'", getParam('year'));
    }
    if ($parts) {
        $sql .= " WHERE " . implode(" AND ", $parts);
    }

    $query = $db->query($sql);
    $albums = $query->fetchAll(PDO::FETCH_ASSOC);

    if ($albums) {
        foreach ($albums as &$album) {
            $sql = sprintf("SELECT song.id, song.name FROM song
JOIN artist ON song.artist_id = artist.id
JOIN album ON song.album_id = album.id
AND album.id = '%s'", $album['id']);
            $query = $db->query($sql);
            $album['songs'] = $query->fetchAll(PDO::FETCH_ASSOC);
        }

        $data = $albums;
    } else {
        $status = 0;
        $message = 'not found';
    }

} elseif (getParam('type') === 'song') {

    $sql = sprintf("SELECT song.id, song.name, artist.name AS artist_name, album.name AS album_name FROM song
JOIN artist ON artist.id = album.artist_id
JOIN album ON album.id = song.album_id
AND artist.name LIKE '%%%s%%'", getParam('artist'));

    $query = $db->query($sql);
    $songs = $query->fetchAll(PDO::FETCH_ASSOC);
    if ($songs) {
        $data = $songs;
    } else {
        $status = 0;
        $message = 'not found';
    }

} else {
    $status = 0;
    $message = 'type error';
}

echo json_encode([
    'data' => $data,
    'status' => $status,
    'message' => $message,
]);