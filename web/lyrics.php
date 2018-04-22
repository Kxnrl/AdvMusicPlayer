<?php
/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          lyrics.php                                     */
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