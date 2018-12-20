<?

$theme->clearContent();
$ui = $MIOLO->getUI();
$navbar->addOption('Indexed Attributes', $module, $self);
$form = $ui->getForm($module,'frmIndexed');
$theme->setContent($form);

?>