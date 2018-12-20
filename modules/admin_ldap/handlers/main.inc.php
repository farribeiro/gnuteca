<?php
$perms->checkAccess('admin_ldap',A_ACCESS,true);

$navbar->addOption('Administração',$module,'main:admin');
$ui = $MIOLO->getUI();


$close = $MIOLO->getActionURL('admin_ldap','main');
$cmPanel = new ActionPanel('pnlCommon','Administração de permissões LDAP','', $close, $ui->getImage($module,'tools1.png'));
//$cmPanel->addAction( 'Modules', $ui->getImage($module,'system.png'), $module, 'main:modules');
$cmPanel->addAction( 'Usuários', $ui->getImage($module,'user.png'), $module, 'main:users');
$cmPanel->addAction( 'Grupos', $ui->getImage($module,'groups.png'), $module, 'main:groups');

$handled = $MIOLO->invokeHandler($module, $context->shiftAction());

if (! $handled)
{
    $theme->appendContent($cmPanel);
}


/*
$MIOLO->trace('file:'.$_SERVER['SCRIPT_NAME']);

$ui = $MIOLO->getUI();
   
$theme->clearContent();
$a = $context->shiftAction();

if( !($handled = $MIOLO->invokeHandler($module,$a)) )
{
    $image   = new MImage('logo_miolo',_M('MIOLO'),$ui->getImage('admin','logo_miolo_big.png'));
    $content = new MDiv('logo_miolo',$image,'m-prompt-box');
    $theme->insertContent($content);
}
*/
?>
