<?
$MIOLO->logMessage('[LOGIN] file:'.$_SERVER['SCRIPT_NAME']);
$MIOLO->logMessage('[LOGIN] Using login prompt');
$ui = $MIOLO->getUI();
$theme->clearContent();
$navbar->addOption('Login', 'admin', 'login');
$login = $auth->getLogin();


if ($login)
{
   $form = $ui->getForm('admin','frmAccess',$login);
}
elseif ($MIOLO->getConf('options.authmd5'))
{
   $form = $ui->getForm('admin','frmLoginMD5');
}
else
{
   $form = $ui->getForm('admin','frmLogin');
}
if ($theme->getContent()  == '')
{
   $theme->insertContent($form);
}

//$MIOLO->page->generate();
//exit;
?>
