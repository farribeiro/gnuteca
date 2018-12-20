<?

$theme->clearContent();

$MIOLO->checkAccess('module',A_ACCESS,true);

$navbar->addOption( _M('Remove Module Options'), $module, 'main:modules:rem_modules:rem_modules_options');

$ui   = $MIOLO->getUI();
$form = $ui->getForm($module,'frmRemModuleOptions');
$theme->appendContent($form);

?>
