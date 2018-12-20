<?php

/**
 * Brief Class Description.
 * Complete Class Description.
 */

class MIOLOConsole
{
    private $MIOLO, $module;

    function __construct()
    {

    }

    public function getMIOLOInstance($pathMiolo, $module, $httpHost = 'miolo25')
    {
        ob_start();
        echo "MIOLO console\n\n";

        $this->module = $module;

        /**
         * Simula as variáveis do apache que são necessárias para o MIOLO
         */
        $_SERVER['DOCUMENT_ROOT']   = $pathMiolo . '/html';
        $_SERVER['HTTP_HOST']       = strlen($_SERVER['HTTP_HOST']) ? $_SERVER['HTTP_HOST'] : $httpHost;
        $_SERVER['SCRIPT_NAME']     = '/index.php';
        $_SERVER['QUERY_STRING']    = strlen($_SERVER['QUERY_STRING']) ? $_SERVER['QUERY_STRING'] : 'module=' . $this->module . '&action=main';
        $_SERVER['REQUEST_URI']     = "http://{$_SERVER['HTTP_HOST']}/{$_SERVER['SCRIPT_NAME']}?{$_SERVER['QUERY_STRING']}";
        $_SERVER['SCRIPT_FILENAME'] = $_SERVER['DOCUMENT_ROOT'];

        /**
         * Instancia o MIOLO
         */
        require_once 'miolo.class.php';
        $this->MIOLO = MIOLO::getInstance();
        ob_end_clean();


        return $this->MIOLO;
    }

    function loadMIOLO()
    {
        ob_start();
        $this->MIOLO->handlerRequest();
        $this->MIOLO->conf->loadConf($this->module);
        ob_end_clean();
    }

}
?>
