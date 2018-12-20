<?

$theme->clearContent();
$ui = $MIOLO->getUI();
$navbar->addOption('MOQL', $module, $self);
$form = $ui->getForm($module,'frmMOQL');
$theme->setContent($form);

?>