<?php
//mmcache_cache_page($SERVER['PHP_SELF'].'?GET='.serialize($_GET),300);


// PARA ABRIR A PAGINA DA PESQUISA< DEVE SER CONFIGURADO NO APACHE O DIRECTORY INDEX PARA O ARQUIVO gunteca.php

// ensure no caching
header("Expires: Mon, 26 Jul 1997 05:00:00 GMT");              // Date in the past
header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT"); // always modified
header("Cache-Control: no-store, no-cache, must-revalidate");  // HTTP/1.1
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");                                    // HTTP/1.0
//var_dump($_POST);

ini_set("session.bug_compat_42","off");
ini_set("session.bug_compat_warn","off");

require_once '../classes/miolo.class.php';
$MIOLO = MIOLO::getInstance();
/* @var *MIOLO MIOLO */
$MIOLO->handlerRequest();

?>
