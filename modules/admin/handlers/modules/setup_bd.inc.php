<?

$theme->clearContent();



$MIOLO->checkAccess('module',A_ACCESS,true);

$navbar->addOption( _M('Module Setup Data Base'), $module, 'main:modules:setup_bd');

$ui   = $MIOLO->getUI();
$form = $ui->getForm($module,'frmSetupModuleBD');
$theme->appendContent($form);

?>