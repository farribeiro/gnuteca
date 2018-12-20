<?php

$fileName = '../../'.$item;

$fileName = realpath($fileName);

$form = new MForm( 'View '. $item);

$content = new MFileContent($fileName, true);
$content = str_replace('&nbsp;', ' ', $content->generate());

if ( $item == 'README' )
{
    $content = str_replace("<br />", '<p>', $content);
}

$div = new MDiv('file-content', $content );
$div->textIndent = '16px';

$fields = array($div);

$form->setFields( $fields );
$form->defaultButton = False; 

$formAction = $MIOLO->getConf('home.url') . '/' . $MIOLO->getConf('options.dispatch');
$form->addButton( new MButton( 'btnForm', 'Go Back', $formAction) );

$theme->appendContent( $form );

?>