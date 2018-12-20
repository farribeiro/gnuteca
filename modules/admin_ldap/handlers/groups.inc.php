<?
$perms->checkAccess( $module,A_ACCESS,true);
$home = 'main:admin';
$navbar->addOption('Groups',$module,$self);
$ui = $MIOLO->getUI();
$form = $ui->getForm($module,'frmGroup');
$theme->appendContent($form);
?>
