<?php
ini_set("display_errors", 1);
// header
//header('Content-type: text/html; charset=UTF-8');

// require library
require_once 'NeteaseMusicAPI.php';

$api = new NeteaseMusicAPI();
$result = $api->lyric($_GET['id']);

// get url
$json_d = json_decode($result);
$json_e = json_encode($json_d,JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES);
$de_json = json_decode($json_e, true);
print_r($de_json['lrc']['lyric']);
?>