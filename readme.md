# Lab4 - 曲庫資料讀取 API

目的：學習如何測試與重構舊有 PHP 程式碼。

註：這個範例為了簡單起見，並沒有考慮安全驗證機制，單純介紹重構技巧。

## 建置測試環境

這步是最困難，很多人會卡在線上環境不易建置；而每個專案的狀況都不同，所以沒有什麼 SOP 可以參考。

這邊用最簡單的 `http:://localhost:8000` 來模擬，實務上應該用接近真實環境的測試機。

在 Terminal 視窗執行：

```bash
php -S localhost:8000 -t public
```

## 加入 PHPUnit 和 Guzzle 支援

執行：

```bash
composer require guzzlehttp/guzzle phpunit/phpunit --dev
```

建立 `.gitignore`

```
vendor/
```

建立 `tests` 資料夾

建立 `phpunit.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit backupGlobals="false"
         backupStaticAttributes="false"
         bootstrap="vendor/autoload.php"
         colors="true"
         convertErrorsToExceptions="true"
         convertNoticesToExceptions="true"
         convertWarningsToExceptions="true"
         processIsolation="false"
         stopOnFailure="false"
         syntaxCheck="false">
    <testsuites>
        <testsuite name="Application Test Suite">
            <directory>./tests/</directory>
        </testsuite>
    </testsuites>
</phpunit>
```

## 確認與觀察輸出結果

分別查看以下的網址的輸出：

```
http://localhost:8000/?type=playlist&name=精選
http://localhost:8000/?type=album&name=&artist=周杰倫&style=流行樂&year=2006
http://localhost:8000/?type=song&artist=王力宏
http://localhost:8000/
```

