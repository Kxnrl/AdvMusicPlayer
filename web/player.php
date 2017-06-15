<?php

echo "<audio id='music' src='https://music.csgogamers.com/songs/".$_GET['id'].".mp3' autoplay='autoplay' />";

if($_GET['volume'])
{
	$volume = round($_GET['volume'] / 100, 2);
	echo "<script type='text/javascript'>window.onload=function(){document.getElementById('music').volume=$volume;};</script>";
}

?>