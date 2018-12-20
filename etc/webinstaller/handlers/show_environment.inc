<?php

    $fileName = 'environment.inc';
    include_once($fileName);
    Requisites::processRequisites( );

    $formAction = $MIOLO->getConf('home.url') . '/' . $MIOLO->getConf('options.dispatch');
    $form = new MForm('Server Environment');
    $form->defaultButton = false;

//$btnForm7 = new MButton( 'btnForm7', 'Javascript', "alert('Javascript!')" );


    $form->addButton( new MButton( 'btnForm', 'Go Back', $formAction ) );

    $fields = array( Requisites::$content );
    $form->setFields( $fields);

    $theme->appendContent( $form );

?>