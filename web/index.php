<?php 

// ugh? no action?
if(!isset($_GET['action']) || empty($_GET['action']) || !in_array($_GET['action'], array('search', 'player', 'cached', 'lyrics'))) {
    http_response_code(404);
    exit(404);
}

if(!isset($_GET['engine']) || empty($_GET['engine']) || !in_array($_GET['engine'], array('netease', 'tencent', 'xiami', 'kugou', 'baidu'))) {
    http_response_code(404);
    exit(404);
}

if(!isset($_GET['song']) || empty($_GET['song'])) {
    http_response_code(404);
    exit(404);
}

require_once 'library/ktools.php';
require_once 'library/kmusic.php';
use Kxnrl\Music;
use Kxnrl\KeyValues;

try {
    switch($_GET['action']) {
        case 'search':
            $search = new Meting($_GET['engine']);
            $json = $api->format(true)->search($_GET['song'], ['page' => 1, 'limit' => (isset($_GET['limit']) ? $_GET['limit'] : 30)]);
            $data = json_decode($json, true);
            $kv = new KeyValues($data);
            $result = $kv->ExportToString();
            header("Content-type: text/plain"); 
            header("Content-Disposition: attachment; filename='search_results.kv'");
            break;
        case 'player':
            $result = "<html><head><title>Advanced Music Player Motd</title><meta name='description' content='Advanced Music Player' /><meta name='author' content='Kyle' /><meta name='copyright' content='2015-2018 Kyle' /></head><body><audio id='music' src='https://static.kxnrl.com/musics/". $_GET['engine'] ."/" . $_GET['song'] . ".mp3' autoplay='autoplay' />";
            if(isset($_GET['volume']) && !empty($_GET['volume'])) {
                $volume = round($_GET['volume'] / 100, 2);
                $result .= "<script type='text/javascript'>window.onload=function(){document.getElementById('music').volume=$volume;};</script>";
            }
            $result .= "</body></html>";
            break;
        case 'cached':
            $engine = new Music($_GET['engine'], $_GET['song'], true);
            $result = "success!";
            break;
        case 'lyrics':
            $engine = new Music($_GET['engine'], $_GET['song'], true);
            $result = $engine->lrcstr;
            header("Content-type: text/plain; charset=UTF-8"); 
            break;
        default:
            http_response_code(404);
            exit(404);
    }
} catch (Exception $e) {
    http_response_code(404);
    die(404);
}

echo $result;

?>