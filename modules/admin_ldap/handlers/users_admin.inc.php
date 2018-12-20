<?php

    $home = 'main:admin';
    
    $navbar->addOption('Usuários',$module,$self);
    
    $ui = $MIOLO->getUI();
    
    $form = $ui->getForm($module,'frmUser');
    $theme->clearContent();
    $theme->insertContent($form);    

?>