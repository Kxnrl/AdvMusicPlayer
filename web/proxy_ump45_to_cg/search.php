<?php

ini_set("display_errors", "On");
error_reporting(E_ALL | E_STRICT);

if(!isset($_GET['s']) || empty($_GET['s'])){
    die(404);
}

$dir = __DIR__ . "/kvs";
if(!file_exists($dir)){
    if(!mkdir($dir, 0777, true)){
        echo 'create director failed!';
        exit(404);
    }
}else{
    chmod($dir, 0777);
}

$file = $dir . "/" . md5(strtolower($_GET['s'])) .".kv";
if(file_exists($file) && filemtime($file) > time()-8)
{
    $fp = fopen($file, "r");
    $data = fread($fp, filesize($file));
    fclose($fp);
}else{
    $encode = urlencode($_GET['s']);
    $url = "music.csgogamers.com/api/search.php?s=$encode";

    $curl = curl_init($url);
    curl_setopt($curl, CURLOPT_USERAGENT, "Mozilla/4.0 (compatible; MSIE 5.01; Windows NT 5.0)");
    curl_setopt($curl, CURLOPT_VERBOSE, true);
    curl_setopt($curl, CURLOPT_HEADER, false);
    curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($curl, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
    $data = curl_exec($curl);
    //print_r("Info: \n");
    $info = curl_getinfo($curl);
    //print_r($info);
    //print_r("\n");
    //print_r("Error: \n");
    //print_r(curl_error($curl));
    //print_r("\n");
    curl_close($curl);
    if(strlen($data) > 1024 && $info['http_code'] == 200)
        file_put_contents($file, $data);
}

// output
Header("Content-type: text/plain"); 
Header("Content-Disposition: attachment; filename='". $_GET['s'] .".kv'");
echo $data;

?>