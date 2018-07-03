<?php
/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          ktools.php                                     */
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

class KeyValues
{
    public $str;
    public $arr;
    
    public function __construct($title, $input)
    {
        if(is_array($input)) {
            $this->str = '"' . $title . '"' .  PHP_EOL . '{' . PHP_EOL . $this->Encode($input, 1) . '}';
            $this->arr = array();
            $this->arr[$title] = $input;
        } elseif(is_string($input)) {
            $this->arr = $this->Decode($input);
            $this->str = $input;
        } else {
            throw new HandleException("Invalid keyvalues input: " . $input);
        }
    }

    public function ExportToString()
    {
        return $this->str;
    }
    
    public function ExportToArray()
    {
        return $this->arr;
    }

    private function Decode($text)
    {
        if(!is_string($text)) {
            throw new HandleException("Decode expects parameter 1 to be a string, " . gettype($text) . " given.");
        }

        if      (substr($text, 0, 2) == "\xFE\xFF")         $text = mb_convert_encoding($text, 'UTF-8', 'UTF-16BE');
        else if (substr($text, 0, 2) == "\xFF\xFE")         $text = mb_convert_encoding($text, 'UTF-8', 'UTF-16LE');
        else if (substr($text, 0, 4) == "\x00\x00\xFE\xFF") $text = mb_convert_encoding($text, 'UTF-8', 'UTF-32BE');
        else if (substr($text, 0, 4) == "\xFF\xFE\x00\x00") $text = mb_convert_encoding($text, 'UTF-8', 'UTF-32LE');

        $text = preg_replace('/^[\xef\xbb\xbf\xff\xfe\xfe\xff]*/', '', $text);
        $lines = preg_split('/\n/', $text);
        $arr = array();
        $stack = array(0=>&$arr);
        $expect_bracket = false;
        $name = "";
        $re_keyvalue = '~^("(?P<qkey>(?:\\\\.|[^\\\\"])+)"|(?P<key>[a-z0-9\\-\\_]+))([ \t]*("(?P<qval>(?:\\\\.|[^\\\\"])*)(?P<vq_end>")?|(?P<val>[a-z0-9\\-\\_]+)))?~iu';
        $j = count($lines);

        for($i = 0; $i < $j; $i++) {
            $line = trim($lines[$i]);

            if($line == "" || $line[0] == '/') { continue; }

            if($line[0] == "{") {
                $expect_bracket = false;
                continue;
            }

            if($expect_bracket) {
                throw new HandleException("Decode: invalid syntax, expected a '}' on line " . ($i+1));
            }

            if($line[0] == "}") {
                array_pop($stack);
                continue;
            }

            while(true) {
                preg_match($re_keyvalue, $line, $m);
                
                if(!$m) {
                    throw new HandleException("Decode: invalid syntax on line " . ($i+1));
                }
                
                $key = (isset($m['key']) && $m['key'] !== "") ? $m['key'] : $m['qkey'];
                $val = (isset($m['qval']) && (!isset($m['vq_end']) || $m['vq_end'] !== "")) ? $m['qval'] : (isset($m['val']) ? $m['val'] : False);
                
                if($val === False) {
                    if(!isset($stack[count($stack)-1][$key])) {
                        $stack[count($stack)-1][$key] = array();
                    }
                    $stack[count($stack)] = &$stack[count($stack)-1][$key];
                    $expect_bracket = true;
                } else {
                    if(!isset($m['vq_end']) && isset($m['qval'])) {
                        $line .= "\n" . $lines[++$i];
                        continue;
                    }
                    $stack[count($stack)-1][$key] = $val;
                }
                break;
            }
        }

        if(count($stack) !== 1)  {
            throw new HandleException("Decode: open parentheses somewhere");
        }

        return $arr;
    }

    private function Encode($arr, $level)
    {
        if(!is_array($arr)) {
            throw new HandleException("Encode encounted " . gettype($arr) . ", only array or string allowed (depth " . $level . "), string:" . $arr);
        }

        $str = "";
        $line_indent = str_repeat("    ", $level);

        foreach($arr as $key => $val) {
            if(!is_array($val)) {
                if(is_numeric($key)) {
                    $str .= "$line_indent\"". (string)$key . "\"    \"$val\"\n";
                } else {
                    $str .= "$line_indent\"$key\"    \"$val\"\n";
                }
            } else {
                $res = $this->Encode($val, $level + 1);
                if($res === null) return null;
                $str .= "$line_indent\"$key\"\n$line_indent{\n$res$line_indent}\n";
            }
        }

        return $str;
    }
}