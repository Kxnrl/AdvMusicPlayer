<?php
/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          search.php                                     */
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

if(!isset($_GET['s']) || empty($_GET['s'])){
    LogMessage("Search -> WTF YOU DOING? EMPTY PARAM!");
    die(404);
}

// require api
$api = new NeteaseMusicAPI();
$data = $api->search($_GET['s']);

// processing result
$result = json_decode($data);
$_array = json_decode(json_encode($result, JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES),true); //再把json字符串格式化为数组  

if(!is_array($_array)){
    print_r($_array);
    LogMessage($_array);
    die(1);
}

// processing data
$data = vdf_encode($_array['result'], true);

// file name
if(isset($_GET['steam']) && !empty($_GET['steam'])){
	$name = "result_" . $_GET['steam'];
}else{
    $name = 'unnamed';
}

// output
Header("Content-type: text/plain"); 
Header("Content-Disposition: attachment; filename='". $name .".kv'");
echo $data;

?>