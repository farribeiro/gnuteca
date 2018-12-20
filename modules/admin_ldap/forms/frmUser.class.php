<?
class frmUser extends MForm
{
	public $home;
    public $objGrupo;
    public $objUser;
    public $objModule;
    public $schema;

	function __construct()
    {   global $MIOLO, $module, $action;

        $this->home = $MIOLO->getActionURL($module,$action);
        $this->objGrupo = $MIOLO->getBusiness($module,'group');
        $this->objModule= $MIOLO->getBusiness($module,'module');
        $this->objUser  = $MIOLO->getBusiness($module,'user');
        $this->schema = $this->objUser->schema;
		parent::__construct('Usu�rios');
        $this->setWidth('65%');
        $this->setIcon($MIOLO->getUI()->getImage('admin','user1.png'));
        $this->setClose($MIOLO->getActionURL('admin','main'));
	    $this->eventHandler();
	}

    public function createFields()
    {   global $MIOLO;

        $grupos     = $this->objGrupo->listAll(false);
        $mtFieldGrp = array(array('mtgrupo' ,'Grupos','',$grupos));
        $modulos    = $this->objModule->listAll(false);
        $permissoes = $this->objModule->listAllAccess(false);
        $mtFieldAcs = array(array('mtmodule','M�dulo','',$modulos), array('mtaccess','Permiss�o','',$permissoes));
        
        $fields = array(
            new MHiddenField('key',''),
            new MTextField('txtLogin','','Login',20),
            new MTextField('edtNome','','Nome',40),
            new MTextField('codAluno','','C�digo de aluno',10),
            new MTextField('edtEmail','','Email',40),
            new MPasswordField('edtPassword','','Senha',20),
            new MMultiTextField2('mtfGrupos',NULL,'Grupos',$mtFieldGrp,300,true,'vertical'),
            new MMultiTextField2('mtfAccess',NULL,'Permiss�es',$mtFieldAcs,300,true,'vertical'),
        );
        $this->setFields($fields);

        $this->setFieldsVisible(false);

        $buttons = array(
            new MButton('btnEdit',   'Editar'),
            //new MButton('btnNew',    'Incluir'),
            //new MButton('btnDelete', 'Excluir'),
            new MButton('btnList',   'Rela��o')
        );
        $this->setButtons($buttons);
    }

    public function setFieldsVisible($value)
    {
	   $this->setFieldAttr('txtIdUser','visible',$value);
	   $this->setFieldAttr('edtPassword','visible',$value);
	   $this->setFieldAttr('hidIdPessoa','visible',$value);
	   $this->setFieldAttr('edtEmail','visible',$value);
	   $this->setFieldAttr('edtNick','visible',$value);
	   $this->setFieldAttr('mtfGrupos','visible',$value);
	   $this->setFieldAttr('mtfAccess','visible',$value);

       if($this->schema == 'system')
       {
           $this->setFieldAttr('edtEmail','readonly',true);
           $this->setFieldAttr('edtPassword','visible',false);
       }
    }

/*
    GetData: obt�m os valores fornecidos no formulario e cria um objeto FormData
             cujos attributos t�m o mesmo nome dos atributos do objeto que vai receber os valores.
    A implementa��o default do GetData cria um objeto FormData cujos atributos t�m
    o mesmo nome dos campos do formul�rio.   
*/
	function getData()
	{
        $data = new FormData();
		$data->idUser   = $this->getFieldValue('key');
		$data->login    = $this->getFieldValue('txtLogin');
		$data->password = $this->getFieldValue('edtPassword');
		$data->grupos   = $this->getFieldValue('mtfGrupos');
        $data->nome     = $this->getFieldValue('edtNome');
        $data->codAluno = $this->getFieldValue('codAluno');
        $data->email    = $this->getFieldValue('edtEmail');
        return $data;
	}

/*
    SetData: obt�m os valores fornecidos atrav�s do par�metro $data (geralmente um
             objeto de neg�cio) e preenche os campos do formul�rio.
    A implementa��o default do SetData assume que os atributos do objeto $data t�m
    o mesmo nome dos campos do formul�rio.   
*/
	function setData($data)
	{
		$this->setFieldValue('key'        , $data->idUser);
		$this->setFieldValue('txtIdUser'  , $data->idUser);
		$this->setFieldValue('txtLogin'   , $data->login);
		$this->setFieldValue('edtPassword', $data->password);
		$this->setFieldValue('edtNome'    , $data->nome);
		$this->setFieldValue('codAluno'   , $data->codAluno);
		$this->setFieldValue('edtEmail'   , $data->email);
        // $data->grupos � um array de objetos; GetAttribute percorre este array e obtem um array com 
        // o atributo IdGrupo
        $grupos = $data->groups; //$this->getAttribute($data->groups,'idGroup');//,'group'));
        $this->getField('mtfGrupos')->setCodeValue($grupos);

        $rights     = $this->objUser->getRights($data->login);

        $r = array();
        foreach($rights as $module=>$rights)
        {
            foreach($rights as $right)
                $r[] = array($module, $right);
        }
        $this->getField('mtfAccess')->setCodeValue($r);
	}

