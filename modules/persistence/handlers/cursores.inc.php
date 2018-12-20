<?

$theme->clearContent();
$ui = $MIOLO->getUI();
$navbar->addOption('Cursores', $module, $self);
$form = $ui->getForm($module,'frmCursores');
$theme->setContent($form);

?>