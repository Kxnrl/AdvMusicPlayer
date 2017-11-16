<?php
// a simple parser for Valve's KeyValue format
// https://developer.valvesoftware.com/wiki/KeyValues
//
// author: Rossen Popov, 2015-2016
function vdf_encode($arr, $pretty = false) {
    if(!is_array($arr)) {
        trigger_error("vdf_encode expects parameter 1 to be an array, " . gettype($arr) . " given.", E_USER_NOTICE);
        return NULL;
    }
    $pretty = (boolean) $pretty;
    return vdf_encode_step($arr, $pretty, 0);
}
function vdf_encode_step($arr, $pretty, $level) {
    if(!is_array($arr)) {
        trigger_error("vdf_encode encounted " . gettype($arr) . ", only array or string allowed (depth ".$level.")", E_USER_NOTICE);
        return NULL;
    }
    $buf = "";
    $line_indent = ($pretty) ? str_repeat("    ", $level) : "";
    foreach($arr as $k => $v) {
        if(!is_array($v)) {
			if($k != "songCount")
            $buf .= "$line_indent\"$k\"    \"$v\"\n";
        }
        else {
            $res = vdf_encode_step($v, $pretty, $level + 1);
            if($res === NULL) return NULL;
            $buf .= "$line_indent\"$k\"\n$line_indent{\n$res$line_indent}\n";
        }
    }
    return $buf;
}
?>