	function btnPost_click()
	{
		global $MIOLO;

        $key = $this->getFieldValue('key');  // inclus�o ou edi��o?
        $objUser = $this->objUser;     // apenas um shortcut
        if ($key != '')
        {
            $objUser->getById($key); // se for edi��o, obtem os dados atuais do objeto
        }
        // seta os atributos do objeto com os valores dos campos do formulario
		$objUser->setData($this->getData()); 
        // os grupos devem ser tratados a parte, pois devem gerar um array de objetos
        $grupos = $this->getField('mtfGrupos')->getCodeValue();
        foreach($grupos as $g)
        {
            $data->grupos[] = $g[0]; // obt�m o idGrupo
        }
		$objUser->setArrayGroups($data->grupos);
        $objUser->setArrayRights($this->getField('mtfAccess')->getCodeValue());

        try
        {
            $objUser->save();
            $MIOLO->information('Usu�rio atualizado com sucesso.', $this->home );
        }
        catch (EMioloException $e)
        {
            $this->addError($e->getMessage());
	    }
	}

	function btnList_click()
	{   
		global $MIOLO, $module, $action;

        // limpa o formul�rio
        //$this->clearFields();
        $this->clearButtons();
        $this->defaultButton = false;
 
        // define o campo para fazer o filtro
        $fields = array(
            array(
               new MTextField('txtLogin','','Login',25),
               new MTextField('edtNome','','Nome',40),
               new MTextField('codAluno','','C�digo de aluno',10),
               new MButton('btnList','Rela��o')
            )
        );
        $this->setFields($fields);

        // colunas do DataGrid
        $columns = array(
           new MDataGridColumn('iduser','Id','right', true, '10%',true),
           new MDataGridColumn('login','Login','left', true, '20%',true, NULL, true,true),
           new MDataGridColumn('nome','Nome','left',true, '70%',true, NULL, true,true),
        );

        // link de referencia para o grid
		$hrefDatagrid = $MIOLO->getActionURL($module,$action,'', Array('event'=>'btnList_click'));

        // valor definido como filtro
        $login = MUtil::NVL($this->getFieldValue('txtLogin'), '');

        // executa a query
        $name  = $this->edtNome->value;
        $cod   = $this->codAluno->value;
        $query = $this->objUser->listByLogin($login, $name, $cod);

        // instancia o datagrid
        $datagrid = new MGrid($query, $columns, $hrefDatagrid, 20);
        $datagrid->setTitle('Rela��o de Usu�rios');
        $datagrid->setClose($MIOLO->getActionURL($module,$action));

 	    $href_edit = $MIOLO->getActionURL($module,$action,'%0%',Array('event'=>'btnEdit:click'));
	    //$href_dele = $MIOLO->getActionURL($module,$action,'%0%',Array('event'=>'btnDelete:click'));
        $datagrid->addActionUpdate($href_edit);
	    //$datagrid->addActionDelete($href_dele);
        // coloca o datagrid no formul�rio
		$this->addField($datagrid);
	}

