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
/*  Copyright (C) 2020  Kyle                                      */
/*  2020/07/28 19:57:11                                           */
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

// Your websocket server
$config['websocket']['srv']['uri']['host'] = 'wss://music.kxnrl.com';
$config['websocket']['srv']['uri']['port'] = '8443'; // out stream 
$config['websocket']['srv']['cli']['port'] = '420';  // locol port listner , sasusi birthday.

// cookies
$config['cookie']['netease'] = 'appver=1.5.9; os=osx; __remember_me=true; osver=%E7%89%88%E6%9C%AC%2010.13.5%EF%BC%88%E7%89%88%E5%8F%B7%2017F77%EF%BC%89;';
$config['cookie']['tencent'] = 'pgv_pvi=22038528; pgv_si=s3156287488; pgv_pvid=5535248600; yplayer_open=1; ts_last=y.qq.com/portal/player.html; ts_uid=4847550686; yq_index=0; qqmusic_fromtag=66; player_exist=1';

?>