<?php
/**
 * MIOLO 2 Web Installer
 *
 * @author Vilson Cristiano Gartner [vilson@solis.coop.br]
 *
 * @version $id$
 *
 * \b Maintainers: \n
 * Vilson Cristiano Gartner [vilson@solis.coop.br]
 *
 * @since
 * File created on 04/09/2006
 *
 * \b Organization: \n
 * SOLIS - Cooperativa de Soluções Livres \n
 * The MIOLO Development Team
 *
 * \b CopyLeft: \n
 * CopyLeft (L) 2006 SOLIS - Cooperativa de Soluções Livres \n
 *
 * \b License: \n
 * Licensed under GPL (for further details read the COPYING file or http://www.gnu.org/copyleft/gpl.html)
 *
 * \b History: \n
 * See history in SVN repository: http://www.miolo.org.br
 *
 **/


// Verify PHP 5 version
if ( ! ( PHP_VERSION >= 5 ) )
{
    echo '<br/>';
    echo ' <table width="400" border="1" cellspacing="0" cellpadding="8" align="center" height="10%"> ';
    echo '   <tr>';
    echo '     <td style="color:#ffffff;font-weight:bold;background-color:#880000;text-align:center" colspan="2"> FATAL ERROR </td> ';
    echo '   </tr>';
    echo '   <tr>';
    echo '     <td class="errorText" align="center"><ul>';

    echo '       <strong><br/>MIOLO 2 requires PHP >= 5</strong><br/><br/>';
    echo '       <strong>Unable to continue!</strong><br/>';

    echo '       </ul>';
    echo '     </td>';
    echo '   </tr>';
    echo '   <tr>';
    echo '     <td align=center> MIOLO Framework v2.0 <br/>';
    echo '     Copyleft (L) 2004-2006 by SOLIS</td>';
    echo '   </tr>';
    echo ' </table>';

    exit;
}

global $debugOn;

$debugOn = true;

$dir = 'handlers/';

// Include support file
include_once($dir.'support.inc');
// Initate processes & variables
include_once($dir.'init.inc');

$module = MIOLO::_REQUEST('module');
$action = MIOLO::_REQUEST('action');
$item   = MIOLO::_REQUEST('item');

// Requesting a theme file?
if ( substr($action, 0, strpos($action, ':') )  == 'themes' )
{
    $fileName  = substr( $action, strrpos($action, ':')+1, strlen($action) );
    $file_info = pathinfo($fileName);

    if ( $file_info['extension'] == 'css' )
    {
        $location = $MIOLO->getConf('home.themes');
    }
    else
    {
        $location = $MIOLO->getConf('home.themes') . '/images/';
    }

    $fullName = $location . $fileName;

    $d = new MDownload();
    $d->setFileName($fullName);
    $d->send();
}
// Requesting a image file?
else if ( substr($action, 0, strpos($action, ':') )  == 'html' )
{
    $fileName  = substr( $action, strrpos($action, ':')+1, strlen($action) );

    $location = $MIOLO->getConf('home.url') . '/images/';

    $fullName = $location . $fileName;

    $d = new MDownload();
    $d->setFileName($fullName);
    $d->send();
}

updateDispatcher('theme');

if ( $module == '' || $action == 'main'  ) // start screen
{
    include_once($dir.'main.inc');
}
else if ( $module == 'install' && $action != ''  ) // otherways
{
    $fileName = $dir . $action . '.inc';

    include_once($fileName);
}
else if ( $module == 'view' && $action != ''  ) // otherways
{
    include_once($dir.'view.inc');
}

// Generate Page Content
updateDispatcher('default');
//$MIOLO->setConf('home.url', 'http://' . $_SERVER['HTTP_HOST' ]);
$MIOLO->theme->init();
//$MIOLO->page->generate();
$MIOLO->history->close();
$MIOLO->terminate();

?>