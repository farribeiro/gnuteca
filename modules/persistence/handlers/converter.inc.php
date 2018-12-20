<?

$theme->clearContent();
$ui = $MIOLO->getUI();
$navbar->addOption('Converters', $module, $self);
$form = $ui->getForm($module,'frmConverters');
$theme->setContent($form);

?>