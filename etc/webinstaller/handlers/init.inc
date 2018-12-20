<?php

global $autoload, $mioloClassesPath, $themePath, $autoloadFile;

//echo $_SERVER['SERVER_SOFTWARE'];
$scriptFileName = $_SERVER["SCRIPT_FILENAME"];
$installerRoot  = substr($scriptFileName, 0,  strrpos( $scriptFileName, '/') + 1 );

$mioloDir = $installerRoot . '../../';
$mioloDir = realPath($mioloDir);

$mioloClassesPath = $mioloDir . '/classes/';

$controlsClassesPath = $mioloClassesPath . 'ui/controls/';
$controlsClassesPath = realPath($controlsClassesPath) . '/';

$themePath    = $mioloClassesPath . '/ui/themes/miolo2/';
$autoloadFile = $mioloClassesPath . 'etc/autoload.xml';

require_once($installerRoot . '/mautoload.class');
require_once($installerRoot . 'miolo.class');

$MIOLO->getTheme();
$MIOLO->getPainter();
$theme = $MIOLO->theme;
?>