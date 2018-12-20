<?php

// GET VARS
$module = $_GET['module']   = $_REQUEST['module'];
$class  = $_GET['class']    = $_REQUEST['class'];
$action = $_GET['action']   = $_REQUEST['action'];

// INCLUI E INSTANCIA O MIOLO
chdir(dirname(__FILE__));
$path       = realpath("../");
$classPath  = realpath("../classes/");

include("$classPath/mioloconsole.class.php");

$MIOLOConsole   = new MIOLOConsole();
$MIOLO          = $MIOLOConsole->getMIOLOInstance($path, $module);
$MIOLOConsole   ->loadMIOLO();

$logFile = $MIOLO->getConf('home.logs')."/gnuteca3-webServices.log";

/**
 * Escreve o arquivo de log
 *
 * @param resultado do envio (Boolean) $result
 */
function recordLog($content)
{
    global $logFile;
    file_put_contents($logFile, "{$content}\n", FILE_APPEND);
}

recordLog("+------------------------------------------------+");
recordLog(date("d/m/Y H:i:s"));
recordLog($_SERVER['REMOTE_ADDR']);
recordLog("");

recordLog("Module: $module;\nClass: $class;\nAction: $action;");

if(!strlen($module) || !strlen($class))
{
    recordLog("[ERROR] - Class or module undefined");
    die("class or module undefined");
}

// CLASS PATH
$path = $MIOLO->getModulePath( $module, "/webservices/$class.class.php" );
recordLog("Path: $path");
if(!file_exists($path))
{
    recordLog("[ERROR] - File Class not exists!");
    die("File Class not exists!");
}

// INCLUDE CLASS FOR WEBSERVICES
include($path);

// CONFIGURATION SOAP SERVER
$serverOptions['uri']           = $MIOLO->getConf('home.url');
$serverOptions['encoding']      = 'ISO-8859-1';
//$serverOptions['soap_version']  = SOAP_1_2;

$server = new SoapServer(NULL, $serverOptions);

if(!$server)
{
    recordLog("[ERROR] - Server not start");
    die("Could not start the server soap!!");
}

$server->setClass($class);
$server->setPersistence(SOAP_PERSISTENCE_SESSION);
$server->handle();

$debug = $_GET['debug']   = $_REQUEST['debug'];
if(!$debug)
{
    die();
}

$funcs = $server->getFunctions();

echo "<pre>Methods:\n ";

foreach($funcs as $f)
{
    echo " - $f\n ";
}

echo "\n</pre>";

?>