<?php
/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          player.php                                     */
/*  Description:   An advance music player in source engine game. */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2018  Kyle                                      */
/*  2018/01/01 04:02:39                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/



error_reporting(E_ALL^E_WARNING^E_NOTICE);

// header
header('Content-type: text/html; charset=UTF-8');

// library
require_once 'NeteaseMusicAPI.php';
require_once 'KyleUTILs.php';

if(!isset($_GET['id']) || empty($_GET['id'])){
    LogMessage("Player -> WTF YOU DOING? EMPTY PARAM!");
    die(404);
}

$path = __DIR__ . "/cached/".$_GET['id'].".mp3";
if(isset($_GET['cache']) && !empty($_GET['cache']) && $_GET['cache'] == 1 && file_exists($path) && filesize($path) > 524288){
    $url = "cached/".$_GET['id'].".mp3";
}elseif(isset($_GET['proxy']) && !empty($_GET['proxy']) && $_GET['proxy'] == 1){
    $url = file_get_contents("https://music.ump45.moe/geturl.php?id=$_GET[id]");
}else{
    // get result
    $api = new NeteaseMusicAPI();
    $result = $api->url($_GET['id']);

    // get url
    $json_d = json_decode($result);
    $json_e = json_encode($json_d,JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES);
    $de_json = json_decode($json_e, true);
    $url = $de_json['data'][0]['url'];
}

echo '<html>';
echo '<head>';
echo '<title>【CG】 Advanced Music Player Motd</title>';
echo '<meta name="description" content="Advanced Music Player" />';
echo '<meta name="author" content="Kyle" />';
echo '<meta name="copyright" content="2015-2018 Kyle" />';
echo '</head>';
echo '<body>';
echo '<audio id="music" src="'.$url.'" autoplay="autoplay"></audio>';

if(isset($_GET['volume']) && !empty($_GET['volume'])){
	$volume = round($_GET['volume'] / 100, 2);
	echo "<script type='text/javascript'>window.onload=function(){document.getElementById('music').volume=$volume;};</script>";
}

echo '</body>';
echo '</html>';

?>