<?php

    $home = 'main:admin';
    
    $navbar->addOption('Usu�rios',$module,$self);
    
    $ui = $MIOLO->getUI();
    
    $form = $ui->getForm($module,'frmUser');
    $theme->clearContent();
    $theme->insertContent($form);    

?>