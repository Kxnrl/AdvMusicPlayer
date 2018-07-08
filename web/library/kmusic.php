<?php
/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          kmusic.php                                     */
/*  Description:   An advanced music player.                      */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2018  Kyle                                      */
/*  2018/07/04 02:02:11                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/



namespace Kxnrl;

require_once 'config.php';
require_once 'Meting.php';
require_once 'Exception/HandleException.php';

use Metowolf\Meting;
use Kxnrl\HandleException;

class Music
{
    // global
    public $engine;
    public $songid;
    public $name;
    public $album;
    public $artist;
    public $length;
    public $server;

    // mp3
    public $mp3_id;
    public $mp3loc;
    public $mp3uri;

    // lyric
    public $lrc_id;
    public $lrcloc;
    public $lrcuri;
    public $lrcstr;
    
    // cover
    public $pic_id;
    public $picloc;
    public $picuri;

    public function __construct($engine, $id, $load = true)
    {
        global $config;

        if(!in_array($engine, array('netease', 'tencent', 'xiami', 'kugou', 'baidu'))) {
            
            if($engine == 'custom') {
                $this->mp3uri = $config['uri_prefix']['mp3'] . $this->engine . "/" . $this->songid . ".mp3";
                $this->lrcuri = $config['uri_prefix']['lrc'] . $this->engine . "/" . $this->songid . ".lrc";
                $this->picuri = $config['uri_prefix']['pic'] . $this->engine . "/" . $this->songid . ".jpg";
                return;
            }

            throw new HandleException("Engine $engine not support.");
        }

        if(!file_exists($config['uri_prefix']['dir']) && !mkdir($config['uri_prefix']['dir'], 0755, true)) {
            throw new HandleException("Failed to create data folder.");
        }

        $this->songid = $id;
        $this->engine = $engine;

        $this->server = new Meting($this->engine);

        $this->song();

        if($load) {
            $this->mp3();
            $this->lrc();
            $this->pic();
        }
    }

    public function song()
    {
        //static 
        static $dictionary = array();

        if(isset($dictionary[$this->engine][$this->songid])) {
            $this->name = $dictionary[$this->engine][$this->songid]['name'];
            $this->album = $dictionary[$this->engine][$this->songid]['album'];
            $this->artist = $dictionary[$this->engine][$this->songid]['artist'];
            $this->length = $dictionary[$this->engine][$this->songid]['length'];
            return;
        }

        $json = $this->server->format(true)->song($this->songid);
        $song = json_decode($json, true);

        if(!isset($song[0])) {
            throw new HandleException("Null results. -> json[" . $json . "]");
        }

        if($song[0]['id'] != $this->songid) { throw new HandleException("Access is denied. id[" . $song[0]['id'] . "] songid[" . $this->songid . "]"); }

        $this->name = $song[0]['name'];
        $this->album = $song[0]['album'];
        $this->length = $song[0]['length'];

        if(is_array($song[0]['artist'])) {
            foreach($song[0]['artist'] as $nmsl) {
                if(strlen($this->artist) == 0) {
                    $this->artist = $nmsl;
                } else {
                    $this->artist .= "/";
                    $this->artist .= $nmsl;
                }
            }
        } else {
            $this->artist = $song[0]['artist'];
        }

        $this->mp3_id = $song[0]['url_id'];
        $this->lrc_id = $song[0]['lyric_id'];
        $this->pic_id = $song[0]['pic_id'];

        $dictionary[$this->engine][$this->songid]['name'] = $this->name;
        $dictionary[$this->engine][$this->songid]['album'] = $this->name;
        $dictionary[$this->engine][$this->songid]['artist'] = $this->artist;
        $dictionary[$this->engine][$this->songid]['length'] = $this->length;
    }

    public function mp3()
    {
        global $config;

        $this->mp3loc = $config['uri_prefix']['dir'] . '/musics/' . $this->engine . '/' . $this->songid . '.mp3';
        
        if(!file_exists($config['uri_prefix']['dir'] . '/musics/' . $this->engine) && !mkdir($config['uri_prefix']['dir'] . '/musics/' . $this->engine, 0755, true)) {
            throw new HandleException("Failed to create folder to store mp3 files.");
        }

        if(file_exists($this->mp3loc)) {
            if(filesize($this->mp3loc) > 524288){
                $this->mp3uri = $config['uri_prefix']['mp3'] . $this->engine . "/" . $this->songid . ".mp3";
                return;
            }
            unlink($this->mp3loc);
        }

        $json = $this->server->format(true)->url($this->mp3_id, 320);
        $data = json_decode($json, true);

        if(!isset($data['url']) || strlen($data['url']) <= 15) { throw new HandleException("Access is denied. mp3url[" . $data['url'] . "]. json[" . $json . "]"); }

        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $data['url']);
        curl_setopt($curl, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, 0);
        curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 10);

        for ($i = 0; $i < 3; $i++) {
            $file = curl_exec($curl);
            $info = curl_getinfo($curl);
            $error = curl_errno($curl);
            $status = $error ? curl_error($curl) : '';
            if(!$error) {
                break;
            }
        }

        curl_close($curl);
        
        if($info['http_code'] >= 300) {
            throw new HandleException("Failed to download song file. id[" . $this->mp3_id . "] url[" . $data['url'] . "] status[" . $status . "] HttpCode[". $info['http_code'] . "]");
        }

        if(file_put_contents($this->mp3loc, $file, LOCK_EX) === FALSE) {
            throw new HandleException("Failed to put the song file.");
        }

        if(filesize($this->mp3loc) <= 524288) {
            unlink($this->mp3loc);
            throw new HandleException("Wrong song file. id[" . $this->mp3_id . "] url[" . $data['url'] . "]");
        }

        $this->mp3uri = $config['uri_prefix']['mp3'] . $this->engine . "/" . $this->songid . ".mp3";
    }

    public function lrc()
    {
        global $config;
        
        $this->lrcloc = $config['uri_prefix']['dir'] . '/lyrics/' . $this->engine . '/' . $this->songid . '.lrc';
        
        if(!file_exists($config['uri_prefix']['dir'] . '/lyrics/' . $this->engine) && !mkdir($config['uri_prefix']['dir'] . '/lyrics/' . $this->engine, 0755, true)) {
            throw new HandleException("Failed to create folder to store lrc files.");
        }

        if(file_exists($this->lrcloc)) {
            if(filesize($this->lrcloc) >= 15) {
                $lrcold = file_get_contents($this->lrcloc);
                if(strpos($lrcold, "[0:00] ... Music ...") !== false) {
                    $this->lrcstr = $lrcold;
                    $this->lrcuri = $config['uri_prefix']['lrc'] . $this->engine . "/" . $this->songid . ".lrc";
                    return;
                }
            }
            unlink($this->lrcloc);
        }

        $data = json_decode($this->server->format(true)->lyric($this->lrc_id), true);
 
        if(!isset($data['lyric']) || strlen($data['lyric']) < 15) { 
            $len = $this->length;
            $crt = 10;
            $data['lyric'] = "[0:00] ... Music ...";
            do{
                $data['lyric'] .= "\n[$crt:00] ... Music ...";
                $crt += 10;
            } while (($len - $crt) > 0);
        }

        if(file_put_contents($this->lrcloc, $data['lyric'], LOCK_EX) === FALSE) {
            throw new HandleException("Failed to put the lyric file.");
        }

        if(filesize($this->lrcloc) <= 15) {
            unlink($this->lrcloc);
            throw new HandleException("Wtf lyric string: " . $data['lyric']);
        }

        $this->lrcstr = $data['lyric'];
        $this->lrcuri = $config['uri_prefix']['lrc'] . $this->engine . "/" . $this->songid . ".lrc";
    }

    public function pic()
    {
        global $config;

        $this->picloc = $config['uri_prefix']['dir'] . '/covers/' . $this->engine . '/' . $this->songid . '.jpg';
        
        if(!file_exists($config['uri_prefix']['dir'] . '/covers/' . $this->engine) && !mkdir($config['uri_prefix']['dir'] . '/covers/' . $this->engine, 0755, true)) {
            throw new HandleException("Failed to create folder to store jpg files.");
        }

        if(file_exists($this->picloc)) {
            if(filesize($this->picloc) > 1024){
                $this->picuri = $config['uri_prefix']['pic'] . $this->engine . "/" . $this->songid . ".jpg";
                return;
            }
            unlink($this->picloc);
        }

        $json = $this->server->format(true)->pic($this->pic_id);
        $data = json_decode($json, true);

        if(!isset($data['url']) || strlen($data['url']) <= 15) { throw new HandleException("Access is denied. picurl[" . $data['url'] . "]. json[" . $json . "]"); }

        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $data['url']);
        curl_setopt($curl, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, 0);
        curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 10);

        for ($i = 0; $i < 3; $i++) {
            $file = curl_exec($curl);
            $info = curl_getinfo($curl);
            $error = curl_errno($curl);
            $status = $error ? curl_error($curl) : '';
            if(!$error) {
                break;
            }
        }

        curl_close($curl);
        
        if($info['http_code'] >= 300) {
            throw new HandleException("Failed to download cover file. id[" . $this->pic_id . "] url[" . $data['url'] . "] status[" . $status . "] HttpCode[". $info['http_code'] . "]");
        }

        if(file_put_contents($this->picloc, $file, LOCK_EX) === FALSE) {
            throw new HandleException("Failed to put the cover file.");
        }

        if(filesize($this->picloc) <= 1024) {
            unlink($this->picloc);
            throw new HandleException("Wrong cover file. id[" . $this->pic_id . "] url[" . $data['url'] . "]");
        }

        $this->picuri = $config['uri_prefix']['pic'] . $this->engine . "/" . $this->songid . ".jpg";
    }
}