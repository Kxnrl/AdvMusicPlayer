<?php
require_once 'NeteaseMusicAPI.php';

$api = new NeteaseMusicAPI();

$result = $api->url($_GET['id']);


$data=json_decode($result);
header('Content-type: application/json; charset=UTF-8');

echo json_encode($data,JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES);

?>