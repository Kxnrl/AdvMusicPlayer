<?php
/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          config.php                                     */
/*  Description:   An advanced music player.                      */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2018  Kyle                                      */
/*  2018/07/04 02:02:11                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/



// Store music file/cover/lyric
$config['uri_prefix']['dir'] = '/var/www/music';

// Your website url (must end with "/")
$config['uri_prefix']['mp3'] = 'https://music.kxnrl.com/musics/';
$config['uri_prefix']['lrc'] = 'https://music.kxnrl.com/lyrics/';
$config['uri_prefix']['pic'] = 'https://music.kxnrl.com/covers/';

// If you want to use shadowsocks-libev
//$config['curl_proxy']['host'] = '127.0.0.1:1080';
//$config['curl_proxy']['type'] = CURLPROXY_SOCKS5;

?>