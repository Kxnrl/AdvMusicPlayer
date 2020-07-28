<?php
/******************************************************************/
/*                                                                */
/*                     Advanced Music Player                      */
/*                                                                */
/*                                                                */
/*  File:          HandleException.php                            */
/*  Description:   An advanced music player.                      */
/*                                                                */
/*                                                                */
/*  Copyright (C) 2020  Kyle                                      */
/*  2020/07/28 19:57:11                                           */
/*                                                                */
/*  This code is licensed under the GPLv3 License.                */
/*                                                                */
/******************************************************************/



namespace Kxnrl;

class HandleException extends \Exception
{
    function  __construct($message) {

        $fp = fopen(__DIR__ . "/errorlog.php", "a+");
        fputs($fp, "<?PHP exit;?>    ");
        fputs($fp, $message);
        fputs($fp, "\n");
        fclose($fp);

        //parent::__construct($message);
    }
}

?>