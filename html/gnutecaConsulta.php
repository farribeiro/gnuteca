<?php

/**
 * Novo arquivo de entrada, usado pela pesquisa aberta no Alfa (externalSearch)
 * Necessario para abrir sem HTTPS, modificando configuracoes de URL e dispatch
 */

// ensure no caching
header("Expires: Mon, 26 Jul 1997 05:00:00 GMT");              // Date in the past
header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT"); // always modified
header("Cache-Control: no-store, no-cache, must-revalidate");  // HTTP/1.1
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");                                    // HTTP/1.0

ini_set("session.bug_compat_42","off");
ini_set("session.bug_compat_warn","off");

require_once '../classes/miolo.class.php';
$MIOLO = MIOLO::getInstance();
// carrega configuracoes padrao
$MIOLO->initialize();

// remove HTTPS e seta configuracao, caso necessario
if ( $_SERVER['HTTPS'] == 'on' )
{
    $url = str_replace('http://', 'https://', $MIOLO->getConf('home.url'));
}
else
{
    $url = str_replace('https://', 'http://', $MIOLO->getConf('home.url'));
}
$MIOLO->setConf('home.url', $url);
$MIOLO->setConf('options.dispatch', 'gnutecaConsulta.php');

//Precisa limpar a sessão pois dá conflito com outrosdispatch do miolo
session_start();
unset($_SESSION['_stackContext']);
unset($_SESSION['_stackAction']);

// chama sistema sem carregar configuracao por cima
$MIOLO->handlerRequest(false);

?>
