<?php
/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          geturl.php                                     */
/*  Description:   An advance music player in source engine game. */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2018  Kyle   https://ump45.moe                  */
/*  2018/01/01 04:02:39                                           */
/*                                                                */
/*  This code is licensed under the MIT License (MIT).            */
/*                                                                */
/******************************************************************/



error_reporting(E_ALL^E_WARNING^E_NOTICE);

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