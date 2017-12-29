<?php

// library
require_once 'NeteaseMusicAPI.php';
require_once 'KyleUTILs.php';

if(!isset($_GET['id']) || empty($_GET['id'])){
    LogMessage("Lyric -> WTF YOU DOING? EMPTY PARAM!");
    die(404);
}

// header
Header("Content-type: text/plain; charset=UTF-8"); 

$api = new NeteaseMusicAPI();
$result = $api->lyric($_GET['id']);

// get url
$json_d = json_decode($result);
$json_e = json_encode($json_d,JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES);
$de_json = json_decode($json_e, true);
print_r($de_json['lrc']['lyric']);
?>