<?php

$navbar->AddOption('Persistence','persistence','main');

// clear the content area of theme
$theme->clearContent();

// generates a link to put no the panel's close button
$close = $MIOLO->getActionURL( 'example', 'main' );

// create a new panel
$panel = new MActionPanel( 'panel', 'Persistence Samples', '', $close );

// obtains access to the UIfunctions (needed to able to use getImage
$ui = $MIOLO->getUI();

// add actions to the panel
$panel->addAction( _M('Persistent Objects'), $ui->getImage( 'example','database.png' ), 'persistence', 'main:object' );
$panel->addAction( _M('MOQL Samples'), $ui->getImage( 'example','database.png' ), 'persistence', 'main:moql' );
$panel->addAction( _M('Converters'), $ui->getImage( 'example','database.png' ), 'persistence', 'main:converter' );
$panel->addAction( _M('Indexed Attributes'), $ui->getImage( 'example','database.png' ), 'persistence', 'main:indexed' );
$panel->addAction( _M('Associated Joins'), $ui->getImage( 'example','database.png' ), 'persistence', 'main:join' );
$panel->addAction( _M('Cursores'), $ui->getImage( 'example','database.png' ), 'persistence', 'main:cursor' );

// append the content into the theme content
$theme->appendContent( $panel );

if ( $a = $context->shiftAction() )
{
   $handled = $MIOLO->invokeHandler( $module, $a );
}

?>