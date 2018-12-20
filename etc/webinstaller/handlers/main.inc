<?php
    $MIOLO->theme->clearContent();
    //$MIOLO->setConf('theme.system', 'Start Screen');

    // generates a link to put no the panel's close button
    //$close = $MIOLO->getActionURL( 'admin', 'main' );

    // create a new panel
    $installPanel = new MActionPanel( 'pnlInstall', 'MIOLO 2.0 - Installation', '', $close );

    // obtains access to the UIfunctions (needed to able to use getImage
    $ui = $MIOLO->getUI();

    // add actions to the panel
//    $MIOLO->dispatch = 'webinstaller/index.php';
    updateDispatcher('theme');
    $installPanel->addAction( _M('View INSTALL')    , 'images/document.png', 'install', 'view', 'INSTALL' );
    $installPanel->addAction( _M('View README')     , 'images/document.png', 'install', 'view', 'README' );
    $installPanel->addAction( _M('LICENSE')         , 'images/document.png', 'install', 'view', 'LICENSE' );
    $installPanel->addAction( _M('Show Environment'), 'images/globals.png', 'install', 'show_environment' );
    $installPanel->addAction( _M('Install MIOLO2')  , 'images/install.png', 'install', 'install' );

    // append the content into the theme content
    $MIOLO->theme->appendContent( $installPanel );
?>