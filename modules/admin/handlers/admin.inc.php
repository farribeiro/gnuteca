<?

$perms->checkAccess('admin',A_ACCESS,true);

$navbar->addOption('Administra��o',$module,'main:admin');

$admMenu = & $theme->getMenu('admin');
$admMenu->setTitle('Administra��o');
$admMenu->addOption('Transa��es',$module,'main:admin:transaction');
$admMenu->addOption('Usu�rios',$module,'main:admin:user');
$admMenu->addOption('Senha',$module,'main:admin:password');
$admMenu->addOption('Grupos',$module,'main:admin:groups');
$admMenu->addOption('Log',$module,'main:admin:log');


$handled = $MIOLO->invokeHandler($module, 'admin/' . $context->shiftAction());
if (! $handled)
{
   $MIOLO->invokeHandler($module, 'admin/users');
}
?>
