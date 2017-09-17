<?php

// header
header('Content-type: text/html; charset=UTF-8');

// require library
require_once 'NeteaseMusicAPI.php';

// get result
$api = new NeteaseMusicAPI();
$result = $api->lyric($_GET['id']);

$data=json_decode($result);

// get url
$json_d = json_decode($result);
$json_e = json_encode($json_d,JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES);
$de_json = json_decode($json_e, true);
echo $de_json[lrc][lyric];
?>