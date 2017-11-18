<?php

// header
//header('Content-type: text/html; charset=UTF-8');

// library
require_once 'NeteaseMusicAPI.php';
require_once 'KyleUTILs.php';

if(!isset($_GET['id']) || empty($_GET['id'])){
    LogMessage("Cache -> WTF YOU DOING? EMPTY PARAM!");
    die(404);
}

$dir = __DIR__ . "/cached";
if(!file_exists($dir)){
    if(!mkdir($dir, 0777, true)){
        LogMessage("Cache -> create cached director failed.");
        echo 'create director failed!';
        exit(404);
    }else{
        LogMessage("Cache -> We created a cached director.");
    }
}else{
    chmod($dir, 0777);
}

$path = __DIR__ . "/cached/".$_GET['id'].".mp3";

if(file_exists($path)){
    if(filesize($path) > 524288){
        echo 'file_exists!';
        die(200);
    }else{
        unlink($path);
    }
}

// get result
$api = new NeteaseMusicAPI();
$result = $api->url($_GET['id']);

// get url
$json_d = json_decode($result);
$json_e = json_encode($json_d,JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES);
$de_json = json_decode($json_e, true);
$url = $de_json['data'][0]['url'];

if(strlen($url) < 24){
    echo 'Can not get url.  -> '.$url;
    LogMessage("Cache -> Can not get url. -> $url");
    exit(404);
}

// get mp3
$curl = curl_init();
curl_setopt($curl, CURLOPT_URL, $url);
curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($curl, CURLOPT_HEADER, 0);
curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
$file = curl_exec($curl);
curl_close($curl);

// save file
if(file_put_contents($path, $file)){
    if(filesize($path) > 524288){
        echo 'success!';
    }else{
        echo 'file error -> '.$path.'   size: '.filesize($path);
    }
}else{
    echo 'put file failed: '.$path.'   length: '.strlen($file);
    LogMessage("Cache -> put file failed -> $path   length: ".strlen($file));
}
?>