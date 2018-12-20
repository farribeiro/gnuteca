<?
class frmLogin extends Form
{
    public $auth;

    public function frmLogin()
    {   
        $this->form('Login');               
        $this->setIcon($this->manager->getUI()->getImage('admin','login.gif'));
        if ($this->page->isPostBack())
        {
           $this->eventHandler();
        }
    }

    public function createFields()
    {
        global $MIOLO, $action, $module;

        $this->auth = $this->manager->auth;
        $return_to = $this->getFormValue('return_to',MIOLO::_Request('return_to'));

        if(!$return_to)
        {
            $return_to = $MIOLO->history->top();
        }

        $fields = Array(
           new MTextField('uid',$this->auth->login->iduser,'Login',20),
           new PasswordField('pwd','','Password',20),
           new TextLabel('username',$this->auth->login->user,'Nome',40),
           new HyperLink('mail','Email para contato', 'mailto:'.$this->manager->getConf('theme.email'),$this->manager->getConf('theme.email')),
           new HiddenField('tries', ''),
           new HiddenField('return_to', $return_to)
        );
        $this->setFields($fields);
        $this->addButton(new FormButton('btnLogin', 'Login'));
        $this->addButton(new FormButton('btnLogout', 'Logout'));
        $help = $MIOLO->getActionURL('admin_ldap','loginhelp',null,null,'popup.php');
        $this->addButton(new FormButton('btnHelp', 'Ajuda', "MIOLO_Popup('$help',300,250)"));

        $this->setButtonAttr('btnLogin' ,'visible' , ! $this->isAuthenticated() );
        $this->setButtonAttr('btnLogout','visible' ,   $this->isAuthenticated() );
        $this->setFieldAttr('uid'       ,'readonly',   $this->isAuthenticated() );
        $this->setFieldAttr('pwd'       ,'visible' , ! $this->isAuthenticated() );
        $this->setFieldAttr('username'  ,'visible' ,   $this->isAuthenticated() );
        $this->page->onLoad('document.' . $this->name . '.uid.focus();');
    }

    public function btnLogin_click()
    {   global $MIOLO;

        $this->getData();
        $MIOLO->logMessage('[LOGIN] Validating login information');
        
        // Max login tryes
        $max_tries = 3;
        
        // autenticar usuário e obter dados do login
        $uid = $this->getFormValue('uid');
        $pwd = $this->getFormValue('pwd');

        if ( !$this->loginPermitted($uid) )
        {
           $err = 'Acesso não permitido.';
        }
        else
        {
           if ( $this->auth->authenticate($uid, $pwd) )
           {
               $return_to = $this->getFormValue('return_to');
               // ToDo: voltar para onde estava...
               if ( $return_to )
               {
                  $url = $return_to;
               }
               else
               {
                  $url = $MIOLO->getActionURL('admin_ldap','login');
               }
               $this->page->redirect($url);
            }
            else
            {      
               $tries = $this->getFormValue('tries');
               if ( $tries >= $max_tries )
               {
                  $MIOLO->error('Erro na identificação do usuário!');
               }
               else
               {
                  $err = 'Erro na identificação do usuário!' . ' - Restam ' . ( $max_tries - $tries) . 
                         ' ' . 'tentativa(s).';
                  $tries++;
                  $this->setFieldValue('tries',$tries);
                  $pwd = null;
                  if ( $err )
                  {
                      $this->addError($err);
                  }
               }
            }
        }
    }

    public function btnLogout_click()
    {
        global $MIOLO;
        $this->page->redirect($MIOLO->getActionURL('admin_ldap','logout'));
    }

    public function loginPermitted($uid)
    {  global $MIOLO;

       $ok = true;
       return $ok;
    }

    public function isAuthenticated()
    {
        return $this->auth->isLogged();
    }

}
?>
