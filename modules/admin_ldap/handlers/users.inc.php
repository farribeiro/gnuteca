<?
$perms->checkAccess($module,A_ACCESS,true);
$home = 'main:admin';
$navbar->addOption('Users',$module,$self);
$ui = $MIOLO->getUI();
$form = $ui->getForm($module,'frmUser');
$theme->appendContent($form);
?>
