<?php

namespace Kxnrl;

class HandleException extends \Exception
{
    function  __construct($message) {

        $fp = fopen(__DIR__ . "/errorlog.php", "a+");
        fputs($fp, "<?PHP exit;?>    ");
        fputs($fp, $message);
        fputs($fp, "\n");
        fclose($fp);

        //parent::__construct($a, $b);
    }
}

?>