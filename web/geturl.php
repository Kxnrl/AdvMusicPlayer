<?php

$str=@file_get_contents("https://music.csgogamers.com/api/output.php?id=".$_GET[id]);
$de_json = json_decode($str, true);
$url = $de_json['data'][0]['url'];
echo $url;

?>