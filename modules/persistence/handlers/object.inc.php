<?

$theme->clearContent();
$ui = $MIOLO->getUI();
$navbar->addOption('Objects', $module, $self);
$form = $ui->getForm($module,'frmObjects');
$theme->setContent($form);

?>