<?php

// library
require_once 'NeteaseMusicAPI.php';
require_once 'KyleUTILs.php';

// get result
$api = new NeteaseMusicAPI();
$result = $api->url($_GET['id']);

// get url
$json_d = json_decode($result);
$json_e = json_encode($json_d, JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES);
$de_json = json_decode($json_e, true);
$url = $de_json['data'][0]['url'];

echo $url;

?>