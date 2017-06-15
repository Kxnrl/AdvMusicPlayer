<?php
$str=@file_get_contents("https://music.csgogamers.com/api/lyric.php?id=".$_GET['id']);
$de_json = json_decode($str, true);
$arr=extract($de_json);
$ltd=extract($lrc);
echo $lyric;
?>
