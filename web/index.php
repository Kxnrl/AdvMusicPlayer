<?php 
/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          index.php                                      */
/*  Description:   An advanced music player.                      */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2018  Kyle                                      */
/*  2018/07/04 02:02:11                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/



// ugh? no action?
if(!isset($_GET['action']) || empty($_GET['action']) || !in_array($_GET['action'], array('search', 'player', 'cached', 'lyrics'))) {
    http_response_code(400);
    exit(400);
}

if(!isset($_GET['engine']) || empty($_GET['engine']) || !in_array($_GET['engine'], array('netease', 'tencent', 'xiami', 'kugou', 'baidu'))) {
    http_response_code(400);
    exit(400);
}

if(!isset($_GET['song']) || empty($_GET['song'])) {
    http_response_code(400);
    exit(400);
}

require_once 'library/ktools.php';
require_once 'library/kmusic.php';
use Kxnrl\Music;
use Kxnrl\KeyValues;
use Metowolf\Meting;

try {
    switch($_GET['action']) {
        case 'search':
            $engine = new Meting($_GET['engine']);
            $json = $engine->format(true)->search($_GET['song'], ['page' => 1, 'limit' => (isset($_GET['limit']) ? $_GET['limit'] : 30)]);
            $data = json_decode($json, true);
            $kv = new KeyValues("Song", $data);
            $result = $kv->ExportToString();
            header("Content-type: text/plain"); 
            header("Content-Disposition: attachment; filename='" . $_GET['song'] . ".kv'");
            break;
        case 'player':
            $result = "<html><head><title>Advanced Music Player Motd - by Kyle \"Kxnrl\" Frankiss</title><meta name='description' content='Advanced Music Player' /><meta name='author' content='Kyle' /><meta name='copyright' content='2015-2018 Kyle' /><link rel='icon' type='image/png' href='//kxnrl.com/assets/images/favicon.png' /></head><body><audio id='music' src='" . $config['uri_prefix']['mp3'] .$_GET['engine'] ."/" . $_GET['song'] . ".mp3' autoplay='autoplay' />";
            if(isset($_GET['volume']) && !empty($_GET['volume'])) {
                $volume = round($_GET['volume'] / 100, 2);
                $result .= "<script type='text/javascript'>window.onload=function(){document.getElementById('music').volume=$volume;};</script>";
            }
            $result .= "</body></html>";
            break;
        case 'cached':
            $engine = new Music($_GET['engine'], $_GET['song'], true);
            $result = "success!";
            header("Content-type: text/plain; charset=UTF-8"); 
            break;
        case 'lyrics':
            $engine = new Music($_GET['engine'], $_GET['song'], true);
            $result = $engine->lrcstr;
            header("Content-type: text/plain"); 
            header("Content-Disposition: attachment; filename='" . $_GET['song'] . ".lrc'");
            break;
        default:
            http_response_code(400);
            exit(400);
    }
} catch (Exception $e) {
    http_response_code(404);
    die(404);
}

echo $result;

?>