	function btnEdit_click($sender, $key='')
	{   
        global $item;
        $this->setFieldAttr('edtNome','readonly',true);
        $this->setFieldAttr('codAluno','readonly',true);

        $login = $this->getFieldValue('txtLogin');
        if(!$login) $login = $this->getFieldValue('codAluno');
        // verifica se est� sendo executado atrav�s do evento do grid
        if($item)
        {
            $this->objUser->getById($item);
        }		
        else
        {
            $this->objUser->getByLogin($login);
        }

        if ($this->objUser->idUser)
        {
            // coloca os dados do objeto nos campos do formul�rio
            $this->setData($this->objUser);
            // exibe os campos
            $this->setFieldsVisible(true);
            $this->setFieldAttr('txtLogin','readonly',true);
            $this->setFieldValue('key',$this->objUser->idUser);
            $this->addButton(new MButton('btnCancel', 'Cancelar', $this->home));
            $this->setButtonAttr('btnEdit','name','btnPost');
            $this->setButtonAttr('btnPost','label','Gravar');
            $this->setButtonAttr('btnNew','visible', false);
            //$this->addValidator(new RequiredValidator('edtPassword'));
        }
        else
        {
            $this->addError("Usu�rio [$login] n�o encontrado!");
        }
	}

	function btnCancel_click()
	{   
        $this->setFieldValue('txtLogin','');
    }

	function btnNew_click($sender)
	{   
        $data = new FormData();
        $data->login = $this->getFieldValue('txtLogin');
        if ($data->login != '')
        {
            $this->setData($data);
            $this->setFieldsVisible(true);
            $this->setFieldAttr('txtIdUser','visible',false);
            $this->setFieldAttr('txtLogin','readonly',true);
            $this->addButton(new MButton('btnCancel', 'Cancelar', $this->home));
            $this->setButtonAttr('btnEdit','name','btnPost');
            $this->setButtonAttr('btnPost','label','Gravar');
            $this->setButtonAttr('btnNew','visible', false);
            $this->addValidator(new RequiredValidator('edtPassword'));
            $this->addValidator(new RequiredValidator('lkpNome'));
        }
        else
        {
        //    $this->addError("Por favor, informe o login para novo usu�rio!");
        }
	}

	function btnDelete_click($sender, $key='')
	{   
		global $MIOLO, $module, $item, $self, $action, $url;

        $objUser = $this->objUser;
        $login = $this->getFieldValue('txtLogin');
        // verifica se est� sendo executado atrav�s do evento do grid
        $item = ($key != '') ? $key : $item;
        if ($item != '')
        {
            $objUser->getById($item);
        }		
        else
        {
            $objUser->getByLogin($login);
        }		
        if ($objUser->idUser)
        {
            $conf = $this->getFormValue('conf');
	        if ( $conf == 'sim')
	        {
                try
                {
                     $objUser->delete();
                     $MIOLO->prompt(Prompt::information("Usu�rio [$objUser->login] exclu�do com sucesso.",$this->home));
                }
                catch (EMioloException $e)
                {
		             $MIOLO->prompt(Prompt::information( $objUser->getErrors(),$this->home));
                }
	        }
	        elseif ( $conf == 'nao')
            {
	            $MIOLO->prompt(Prompt::information('Exclus�o cancelada.',$this->home));
            }
	        else
	        {
		        $action_sim = $MIOLO->getActionURL($module,$action,$objUser->idUser, array('event'=>'btnDelete:click','conf'=>'sim'));
		        $action_nao = $MIOLO->getActionURL($module,$action,$objUser->idUser, array('event'=>'btnDelete:click','conf'=>'nao'));
	            $MIOLO->prompt(Prompt::question("Confirma a exclus�o do usu�rio [$objUser->login]?", $action_sim, $action_nao));
            }
        }
        else
        {
            $this->addError("Usu�rio [$login] n�o encontrado!");
        }
	}

    public function getAttribute($array, $attr)
    {
        $rs = array();
        if (!is_null($array))
        {
            foreach($array as $c)
            {
                //if(is_array($attr))
                //{
                //    $rs[] = array($c->$attr[0]);//,$c->$attr[1]);
                //}
                //else
                    $rs[] = $c->$attr;
            }
       }
        return $rs;
    }
}

?>
