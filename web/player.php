<?php

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
echo '<title>【CG】 Advance Music Player Motd</title>';
echo '<meta name="keywords" content="CSGO社区,CSGO服务器,CSGO论坛,CG社区,CG论坛,CG服务器,CSGOGAMERS,CG,CSGO饥饿游戏,CSGO死亡奔跑,CSGO娱乐,CSGO僵尸" />';
echo '<meta name="description" content="【CG】社区是一个新成立不久的CSGO游戏社区，以娱乐为主，涵盖了目前CSGO所有的娱乐模式，还有独家的CSGO饥饿游戏模式。我们用心打造一个国内优秀的良心的CSGO游戏社区。 " />';
echo '<meta name="author" content="Kyle" />';
echo '<meta name="copyright" content="2015-2017 Kyle." />';
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