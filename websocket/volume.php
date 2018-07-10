<?php

static $dict_socket = array();
static $dict_steams = array();

echo "Starting Socket Server..." . PHP_EOL;

$server = new swoole_websocket_server("127.0.0.1", 420);

$server->on('open', function($server, $req) {
    global $dict_socket, $dict_steams;
    if(isset($dict_socket[$req->fd])) {unset($dict_socket[$req->fd]);}; 
    echo "Connection open: Id[{$req->fd}]\n";
});

$server->on('message', function($server, $frame) {
    
    global $dict_socket, $dict_steams;
    
    echo "=============[Received]=============\n";
    $data = json_decode($frame->data, true);
    if(!isset($data['restype'])) {
        echo "something went wrong\n{$frame->data}\n";
        return;
    }

    if($data['restype'] == "Init") {
        echo "SteamId: {$data['SteamId']}\n";
        echo "fVolume: {$data['fVolume']}\n";
        $dict_socket[$frame->fd] = $data;
        $dict_steams[$data['SteamId']] = $frame->fd;
    } elseif($data['restype'] == "Volume") {
        echo "SteamId: {$data['SteamId']}\n";
        echo "nVolume: {$data['nVolume']}\n";
        foreach($dict_steams as $steam => $socket) {
            if($steam == $data['SteamId']) {
                $json = array('restype' => $data['restype'], 'nVolume' => $data['nVolume']);
                $server->push($socket, json_encode($json, JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES));
                echo "Socket push Volume to AMP {$socket}\n";
                break;
            }
        }
    } elseif($data['restype'] == "SaSuSi") {
        echo "SteamId: {$data['SteamId']}\n";
        foreach($dict_steams as $steam => $socket) {
            if($steam == $data['SteamId']) {
                $json = array('restype' => "SaSuSi");
                $server->push($socket, json_encode($json, JSON_UNESCAPED_UNICODE|JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES));
                echo "Socket push SaSuSi to AMP {$socket}\n";
                break;
            }
        }
    } else {
        echo "Recv: " . $frame->data . "\n";
    }
});

$server->on('close', function($server, $fd) {
    global $dict_socket, $dict_steams;
    if(isset($dict_socket[$fd])) {unset($dict_socket[$fd]);}; 
    echo "Connection close: {$fd}\n";
});

$server->start();

?>