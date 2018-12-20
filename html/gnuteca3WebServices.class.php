<?php

class Gnuteca2WebServicesServer extends SoapServer
{
    private $server,
            $serverOptions,
            $logFile;

    private $MIOLO,
            $MIOLOConsole,
            $module,
            $class,
            $action,
            $debug;


    /**
     * Construtor
     *
     */
    function __construct()
    {
        ini_set("display_errors", "on");

        // GET VARS
        $this->module   = $_GET['module']   = $_REQUEST['module'];
        $this->class    = $_GET['class']    = $_REQUEST['class'];
        $this->action   = $_GET['action']   = $_REQUEST['action'];
        $this->debug    = $_GET['debug']    = ($_REQUEST['debug'] == 1);

        $this->getMioloInstance();
        $this->serverOptionsDefined();

        $this->logFile  = $this->MIOLO->getConf('home.logs')."/gnuteca3-webServices.log";
    }


    /**
     * Inicia o serviço
     *
     * @return bollean
     */
    public function __start()
    {
        $this->logStart();

        if(!$this->checkParameters())
        {
            return false;
        }

        if(!$this->includeClass())
        {
            return false;
        }

        if(!$this->startingServer())
        {
            return false;
        }

        return true;
    }



    /**
     * Inicia o servidor soap
     *
     * @return unknown
     */
    private function startingServer()
    {
        $this->serverOptionsDefined();

        if(!parent::__construct(NULL, $this->serverOptions))
        {
            $this->recordLog("Server not starting!!!", 'error');
            return false;
        }

        $this->recordLog("Server starting OK!!!");

        parent::setClass($this->class);
        parent::setPersistence(SOAP_PERSISTENCE_SESSION);
        parent::handle();

        $this->displayClassMethods();

        return true;
    }


    /**
     * Define as opções do server
     *
     */
    private function serverOptionsDefined()
    {
        // CONFIGURATION SOAP SERVER
        $this->serverOptions['uri']           = $this->MIOLO->getConf('home.url');
        $this->serverOptions['encoding']      = 'ISO-8859-1';
        //$serverOptions['soap_version']  = SOAP_1_2;
    }



    /**
     * Inclui a classe que será utilizada pelo webservices
     *
     * @return boolean
     */
    private function includeClass()
    {
        // CLASS PATH
        $path = $this->MIOLO->getModulePath( $this->module, "/webservices/{$this->class}.class.php" );
        $this->recordLog("Class File: $path");

        if(!file_exists($path))
        {
            $this->recordLog("Class file not exists!", 'error');
            return false;
        }

        // INCLUDE CLASS FOR WEBSERVICES
        if(!require_once($path))
        {
            $this->recordLog("Class file include fail!");
            return false;
        }

        $this->recordLog("Class file include OK!");
        return true;
    }



    /**
     * Verifica se os parametros necessários são validos.
     *
     * @return boolean
     */
    private function checkParameters()
    {
        if(!strlen($this->module))
        {
            $this->recordLog("This module undefined!!", 'error');
            return false;
        }

        if(!strlen($this->class))
        {
            $this->recordLog("This class undefined!!", 'error');
            return false;
        }

        if(!strlen($this->action))
        {
            $this->recordLog("This action undefined!!", 'error');
            return false;
        }

        return true;
    }



    /**
     * Retorna a instancia do MIOLO
     *
     */
    private function getMioloInstance()
    {
        // INCLUI E INSTANCIA O MIOLO
        chdir(dirname(__FILE__));
        $path       = realpath("../");
        $classPath  = realpath("../classes/");

        include("$classPath/mioloconsole.class.php");

        $this->MIOLOConsole   = new MIOLOConsole();
        $this->MIOLO          = $this->MIOLOConsole->getMIOLOInstance($path, $this->module);
        $this->MIOLOConsole   ->loadMIOLO();
    }


    /**
     * Enter description here...
     *
     */
    private function logStart()
    {
        $this->logLine();
        $this->recordLog("Starting Gnuteca3 WebServices");
        $this->recordLog("Data: ". date("d/m/Y H:i:s"));
        $this->recordLog("Client IP: ". $_SERVER['REMOTE_ADDR']);
        $this->recordLog("Module: {$this->module}");
        $this->recordLog("Class:  {$this->class}");
        $this->recordLog("");
    }


    /**
     * Enter description here...
     *
     */
    private function logLine()
    {
        $content = "+";
        for($x=0; $x<200; $x++) $content.="-";
        $content.= "+";

        $this->recordLog($content);
    }


    private function displayClassMethods()
    {
        $this->recordLog("=======");
        $this->recordLog("Class Methods:");

        $funcs = parent::getFunctions();
        foreach($funcs as $f)
        {
            $this->recordLog("\t- $f;");
        }
        $this->recordLog("=======");
    }

    /**
     * Grava os log do server
     *
     * @param unknown_type $content
     */
    private function recordLog($content, $type = null)
    {
        switch ($type)
        {
            case 'error'    : $content = "[ERROR] - $content";  break;
            case 'info'     : $content = "[INFO] - $content";   break;
        }

        file_put_contents($this->logFile, "{$content}\n", FILE_APPEND);
        echo "$content<br>";
    }

}

// INCLUI E INSTANCIA O MIOLO
chdir(dirname(__FILE__));
$path       = realpath("../");
$classPath  = realpath("../classes/");

include("$classPath/mioloconsole.class.php");

$MIOLOConsole   = new MIOLOConsole();
$MIOLO          = $MIOLOConsole->getMIOLOInstance($path, "gnuteca3");

$server = new Gnuteca2WebServicesServer();
$server->__start();

?>