如果用瀏覽器查看，則可搭配檢視 JSON 的擴充套件來檢視，例如 Google Chrome 的 [JSON-handle](https://chrome.google.com/webstore/detail/iahnhfdhidomcpggpaimmmahffihkfnj) 。

如果可以用 `curl` 與 `python` 指令，可輸入：

```bash
curl -s "http://localhost:8000/?type=playlist&name=%E7%B2%BE%E9%81%B8" | python -m json.tool
```

`curl` 可能不能直接使用中文網址，所有中文的部份可以先用 urlencode 編碼：

```bash
php -r "echo urlencode('精選');"
```

## 新增測試

在 PhpStorm 選取 `tests` 資料夾，然後按 `⌘ N` > `PHPUnit` > `PHPUnit Test` 。

* Fully qualified name: MusicApi
* Name: MusicApiTest
* File name: tests/MusicApiTest.php

因為接下來需要連上測試網址驗證結果，所以要建立一個 Guzzle Client ：

```php
<?php

use GuzzleHttp\Client;

class MusicApiTest extends PHPUnit_Framework_TestCase
{
    /**
     * @var Client
     */
    protected $client;

    protected function setUp()
    {
        $this->client = new Client([
            'base_uri' => 'http://localhost:8000',
        ]);
    }
}
```

分析前面的輸出結果後，可以知道輸出一定會包含以下值：

* `data` ：實際需要的資料
* `status` ：是否成功 (0: 失敗 / -1 成功)
* `message` ：錯誤訊息

然後可以再針對 `data` 的內容再進行個別的驗證，其中我們只需要驗證是否包含某 key 即可，暫時不需要驗證內容。

先建立類型為 `playlist` 的測試案例：

```php
    public function testGetPlaylist()
    {
        $params = [
            'type' => 'playlist',
            'name' => '精選',
        ];
        $expectedStatus = -1;
        $expectedMessage = '';

        $response = $this->client->get('/', [
            'query' => $params,
        ]);

        $this->assertEquals(200, $response->getStatusCode());

        $body = $response->getBody();
        $json = json_decode($body);

        $this->assertObjectHasAttribute('data', $json);
        $this->assertObjectHasAttribute('status', $json);
        $this->assertObjectHasAttribute('message', $json);
        $this->assertEquals($expectedStatus, $json->status);
        $this->assertEquals($expectedMessage, $json->message);

        foreach ($json->data as $data) {
            $this->assertObjectHasAttribute('name', $data);
            $this->assertObjectHasAttribute('songs', $data);
            $this->assertContains('精選', $data->name);
        }
    }
```

執行測試。

### 重構測試案例

為了後面可以重複利用回傳的結果，所以把取得 JSON 結果的程式碼提煉出來：

```php
    /**
     * @param $params
     * @param $expectedStatus
     * @param $expectedMessage
     * @return mixed
     */
    private function createResponse($params, $expectedStatus, $expectedMessage)
    {
        $response = $this->client->get('/', [
            'query' => $params,
        ]);

        $this->assertEquals(200, $response->getStatusCode());

        $body = $response->getBody();
        $json = json_decode($body);

        $this->assertObjectHasAttribute('data', $json);
        $this->assertObjectHasAttribute('status', $json);
        $this->assertObjectHasAttribute('message', $json);
        $this->assertEquals($expectedStatus, $json->status);
        $this->assertEquals($expectedMessage, $json->message);
        return $json;
    }

    public function testGetPlaylist()
    {
        $params = [
            'type' => 'playlist',
            'name' => '精選',
        ];
        $expectedStatus = -1;
        $expectedMessage = '';

        $json = $this->createResponse($params, $expectedStatus, $expectedMessage);

        foreach ($json->data as $data) {
            $this->assertObjectHasAttribute('name', $data);
            $this->assertObjectHasAttribute('songs', $data);
            $this->assertContains('精選', $data->name);
        }
    }
```

執行測試。

## 新增其他測試案例

加入類型為 `album` 的測試案例：

```php
    public function testGetAlbum()
    {
        $params = [
            'type' => 'album',
            'artist' => '周杰倫',
            'style' => '流行樂',
            'year' => 2006,
        ];
        $expectedStatus = -1;
        $expectedMessage = '';

        $json = $this->createResponse($params, $expectedStatus, $expectedMessage);

        foreach ($json->data as $data) {
            $this->assertObjectHasAttribute('name', $data);
            $this->assertObjectHasAttribute('artist_id', $data);
            $this->assertObjectHasAttribute('artist_name', $data);
            $this->assertObjectHasAttribute('style', $data);
            $this->assertObjectHasAttribute('year', $data);
            $this->assertObjectHasAttribute('songs', $data);
            $this->assertEquals('周杰倫', $data->artist_name);
            $this->assertEquals('流行樂', $data->style);
            $this->assertEquals(2006, $data->year);
        }
    }
```

執行測試。

加入類型為 `song` 的測試案例：

```php
    public function testGetSong()
    {
        $params = [
            'type' => 'song',
            'artist' => '王力宏',
        ];
        $expectedStatus = -1;
        $expectedMessage = '';

        $json = $this->createResponse($params, $expectedStatus, $expectedMessage);

        foreach ($json->data as $data) {
            $this->assertObjectHasAttribute('name', $data);
            $this->assertObjectHasAttribute('artist_name', $data);
            $this->assertObjectHasAttribute('album_name', $data);
            $this->assertEquals('王力宏', $data->artist_name);
        }
    }
```

執行測試。

加入「找不到」的測試案例：

```php
    public function testPlaylistNotFound()
    {
        $params = [
            'type' => 'playlist',
            'name' => '優勝',
        ];
        $expectedStatus = 0;
        $expectedMessage = 'not found';

        $this->createResponse($params, $expectedStatus, $expectedMessage);
    }

    public function testAlbumNotFound()
    {
        $params = [
            'type' => 'album',
            'name' => '張學友',
        ];
        $expectedStatus = 0;
        $expectedMessage = 'not found';

        $this->createResponse($params, $expectedStatus, $expectedMessage);
    }

    public function testSongNotFound()
    {
        $params = [
            'type' => 'song',
            'artist' => '張學友',
        ];
        $expectedStatus = 0;
        $expectedMessage = 'not found';

        $this->createResponse($params, $expectedStatus, $expectedMessage);
    }
```

執行測試。

最後加入類型錯誤的案例：

```php
    public function testTypeError()
    {
        $params = [];
        $expectedStatus = 0;
        $expectedMessage = 'type error';

        $this->createResponse($params, $expectedStatus, $expectedMessage);
    }
```

執行測試。

## 重構：加上註解

先幫程式碼註解：

```php
if (getParam('type') === 'playlist') {

    // 取得歌單資料

        // 取得歌單內歌曲資料
        foreach ($playlists as &$playlist) {

} elseif (getParam('type') === 'album') {

    // 取得專輯資料

        // 取得專輯內歌曲資料
        foreach ($albums as &$album) {

} elseif (getParam('type') === 'song') {

    // 取得歌曲資料

} else {

    // 類型錯誤
```

## 重構：將輸入參數移出去

利用正規式，將所有的 `getParam('...')` 替換為變數；例如 `getParam('type')` 換成 `$type` 。正規式規則為： `getParam\('(\w+)'\)` ，替換為 `\\$$1` 。

在 `if` 判斷式上方，加入：

```php
$type = getParam('type');
$name = getParam('name');
$artist = getParam('artist');
$style = getParam('style');
$year = getParam('year');
```

## 重構，提煉方法

### 提煉 fetchDataForPlaylist 方法

將以下這段選取起來：

```php
    $sql = "SELECT * FROM playlist";
    if ($name) {
        $sql .= sprintf(" WHERE name LIKE '%%%s%%'", $name);
    }
    $query = $db->query($sql);
    $playlists = $query->fetchAll(PDO::FETCH_ASSOC);
```

用 PhpStorm 的 Extract Method 功能，將它提煉成 `fetchDataForPlaylist` 函式：

```php
/**
 * @param $name
 * @param $db
 * @return array
 */
function fetchDataForPlaylist($name, $db)
{
    $sql = "SELECT * FROM playlist";
    if ($name) {
        $sql .= sprintf(" WHERE name LIKE '%%%s%%'", $name);
    }
    $query = $db->query($sql);
    $playlists = $query->fetchAll(PDO::FETCH_ASSOC);
    return array($sql, $query, $playlists);
}

// 取得歌單資料
list($sql, $query, $playlists) = fetchDataForPlaylist($name, $db);
```

因為 `$sql` 和 `$query` 是區域變數，所以將它們從函式參數中拿掉，改為：

```php
/**
 * @param $name
 * @param $db
 * @return array
 */
function fetchDataForPlaylist($name, $db)
{
    $sql = "SELECT * FROM playlist";
    if ($name) {
        $sql .= sprintf(" WHERE name LIKE '%%%s%%'", $name);
    }
    $query = $db->query($sql);
    $playlists = $query->fetchAll(PDO::FETCH_ASSOC);
    return $playlists;
}

// 取得歌單資料
$playlists = fetchDataForPlaylist($name, $db);
```

執行測試。

### 提煉 appendSongsToPlaylist 方法

將以下這段選取起來：

```php
        foreach ($playlists as &$playlist) {
            $sql = sprintf("SELECT song.id, song.name FROM song
JOIN artist ON song.artist_id = artist.id
JOIN playlist_song ON playlist_song.song_id = song.id
JOIN playlist ON playlist_song.playlist_id = playlist.id
AND playlist.id = '%s'", $playlist['id']);
            $query = $db->query($sql);
            $playlist['songs'] = $query->fetchAll(PDO::FETCH_ASSOC);
        }
```

用 PhpStorm 的 Extract Method 功能，將它提煉成 `appendSongsToPlaylist` 函式：

```php
/**
 * @param $playlists
 * @param $playlist
 * @param $db
 * @return mixed
 */
function appendSongsToPlaylist($playlists, $playlist, $db)
{
    foreach ($playlists as &$playlist) {
        $sql = sprintf("SELECT song.id, song.name FROM song
JOIN artist ON song.artist_id = artist.id
JOIN playlist_song ON playlist_song.song_id = song.id
JOIN playlist ON playlist_song.playlist_id = playlist.id
AND playlist.id = '%s'", $playlist['id']);
        $query = $db->query($sql);
        $playlist['songs'] = $query->fetchAll(PDO::FETCH_ASSOC);
    }
    return $playlist;
}

// 取得歌單內歌曲資料
$playlist = appendSongsToPlaylist($playlists, $playlist, $db);
```

因為 `$playlist` 是區域變數，所以將它從函式參數中拿掉，改為回傳 `$playlists` ：

```php
/**
 * @param $playlists
 * @param $db
 * @return mixed
 */
function appendSongsToPlaylist($playlists, $db)
{
    foreach ($playlists as &$playlist) {
        $sql = sprintf("SELECT song.id, song.name FROM song
JOIN artist ON song.artist_id = artist.id
JOIN playlist_song ON playlist_song.song_id = song.id
JOIN playlist ON playlist_song.playlist_id = playlist.id
AND playlist.id = '%s'", $playlist['id']);
        $query = $db->query($sql);
        $playlist['songs'] = $query->fetchAll(PDO::FETCH_ASSOC);
    }
    return $playlists;
}

// 取得歌單內歌曲資料
$playlists = appendSongsToPlaylist($playlists, $db);
```

執行測試。

### 提煉其他取得資料的方法

照此模式，提煉出 `fetchDataForAlbum` 、 `appendSongsToAlbum` 、 `fetchDataForSong` 這三個方法。

```php
/**
 * @param $name
 * @param $artist
 * @param $style
 * @param $year
 * @param $db
 * @return array
 */
function fetchDataForAlbum($name, $artist, $style, $year, $db)
{
    $sql = "SELECT album.*, artist.name AS artist_name FROM album JOIN artist ON artist.id = album.artist_id";
    $parts = array();
    if ($name) {
        $parts[] = sprintf("album.name LIKE '%%%s%%'", $name);
    }
    if ($artist) {
        $parts[] = sprintf("artist.name LIKE '%%%s%%'", $artist);
    }
    if ($style) {
        $parts[] = sprintf("album.style LIKE '%%%s%%'", $style);
    }
    if ($year) {
        $parts[] = sprintf("album.year = '%s'", $year);
    }
    if ($parts) {
        $sql .= " WHERE " . implode(" AND ", $parts);
    }

    $query = $db->query($sql);
    $albums = $query->fetchAll(PDO::FETCH_ASSOC);
    return $albums;
}

/**
 * @param $albums
 * @param $db
 * @return mixed
 */
function appendSongsToAlbum($albums, $db)
{
    foreach ($albums as &$album) {
        $sql = sprintf("SELECT song.id, song.name FROM song
JOIN artist ON song.artist_id = artist.id
JOIN album ON song.album_id = album.id
AND album.id = '%s'", $album['id']);
        $query = $db->query($sql);
        $album['songs'] = $query->fetchAll(PDO::FETCH_ASSOC);
    }
    return $albums;
}

/**
 * @param $artist
 * @param $db
 * @return mixed
 */
function fetchDataForSong($artist, $db)
{
    $sql = sprintf("SELECT song.id, song.name, artist.name AS artist_name, album.name AS album_name FROM song
JOIN artist ON artist.id = album.artist_id
JOIN album ON album.id = song.album_id
AND artist.name LIKE '%%%s%%'", $artist);

    $query = $db->query($sql);
    $songs = $query->fetchAll(PDO::FETCH_ASSOC);
    return $songs;
}
```

原來的 `if ... else` 就變成：

```php
if ($type === 'playlist') {

    // 取得歌單資料
    $playlists = fetchDataForPlaylist($name, $db);

    if ($playlists) {

        // 取得歌單內歌曲資料
        $playlists = appendSongsToPlaylist($playlists, $db);

        $data = $playlists;
    } else {
        $status = 0;
        $message = 'not found';
    }
} elseif ($type === 'album') {

    // 取得專輯資料
    $albums = fetchDataForAlbum($name, $artist, $style, $year, $db);

    if ($albums) {

        // 取得專輯內歌曲資料
        $albums = appendSongsToAlbum($albums, $db);

        $data = $albums;
    } else {
        $status = 0;
        $message = 'not found';
    }

} elseif ($type === 'song') {

    // 取得歌曲資料
    $songs = fetchDataForSong($artist, $db);

    if ($songs) {
        $data = $songs;
    } else {
        $status = 0;
        $message = 'not found';
    }

} else {

    // 類型錯誤
    $status = 0;
    $message = 'type error';
}
```

### 提煉 search 函式

將以下這段選取起來：

```php
if ($type === 'playlist') {
	// ...
}

echo json_encode([
    'data' => $data,
    'status' => $status,
    'message' => $message,
]);
```

提煉成 `search` 函式，並將 `$db` 當成最後一個參數：

```php
/**
 * @param $type
 * @param $name
 * @param $artist
 * @param $style
 * @param $year
 * @param $db
 */
function search($type, $name, $artist, $style, $year, $db)
{
    if ($type === 'playlist') {

        // 取得歌單資料
        $playlists = fetchDataForPlaylist($name, $db);

        if ($playlists) {

            // 取得歌單內歌曲資料
            $playlists = appendSongsToPlaylist($playlists, $db);

            $data = $playlists;
        } else {
            $status = 0;
            $message = 'not found';
        }
    } elseif ($type === 'album') {

        // 取得專輯資料
        $albums = fetchDataForAlbum($name, $artist, $style, $year, $db);

        if ($albums) {

            // 取得專輯內歌曲資料
            $albums = appendSongsToAlbum($albums, $db);

            $data = $albums;
        } else {
            $status = 0;
            $message = 'not found';
        }

    } elseif ($type === 'song') {

        // 取得歌曲資料
        $songs = fetchDataForSong($artist, $db);

        if ($songs) {
            $data = $songs;
        } else {
            $status = 0;
            $message = 'not found';
        }

    } else {

        // 類型錯誤
        $status = 0;
        $message = 'type error';
    }

    echo json_encode([
        'data' => $data,
        'status' => $status,
        'message' => $message,
    ]);
}

search($type, $name, $artist, $style, $year, $db);
```

執行測試會失敗，因為原來的 `$data` 、 `$status` 、 `$message` 沒有搬進來。將它們移進 `search` 函式裡：

```php
function search($type, $name, $artist, $style, $year, $db)
{
    $status = -1;
    $message = '';
    $data = array();
```

執行測試。

儘可能不要在函式裡輸出值，所以將：

```php
    echo json_encode([
        'data' => $data,
        'status' => $status,
        'message' => $message,
    ]);
```

改成：

```php
    return [
        'data' => $data,
        'status' => $status,
        'message' => $message,
    ];
```

然後把：

```php
search($type, $name, $artist, $style, $year, $db);
```

改成：

```php
echo json_encode(search($type, $name, $artist, $style, $year, $db));
```

## 重構：移動不需要曝露的函式

將呼叫 `appendSongsToPlaylist` 函式的程式碼，移到 `fetchDataForPlaylist` 函式裡：

```php
/**
 * @param $name
 * @param $db
 * @return array
 */
function fetchDataForPlaylist($name, $db)
{
    // ...

    if ($playlists) {
        // 取得歌單內歌曲資料
        $playlists = appendSongsToPlaylist($playlists, $db);
    }

    return $playlists;
}
```

依此模式，將 `appendSongsToAlbum` 函式移進 `fetchDataForAlbum` 裡：

```php
function fetchDataForAlbum($name, $artist, $style, $year, $db)
{
	// ...

    if ($albums) {
        // 取得專輯內歌曲資料
        $albums = appendSongsToAlbum($albums, $db);
    }

    return $albums;
}
```

這樣在 `public/index.php` 中就可以改成：

```php
    if ($type === 'playlist') {

        // 取得歌單資料
        $data = fetchDataForPlaylist($name, $db);

        if (empty($data)) {
            $status = 0;
            $message = 'not found';
        }
    } elseif ($type === 'album') {

        // 取得專輯資料
        $data = fetchDataForAlbum($name, $artist, $style, $year, $db);

        if (empty($data)) {
            $status = 0;
            $message = 'not found';
        }
    } elseif ($type === 'song') {

        // 取得歌曲資料
        $data = fetchDataForSong($artist, $db);

        if (empty($data)) {
            $status = 0;
            $message = 'not found';
        }
    } else {

        // 類型錯誤
        $status = 0;
        $message = 'type error';
    }
```

## 重構，提煉類別

### 設定 composer autoload

在 `composer.json` 加入 `autoload` 區段：

```json
    "autoload": {
        "psr-4": {
            "Lab4\\": "src/"
        }
    },
```

建立 `src` 資料夾。

用 PhpStorm 設定 `src` 資料夾的 `prefix` 為 `Lab4` 。

### 提煉 DataStore 類別

建立 `src/DataStore.php` ，內容如下：

```php
<?php

namespace Lab4;

class DataStore
{

}
```

把 `public/index.php` 的 `fetchDataForPlaylist` 、 `appendSongsToPlaylist` 、 `fetchDataForAlbum` 、 `appendSongsToAlbum` 、 `fetchDataForSong` 、 `search` 函式，搬到 `DataSource` 類別裡。除了 `appendSongsToPlaylist` 、 `appendSongsToAlbum` 兩個方法為 `private` 外，其他都是 `public` ：

```php
<?php

namespace Lab4;

class DataStore
{
    public function fetchDataForPlaylist($name, $db)
	{
		// ...
	}

    private function appendSongsToPlaylist($playlists, $db)
	{
		// ...
	}

    public function fetchDataForAlbum($name, $artist, $style, $year, $db)
	{
		// ...
	}

    private function appendSongsToAlbum($albums, $db)
	{
		// ...
	}

    public function fetchDataForSong($artist, $db)
	{
		// ...
	}

    private function search($type, $name, $artist, $style, $year, $db)
	{
		// ...
	}
}
```

然後把 `search` 方法裡的呼叫函式的地方，改成呼叫方法，例如：

```php
fetchDataForPlaylist($name, $db);
```

改為：

```php
$this->fetchDataForPlaylist($name, $db);
```

另外 `fetchDataForPlaylist` 及 `fetchDataForAlbum` 方法裡呼叫 `appendSongsToPlaylist` 及 `appendSongsToAlbum` 函式的地方也要改成呼叫物件方法。

將所有方法裡的 `$db` 參數移除，也就是把 `, $db)` 取代成 `)` 。 (這就是為什麼要把 `$db` 放在最後的原因，比較好一次處理。)

然後把 `$db` 改成 `$this->db` 。

因為 `$this->db` 要從外部傳入，所以我們要把它變成類別屬性，在 `DataStore` 類別加入：

```php
use PDO;

class DataStore
{
    /**
     * @var PDO
     */
    private $db;

    public function __construct(PDO $db)
    {
        $this->db = $db;
    }
```

回到 `public/index.php` ，在檔案開頭引用 `vendor/autoload.php` ：

```php
require_once __DIR__ . '/../vendor/autoload.php';
```

再將：

```php
echo json_encode(search($type, $name, $artist, $style, $year, $db));
```

改為：

```php
$dataStore = new \Lab4\DataStore($db);
echo json_encode($dataStore->search($type, $name, $artist, $style, $year));
```

執行測試。

### 提煉 SearchRules 類別

目前 `fetchDataForPlaylist` 、 `fetchDataForAlbum` 、 `fetchDataForSong` 三個方法的參數不一致，我們將它們封裝成搜尋條件類別。

建立 `src/SearchRules.php` ，內容如下：

```php
<?php

namespace Lab4;

class SearchRules
{
    private $name;
    private $artist;
    private $style;
    private $year;

    public function __construct($name, $artist, $style, $year)
    {
        $this->name = $name;
        $this->artist = $artist;
        $this->style = $style;
        $this->year = $year;
    }

    public function __get($name)
    {
        if (property_exists($this, $name)) {
            return $this->$name;
        }

        return null;
    }
}
```

將 `public/index.php` 的：

```php
echo json_encode($dataStore->search($type, $name, $artist, $style, $year));
```

改為：

```php
$searchRule = new \Lab4\SearchRules($name, $artist, $style, $year);
echo json_encode($dataStore->search($type, $searchRule));
```

回到 `DataStore` 類別，將 `fetchDataForPlaylist` 、 `fetchDataForAlbum` 、 `fetchDataForSong` 、 `search` 四個方法的參數，分別改為：

```php
fetchDataForPlaylist(SearchRules $searchRules)
fetchDataForAlbum(SearchRules $searchRules)
fetchDataForSong(SearchRules $searchRules)
search($type, SearchRules $searchRules)
```

並記得更新 docblock 。

接著找出 `search` 方法裡呼叫 `fetchDataForPlaylist` 、 `fetchDataForAlbum` 、 `fetchDataForSong` 的程式碼：

```php
    $data = $this->fetchDataForPlaylist($name);

    $data = $this->fetchDataForAlbum($name, $artist, $style, $year);

    $data = $this->fetchDataForSong($artist);
```

分別將它們的參數改成 `$searchResult` ，如下：

```php
    $data = $this->fetchDataForPlaylist($searchRules);

    $data = $this->fetchDataForAlbum($searchRules);

    $data = $this->fetchDataForSong($searchRules);
```

最後把 `fetchDataForPlaylist` 、 `fetchDataForAlbum` 、 `fetchDataForSong` 三個方法內的 `$name` 、 `$artist` 、 `$style` 、 `$year` ，分別改成：

```php
$searchRules->name
$searchRules->artist
$searchRules->style
$searchRules->year
```

執行測試。

### 重構，提煉 DataSource\Playlist 類別

建立 `src/DataSource` 資料夾。

建立 `src/DataSource/Playlist.php` ：

```php
<?php

namespace Lab4\DataSource;

class Playlist
{
}
```

將 `DataStore` 類別的 `fetchDataForPlaylist` 與 `appendSongsToPlaylist` 兩個方法搬到 `DataSource\Playlist` 類別中，並改為 `public` ；記得要引用 `SearchRule` 類別。

在 `DataStore` 類別中加入 PDO 的引用以及建構子：

```php
use PDO;

class Playlist
{
    /**
     * @var PDO
     */
    private $db;

    public function __construct(PDO $db)
    {
        $this->db = $db;
    }
```

把原來在 `DataStore::search` 裡呼叫 `fetchDataForPlaylist` 與 `appendSongsToPlaylist` 兩個方法的部份，改成呼叫新的 `DataSource\Playlist` 物件方法：

```php
        if ($type === 'playlist') {

            $dataSource = new Playlist($this->db);

            // 取得歌單資料
            $playlists = $dataSource->fetchDataForPlaylist($searchRules);

            if ($playlists) {

                // 取得歌單內歌曲資料
                $playlists = $dataSource->appendSongsToPlaylist($playlists);
```

要記得引用完整的 `DataSource\Playlist` 類別。

執行測試。

### 重構，提煉 DataSource\Album 類別

依照提煉 `DataSource\Playlist` 類別的步驟，提煉出 `DataSource\Album` 類別。

執行測試。

### 重構，提煉 DataSource\Song 類別

依照提煉 `DataSource\Playlist` 類別的步驟，提煉出 `DataSource\Song` 類別。

執行測試。

### 重構，重新命名方法

利用 PhpStorm 的 Rename 功能，將 `DataSource\Playlist` 類別的 `fetchDataForPlaylist` 及 `appendSongsToPlaylist` 兩個方法，重新命名為 `fetchData` 及 `appendSongs` 。

執行測試。

相同的步驟，將 `DataSource\Album` 類別的 `fetchDataForAlbum` 及 `appendSongsToAlbum` 兩個方法，重新命名為 `fetchData` 及 `appendSongs` 。

執行測試。

最後將 `DataSource\Song` 類別的 `fetchDataForSong` 方法，重新命名為 `fetchData` 。

執行測試。

### 重構，用 Exception 取代 error 變數

在 `DataSource\Playlist::fetchData` 方法，當沒有資料時丟出一個異常：

```php
    if ($playlists) {
        // 取得歌單內歌曲資料
        $playlists = $this->appendSongs($playlists);
    } else {
        throw new Exception('not found');
    }
```

並記得引用 `Exception` 類別及更新 docblock 。

依照此模式，修改 `DataSource\Album::fetchData` 及 `DataSource\Song::fetchData` 兩個方法：

```php
    if ($albums) {
        // 取得專輯內歌曲資料
        $albums = $this->appendSongs($albums);
    } else {
        throw new Exception('not found');
    }
```

```php
    if (empty($songs)) {
        throw new Exception('not found');
    }
```

修改 `DataStore::search` 方法，用一個 `try...catch` 包住 `if...else` ：

```php
    try {
        if ($type === 'playlist') {
            // ...
        }
    } catch (Exception $e) {
        $status = 0;
        $message = $e->getMessage();
    }
```

移除所有：

```php
    if (empty($data)) {
        $status = 0;
        $message = 'not found';
    }
```

將：

```php
    // 類型錯誤
    $status = 0;
    $message = 'type error';
```

改成：

```php
    // 類型錯誤
    throw new Exception('type error');
```

執行測試。

### 重構，引入 Null Object

建立 `src/DataSources/TypeError.php` ，內容如下：

```php
<?php

namespace Lab4\DataSource;

use Exception;
use Lab4\SearchRules;
use PDO;

class TypeError
{
    /**
     * @var PDO
     */
    private $db;

    public function __construct(PDO $db)
    {
        $this->db = $db;
    }

    /**
     * @param SearchRules $searchRules
     * @return array
     * @throws Exception
     */
    public function fetchData(SearchRules $searchRules)
    {
        throw new Exception('type error');
    }
}
```

將 `DataSource::search` 方法裡的：

```php
    throw new Exception('type error');
```

改成：

```php
    // 類型錯誤
    $dataSource = new TypeError($this->db);

    $data = $dataSource->fetchData($searchRules);
```

並引用 `DataSource\TypeError` 類別。

執行測試。

### 重構，提煉抽象的 DataSource 類別

建立 `src/DataSource.php` ，內容如下：

```php
<?php

namespace Lab4;

use Exception;
use PDO;

abstract class DataSource
{
    /**
     * @var PDO
     */
    protected $db;

    public function __construct(PDO $db)
    {
        $this->db = $db;
    }

    /**
     * @param SearchRules $searchRules
     * @return array
     * @throws Exception
     */
    abstract public function fetchData(SearchRules $searchRules);
}
```

讓 `DataSource\Playlist` 類別繼承 `DataSource` 類別，並移除 PDO 相關程式碼：

```php
class Playlist extends DataSource
{
```

執行測試。

依照此模式，分別處理 `DataSource\Album` 、 `DataSource\Song` 與 `DataSource\TypeError` 三個類別並執行測試。

### 重構，提煉簡單工廠方法

整理 `DataStore::search` 的程式碼結構，把 `if...else` 裡的重複程式碼移出來：

```php
try {
    if ($type === 'playlist') {
        $dataSource = new Playlist($this->db);
    } elseif ($type === 'album') {
        $dataSource = new Album($this->db);
    } elseif ($type === 'song') {
        $dataSource = new Song($this->db);
    } else {
        $dataSource = new TypeError($this->db);
    }
    $data = $dataSource->fetchData($searchRules);
} catch (Exception $e) {
    $status = 0;
    $message = $e->getMessage();
}
```

將 `if...else` 提煉成 `createDataSource` 方法：

```php
    try {
        $dataSource = $this->createDataSource($type);
        $data = $dataSource->fetchData($searchRules);
    } catch (Exception $e) {
        $status = 0;
        $message = $e->getMessage();
    }

    /**
     * @param $type
     * @return Album|Playlist|Song|TypeError
     */
    private function createDataSource($type)
    {
        if ($type === 'playlist') {
            // 取得歌單資料
            $dataSource = new Playlist($this->db);
        } elseif ($type === 'album') {
            // 取得專輯資料
            $dataSource = new Album($this->db);
        } elseif ($type === 'song') {
            // 取得歌曲資料
            $dataSource = new Song($this->db);
        } else {
            // 類型錯誤
            $dataSource = new TypeError($this->db);
        }
        return $dataSource;
    }
```

利用 PHP 的動態類別名稱特色，將 `createDataSource` 改成：

```php
/**
 * @param $type
 * @return DataSource
 */
private function createDataSource($type)
{
    $className = DataSource::class . '\\' . ucfirst($type);

    if (class_exists($className)) {
        $dataSource = new $className($this->db);
    } else {
        $dataSource = new TypeError($this->db);
    }
    return $dataSource;
}
```

## 加入測試案例

##　設定 PHPUnit 執行環境

用 composer 安裝 Mockery ：

```bash
composer require mockery/mockery --dev
```

在 `phpunit.xml` 中加入：

```xml
    <filter>
        <whitelist>
            <directory suffix=".php">src/</directory>
        </whitelist>
    </filter>
```

### DataStore 類別的功能測試

建立 `tests/Functional` 資料夾。

建立 `tests/Functional/DataStoreTest.php` ，內容為：

```php
<?php

namespace Functional;

use Lab4\DataStore;
use Mockery as m;
use Mockery\MockInterface;
use PDO;
use PHPUnit_Framework_TestCase;

class DataStoreTest extends PHPUnit_Framework_TestCase
{
    /**
     * @var MockInterface
     */
    protected $db;

    /**
     * @var DataStore
     */
    protected $dataStore;

    protected function setUp()
    {
        $this->db = new PDO('sqlite:' . __DIR__ . '/../../database/example.sqlite');
        $this->dataStore = new DataStore($this->db);
    }
}
```

加入抓取歌單資料成功的測試案例：

```php

    /**
     * @group functional
     */
    public function testSearchPlaylistSuccess()
    {
        // Arrange
        $searchRules = new SearchRules('精選', '', '', '');

        // Act
        $searchResult = $this->dataStore->search('playlist', $searchRules);

        // Assert
        $this->assertArrayHasKey('data', $searchResult);
        $this->assertArrayHasKey('status', $searchResult);
        $this->assertArrayHasKey('message', $searchResult);
        $this->assertEquals(-1, $searchResult['status']);
        $this->assertEquals('', $searchResult['message']);

        foreach ($searchResult['data'] as $data) {
            $this->assertArrayHasKey('name', $data);
            $this->assertArrayHasKey('songs', $data);
            $this->assertContains('精選', $data['name']);
        }
    }
```

記得要引用 `SearchRules` 類別。

用以下指令來執行測試。

```bash
phpunit --group=functional --coverage-html report
```

加入找不到歌單資料的測試案例：

```php
    /**
     * @group functional
     */
    public function testSearchPlaylistFail()
    {
        // Arrange
        $searchRules = new SearchRules('優勝', '', '', '');

        // Act
        $searchResult = $this->dataStore->search('playlist', $searchRules);

        // Assert
        $this->assertArrayHasKey('data', $searchResult);
        $this->assertArrayHasKey('status', $searchResult);
        $this->assertArrayHasKey('message', $searchResult);
        $this->assertEquals(0, $searchResult['status']);
        $this->assertEquals('not found', $searchResult['message']);
    }
```

執行測試。

加入沒有對應類型的測試案例：

```php
    /**
     * @group functional
     */
    public function testTypeError()
    {
        // Arrange
        $searchRules = new SearchRules('', '', '', '');

        // Act
        $searchResult = $this->dataStore->search('', $searchRules);

        // Assert
        $this->assertArrayHasKey('data', $searchResult);
        $this->assertArrayHasKey('status', $searchResult);
        $this->assertArrayHasKey('message', $searchResult);
        $this->assertEquals(0, $searchResult['status']);
        $this->assertEquals('type error', $searchResult['message']);
    }
```

執行測試。

依照這個模式，加入對 `album` 及 `song` 的兩種資料類型的測試案例。

### 加入單元測試

建立 `tests/Unit` 資料夾。

建立 `tests/Unit/PlaylistTest.php` ，內容為：

```php
<?php

namespace Unit;

use Lab4\DataSource\Playlist;
use Mockery as m;
use Mockery\MockInterface;
use PDO;
use PHPUnit_Framework_TestCase;

class dataSourceTest extends PHPUnit_Framework_TestCase
{
    /**
     * @var MockInterface
     */
    protected $db;

    /**
     * @var Playlist
     */
    protected $dataSource;

    protected function setUp()
    {
        $this->db = m::mock(PDO::class, ['sqlite::memory:']);
        $this->dataSource = new Playlist($this->db);
    }

    protected function tearDown()
    {
        m::close();
    }
}
```

加入抓取歌單資料成功的測試案例：

```php
    /**
     * @group unit
     */
    public function testFetchDataSuccess()
    {
        // Arrange
        $this->db->shouldReceive('query->fetchAll')
            ->with(PDO::FETCH_ASSOC)
            ->andReturnValues([
                [ // 第一次呼叫 fetchAll
                    [
                        'id' => 1,
                        'name' => '周杰倫歷年精選',
                    ],
                ],
                [ // 第二次呼叫 fetchAll
                    ['id' => 1,],
                ],
            ]);
        $searchRules = new SearchRules('精選', '', '', '');

        // Act
        $searchResult = $this->dataStore->search('playlist', $searchRules);

        // Assert
        $this->assertArrayHasKey('data', $searchResult);
        $this->assertArrayHasKey('status', $searchResult);
        $this->assertArrayHasKey('message', $searchResult);
        $this->assertEquals(-1, $searchResult['status']);
        $this->assertEquals('', $searchResult['message']);

        foreach ($searchResult['data'] as $data) {
            $this->assertArrayHasKey('name', $data);
            $this->assertArrayHasKey('songs', $data);
            $this->assertContains('精選', $data['name']);
        }
    }
```


記得要引用 `SearchRules` 類別。

用以下指令來執行測試。

```bash
phpunit --group=unit --coverage-html report
```

加入找不到歌單資料的測試案例：

```php
    /**
     * @group unit
     */
    public function testSearchPlaylistFail()
    {
        $this->db->shouldReceive('query->fetchAll')
            ->with(PDO::FETCH_ASSOC)
            ->andReturnValues([
                [], [],
            ]);
        // Arrange
        $searchRules = new SearchRules('優勝', '', '', '');

        // Act
        $searchResult = $this->dataStore->search('playlist', $searchRules);

        // Assert
        $this->assertArrayHasKey('data', $searchResult);
        $this->assertArrayHasKey('status', $searchResult);
        $this->assertArrayHasKey('message', $searchResult);
        $this->assertEquals(0, $searchResult['status']);
        $this->assertEquals('not found', $searchResult['message']);
    }
```

執行測試。

加入沒有對應類型的測試案例：

```php
    /**
     * @group functional
     */
    public function testTypeError()
    {
        // Arrange
        $searchRules = new SearchRules('', '', '', '');

        // Act
        $searchResult = $this->dataStore->search('', $searchRules);

        // Assert
        $this->assertArrayHasKey('data', $searchResult);
        $this->assertArrayHasKey('status', $searchResult);
        $this->assertArrayHasKey('message', $searchResult);
        $this->assertEquals(0, $searchResult['status']);
        $this->assertEquals('type error', $searchResult['message']);
    }
```

執行測試。
