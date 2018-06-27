<?php
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
    public $artist;
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
        if(!in_array($engine, array('netease', 'tencent', 'xiami', 'kugou', 'baidu'))) {
            
            if($engine == 'custom') {
                $this->mp3uri = $config['uri_prefix']['mp3'] . $this->engine . "/" . $this->songid . ".mp3";
                $this->lrcuri = $config['uri_prefix']['lrc'] . $this->engine . "/" . $this->songid . ".lrc";
                $this->picuri = $config['uri_prefix']['pic'] . $this->engine . "/" . $this->songid . ".jpg";
                return;
            }

            throw new HandleException("Engine $engine not support.");
        }
        
        if(!file_exists(__DIR__ . '/../data') && !mkdir(__DIR__ . '/../data', 0755, true)) {
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
        $dictionary = array();

        if(isset($dictionary[$this->engine][$this->songid])){
            $this->name = $dictionary[$this->engine][$this->songid]['name'];
            $this->artist = $dictionary[$this->engine][$this->songid]['artist'];
            return;
        }

        $json = $this->server->format(true)->song($this->songid);
        $song = json_decode($json, true);

        if(!isset($song[0])) {
            throw new HandleException("Null results.");
        }

        if($song[0]['id'] != $this->songid) { throw new HandleException("Access is denied. id[" . $song[0]['id'] . "] songid[" . $this->songid . "]"); }
        
        $this->name = $song[0]['name'];
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
        $dictionary[$this->engine][$this->songid]['artist'] = $this->artist;
    }

    public function mp3()
    {
        $this->mp3loc = __DIR__ . '/../data/songs/' . $this->engine . '/' . $this->songid . '.mp3';
        
        if(!file_exists(__DIR__ . '/../data/songs/' . $this->engine) && !mkdir(__DIR__ . '/../data/songs/' . $this->engine, 0755, true)) {
            throw new HandleException("Failed to create folder to store mp3 files.");
        }

        if(file_exists($this->mp3loc)) {
            if(filesize($this->mp3loc) > 524288){
                $this->mp3uri = $config['uri_prefix']['mp3'] . $this->engine . "/" . $this->songid . ".mp3";
                return;
            }
            unlink($this->mp3loc);
        }

        $data = json_decode($this->server->format(true)->url($this->mp3_id, 320), true);

        if(!isset($data['url']) || strlen($data['url']) <= 15) { throw new HandleException("Access is denied. mp3url[" . $data['url'] . "]"); }

        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $data['url']);
        curl_setopt($curl, CURLOPT_HTTPHEADER, array("Accept: */*", "Accept-Encoding: identity;q=1, *;q=0", "Accept-Language: zh-CN,zh;q=0.9,und;q=0.8,en-US;q=0.7,en;q=0.6", "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36"));
        curl_setopt($curl, CURLOPT_IPRESOLVE, 1);
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
            throw new HandleException("Failed to download song file. id[" . $this->mp3_id . "] url[" . $data['url'] . "]");
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
        $this->lrcloc = __DIR__ . '/../data/lyrics/' . $this->engine . '/' . $this->songid . '.lrc';
        
        if(!file_exists(__DIR__ . '/../data/lyrics/' . $this->engine) && !mkdir(__DIR__ . '/../data/lyrics/' . $this->engine, 0755, true)) {
            throw new HandleException("Failed to create folder to store lrc files.");
        }

        if(file_exists($this->lrcloc)) {
            if(filesize($this->lrcloc) >= 15){
                $this->lrcstr = file_get_contents($this->lrcloc);
                $this->lrcuri = $config['uri_prefix']['lrc'] . $this->engine . "/" . $this->songid . ".lrc";
                return;
            }
            unlink($this->lrcloc);
        }

        $data = json_decode($this->server->format(true)->lyric($this->lrc_id), true);
 
        if(!isset($data['lyric']) || strlen($data['lyric']) < 15) { throw new HandleException("Lyric string is [" . $data['lyric'] . "]."); }

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
        $this->picloc = __DIR__ . '/../data/covers/' . $this->engine . '/' . $this->songid . '.jpg';
        
        if(!file_exists(__DIR__ . '/../data/covers/' . $this->engine) && !mkdir(__DIR__ . '/../data/covers/' . $this->engine, 0755, true)) {
            throw new HandleException("Failed to create folder to store jpg files.");
        }

        if(file_exists($this->picloc)) {
            if(filesize($this->picloc) > 1024){
                $this->picuri = $config['uri_prefix']['pic'] . $this->engine . "/" . $this->songid . ".jpg";
                return;
            }
            unlink($this->picloc);
        }

        $data = json_decode($this->server->format(true)->pic($this->pic_id), true);

        if(!isset($data['url']) || strlen($data['url']) <= 15) { throw new HandleException("Access is denied. picurl[" . $data['url'] . "]"); }

        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL, $data['url']);
        curl_setopt($curl, CURLOPT_HTTPHEADER, array("Accept: */*", "Accept-Encoding: identity;q=1, *;q=0", "Accept-Language: zh-CN,zh;q=0.9,und;q=0.8,en-US;q=0.7,en;q=0.6", "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36"));
        curl_setopt($curl, CURLOPT_IPRESOLVE, 1);
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
            throw new HandleException("Failed to download cover file. id[" . $this->pic_id . "] url[" . $data['url'] . "]");
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