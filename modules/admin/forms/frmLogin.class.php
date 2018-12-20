<?
class frmLogin extends MForm
{
    public $auth;

    public function frmLogin()
    {
        parent::__construct( _M('Login Gnuteca') );
        
        $this->setIcon($this->manager->getUI()->getImage('gnuteca3','login-16x16.png'));

        if ($this->page->isPostBack())
        {
           $this->eventHandler();
        }

        $this->box->setBoxClass("loginForm");
    }

    public function createFields()
    {
        global $MIOLO, $action, $module;

        $ui = $MIOLO->getUI();

        $this->auth = $this->manager->auth;
        $return_to = $this->getFormValue('return_to',MIOLO::_Request('return_to'));

        if(!$return_to)
        {
            $return_to = $MIOLO->history->top();
            /*
            // if we must make login, return to startup module
            if ( $MIOLO->getConf('login.check') )
            {
                $return_to = $MIOLO->getActionURL($MIOLO->getConf('options.startup'), 'main');
            }
            // else return to the environment's common module,
            else
            {
                $return_to = $MIOLO->getActionURL($MIOLO->getConf('options.common'), 'main');
            }
            */
        }

        $imgLogin = new MImage( 'imgLogin', _M('Inform the username and password'), $ui->getImage($module, 'attention.png') );

        $fields = array(
           new MTextField('uid',$this->auth->login->iduser,'Login',20),
           new PasswordField('pwd','',_M('Password'),20),
           new TextLabel('username',$this->auth->login->user,'Nome',40),
           //new HyperLink('mail','Email para contato', 'mailto:'.$this->manager->getConf('theme.email'),$this->manager->getConf('theme.email')),
           new HiddenField('tries', ''),
           new HiddenField('return_to', $return_to)
        );

        $this->setFields($fields);

        $imageLogin  = $this->manager->getUI()->getImage('gnuteca3','accept-16x16.png');
        $imageLogout = $this->manager->getUI()->getImage('gnuteca3','logout-16x16.png');
        $this->addButton(new MButton('btnLogin', _M('Login', $module) ,null, $imageLogin) );
        $this->addButton(new MButton('btnLogout', _M('Logout', $module) ,null, $imageLogout) );

        $this->setButtonAttr('btnLogin' , 'visible' , ! $this->isAuthenticated() );
        $this->setButtonAttr('btnLogout', 'visible' ,   $this->isAuthenticated() );
        $this->setFieldAttr('uid'       , 'readonly',   $this->isAuthenticated() );
        $this->setFieldAttr('pwd'       , 'visible' , ! $this->isAuthenticated() );
        $this->getField('uid')->setClass('m-text-user-field');
        $this->getField('pwd')->setClass('m-text-passwd-field');

        $this->setFieldAttr('username'  ,'visible'  ,$this->isAuthenticated());

        $this->page->onload("dojo.byId('uid').focus();");

    }

    public function btnLogin_click()
    {   global $MIOLO;

        $this->getData();

        // Max login tryes
        $max_tries = 3;

        // autenticar usuï¿½rio e obter dados do login
        $uid = $this->getFormValue('uid');
        $pwd = $this->getFormValue('pwd');

        $MIOLO->logMessage('[LOGIN] Validating login information: ' . $uid);

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
                  $url = $MIOLO->getActionURL('admin','login');
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
                  $err = 'Erro na identificaçãoo do usuário!' . ' - Restam ' . ( $max_tries - $tries) .' ' . 'tentativa(s).';
                  $tries++;
                  $this->setFormValue('tries',$tries);
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
        $this->page->redirect($MIOLO->getActionURL($module,'logout'));
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
