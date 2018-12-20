<?

$MIOLO->checkAccess('module',A_ACCESS,true);
$navbar->addOption('Modules',$module,$self);
$home = 'main:admin';
$ui   = $MIOLO->getUI();
$form = $ui->getForm($module,'frmModule');
$theme->appendContent($form);
?>
