<?

$MIOLO->trace('file:'.$_SERVER['SCRIPT_NAME']);

$MIOLO->checkAccess('module',A_ACCESS,true);

$navbar->addOption( _M('View Available Modules'), $module, 'main:modules:add_online_modules');

$ui   = $MIOLO->getUI();
$form = $ui->getForm($module,'frmAddOnlineModule');

if ( ! $MIOLO->invokeHandler($module, $context->shiftAction()) )
{
    $theme->insertContent($form);
}

?>
