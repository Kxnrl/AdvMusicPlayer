<?php

ini_set("display_errors", "On");
error_reporting(E_ALL | E_STRICT);

if(!isset($_GET['s']) || empty($_GET['s'])){
    LogMessage("Search -> WTF YOU DOING? EMPTY PARAM!");
    die(404);
}

$encode = urlencode($_GET['s']);
//echo "$encode\n";
$url = "csgogamers.com/musicserver/api/search.php?s=$encode";
//echo $url;

$curl = curl_init();
curl_setopt($curl, CURLOPT_URL, $url);
curl_setopt($curl, CURLOPT_USERAGENT, "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.84 Safari/537.36");
curl_setopt($curl, CURLOPT_VERBOSE, true);
//curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
//curl_setopt($curl, CURLOPT_SSL_VERIFYHOST, true);
//curl_setopt($curl, CURLOPT_CAINFO, $cacert);
//curl_setopt($curl, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
curl_setopt($curl, CURLOPT_HEADER, 0);
//curl_setopt($curl, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
$data = curl_exec($curl);
//print_r("Info: \n");
//print_r(curl_getinfo($curl));
//print_r("\n");
//print_r("Error: \n");
//print_r(curl_error($curl));
curl_close($curl);

// output
Header("Content-type: text/plain"); 
Header("Content-Disposition: attachment; filename='". $_GET['s'] .".kv'");
echo $data;

?>