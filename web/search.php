<?php

// library
require_once 'NeteaseMusicAPI.php';
require_once 'KyleUTILs.php';

// require api
$api = new NeteaseMusicAPI();
$data = $api->search($_GET['s']);

// processing result
$result = json_decode($data);
$_array = json_decode(json_encode($result, JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES),true); //再把json字符串格式化为数组  

// processing data
$data = vdf_encode($_array['result'], true);

// file name
if(isset($_GET['steam'])){
	$name = "result_" . $_GET['steam'];
}else{
    $name = 'unnamed';
}

// output
Header("Content-type: text/plain"); 
Header("Content-Disposition: attachment; filename='". $name .".kv'");
echo $data;

?>