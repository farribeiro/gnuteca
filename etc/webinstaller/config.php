<?php

function updateDispatcher($dispatch='default')
{
    global $MIOLO;

    if ( $dispatch == 'default' )
    {
        $MIOLO->dispatch = $MIOLO->getConf('home.url') . '/' . $MIOLO->getConf('options.dispatch');
    }
    else
    {
        $MIOLO->dispatch = $urlContext1;
    }
}


// General configuration & settings

$MIOLO->conf = new MConfigLoader();
$MIOLO->setConf('home.miolo', $mioloDir);
$MIOLO->setConf('home.classes', $mioloClassesPath);
$MIOLO->setConf('home.themes', $themePath);
//$MIOLO->setConf('home.url', 'http://' . $_SERVER['HTTP_HOST' ] . '/webinstaller');

$subDir = substr($_SERVER['REQUEST_URI']  , 0 , strrpos( $_SERVER['REQUEST_URI'], '/')  );

$MIOLO->setConf('home.url', 'http://' . $_SERVER['HTTP_HOST' ] . $subDir );
$MIOLO->setConf('home.url_themes', 'miolo2/classes/themes');

$MIOLO->setConf('options.dispatch.ignore', 'true');
$MIOLO->setConf('module.images','/html/images');

$MIOLO->setConf('namespace.core', '/classes');
$MIOLO->setConf('namespace.service', '/classes/services');
$MIOLO->setConf('namespace.ui', '/classes/ui');
$MIOLO->setConf('namespace.themes', '/ui/themes');
$MIOLO->setConf('namespace.extensions', '/classes/extensions');
$MIOLO->setConf('namespace.controls', '/ui/controls');
$MIOLO->setConf('namespace.database', '/classes/database');
$MIOLO->setConf('namespace.utils', '/classes/utils');
$MIOLO->setConf('namespace.modules', '/modules');
$MIOLO->setConf('login.class','');

$MIOLO->setConf('theme.module', '');
$MIOLO->setConf('theme.main', 'miolo2');
$MIOLO->setConf('theme.lookup', 'miolo2');
$MIOLO->setConf('theme.title', 'Miolo Web Application');
$MIOLO->setConf('theme.company', 'MIOLO FRAMEWORK - Installation');
$MIOLO->setConf('theme.system', 'version 2.0');
$MIOLO->setConf('theme.logo', 'logo_miolo.png');
$MIOLO->setConf('theme.email', 'admin@miolo2.localhost');
$MIOLO->setConf('theme.options.close', true);

$MIOLO->setConf('options.startup', 'common');
$MIOLO->setConf('options.dispatch', 'index.php');
$MIOLO->setConf('options.loading.show', false);
//$MIOLO->setConf('options.performance.uri_images', true);

$MIOLO->setConf('url.style', '0');
$MIOLO->setConf('mainmenu', '3');
$MIOLO->setConf('mainmenu.style', 'office2003');
$MIOLO->setConf('mainmenu.clickopen', 'false');

$MIOLO->setConf('namespace.core', '/classes');
$MIOLO->setConf('namespace.service', '/classes/services');
$MIOLO->setConf('namespace.ui', '/classes/ui');
$MIOLO->setConf('namespace.themes', '/ui/themes');
$MIOLO->setConf('namespace.extensions', '/classes/extensions');
$MIOLO->setConf('namespace.controls', '/ui/controls');
$MIOLO->setConf('namespace.database', '/classes/database');
$MIOLO->setConf('namespace.utils', '/classes/utils');
$MIOLO->setConf('namespace.modules', '/modules');

updateDispatcher();



// Include required files
//require_once( $controlsClassesPath . 'mcomponent.class' );
//require_once( $controlsClassesPath . 'mcontrol.class' );
//require_once( $controlsClassesPath . 'mformcontrol.class' );
//require_once( $controlsClassesPath . 'mform.class' );
//require_once( $controlsClassesPath . 'imagecontrols.class' );
//require_once( $controlsClassesPath . 'linkcontrols.class' );
//require_once( $controlsClassesPath . 'blockcontrols.class' );
//require_once( $controlsClassesPath . 'mcontainer.class' );
//require_once( $controlsClassesPath . 'panelcontrols.class' );
//require_once( $controlsClassesPath . 'moptionlist.class' );
//require_once( $controlsClassesPath . 'mwindow.class' );
//require_once( $controlsClassesPath . 'mpage.class' );
//require_once( $controlsClassesPath . 'labelcontrols.class' );
//require_once( $controlsClassesPath . 'mtheme.class' );
//require_once( $controlsClassesPath . 'mthemeelement.class' );
//require_once( $mioloClassesPath . 'services/mservice.class' );
//require_once( $mioloClassesPath . 'services/mprofile.class' );
//require_once( $mioloClassesPath . 'services/msession.class' );
//require_once( $mioloClassesPath . 'services/mhistory.class' );
//
//require_once( $mioloClassesPath . 'ui/mui.class' );
//require_once( $mioloClassesPath . 'ui/mstate.class' );
//require_once( $mioloClassesPath . 'ui/painter/mbasepainter.class' );
//require_once( $mioloClassesPath . 'ui/painter/mhtmlpainter.class' );
//require_once( $mioloClassesPath . 'utils/' . 'mutil.class' );
//require_once( $mioloClassesPath . 'utils/' . 'mlist.class' );
//require_once( $mioloClassesPath . 'utils/' . 'mconfigloader.class' );



?>
