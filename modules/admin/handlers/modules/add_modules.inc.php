<?

$MIOLO->trace('file:'.$_SERVER['SCRIPT_NAME']);
 
$MIOLO->checkAccess('module',A_ACCESS,true);

$navbar->addOption( _M('Add Modules'), $module, 'main:modules:add_modules');

$ui   = $MIOLO->getUI();
$form = $ui->getForm($module,'frmAddModule');
$theme->appendContent($form);


$handled = $MIOLO->invokeHandler($module, 'modules/'.$context->shiftAction() );

if (! $handled)
{
    $theme->insertContent($cmPanel);
}
include_once($MIOLO->getConf('home.modules') .'/main_menu.inc');

?>
