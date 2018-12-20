<?
class frmGroup extends MForm
{
	var $home;
    public $objGroup;
    public $objModule;
    public $listURL;

	function __construct()
    {   global $MIOLO, $module, $action;

        $this->home = $MIOLO->getActionURL($module,$action);
        $this->objGroup = $MIOLO->getBusiness($module,'group');
        $this->objModule= $MIOLO->getBusiness($module,'module');
		parent::__construct('Grupos');
        $this->setWidth('65%');
        $this->setIcon($MIOLO->getUI()->getImage('admin','user1.png'));
        $this->setClose($MIOLO->getActionURL($module,'main'));
        $this->listURL = $MIOLO->getActionURL($module, 'main:groups',null,array('event'=>'btnList:click'));
	    $this->eventHandler();
	}

    public function createFields()
	{   global $MIOLO, $action;

        $perms = $MIOLO->getPerms()->perms;
        $mt_field = array(
           array('mtperms','Permissions','',$perms)
        );

        $modulos    = $this->objModule->listAll(false);
        $permissoes = $this->objModule->listAllAccess(false);
        $mtFieldAcs = array(array('mtmodule','Módulo','',$modulos), array('mtaccess','Permissão','',$permissoes));
       
        $fields = array(
            new MHiddenField('key',''),
            new MTextField('txtIdGroup','', _M('Id', 'basic'), 10),
		    new MTextField('txtGroup','','Descrição do grupo',20),
            new MMultiTextField2('mtfAccess',NULL,'Permissões',$mtFieldAcs,300,true,'vertical'),
        );
	    $this->setFields($fields);

        $this->setFieldsVisible(false);

	    $this->setFieldAttr('txtIdGroup','visible', true);

       $buttons = array(
           new MButton('btnEdit',   'Editar'),
		   new MButton('btnNew',    'Adicionar'),
           new MButton('btnDelete', 'Remover'),
	       new MButton('btnList',   'Listar')
       );
	   $this->setButtons($buttons);
	}

    public function setFieldsVisible($value)
    {
	   $this->setFieldAttr('txtIdGroup','visible',$value);
	   $this->setFieldAttr('mtfAccess' ,'visible',$value);
	   $this->setFieldAttr('txtGroup' ,'visible',$value);
    }

	function getData()  // nome dos formfields != business fields
	{
        $data = new FormData();
		$data->idGroup = $this->getFieldValue('txtIdGroup');
		$data->group   = $this->getFieldValue('txtGroup');

        return $data;
	}

	function setData($data)
	{
		$this->setFieldValue('txtIdGroup', $data->idGroup);
		$this->setFieldValue('txtGroup',   $data->group);

        $rights     = $this->objGroup->getRights($data->login);

        $r = array();
        foreach($rights as $module=>$rights)
        {
            foreach($rights as $right)
                $r[] = array($module, $right);
        }
        $this->getField('mtfAccess')->setCodeValue($r);

        return $data;

	}

	function btnPost_click()
	{
		global $MIOLO;

        $key = $this->getFieldValue('key');  // inclusão ou edição?
        $objGroup = $this->objGroup;     // apenas um shortcut
        if ($key != '')
        {
            $objGroup->getById($key); // se for edição, obtem os dados atuais do objeto
        }
        // seta os atributos do objeto com os valores dos campos do formulario
		$objGroup->setData($this->getData()); 
        $objGroup->setArrayRights($this->getField('mtfAccess')->getCodeValue());
        try
        {
            $objGroup->save();
            $MIOLO->information('Group atualizado com sucesso.', $this->home );
        }
        catch (EMioloException $e)
        {
            $this->addError($e->getMessage());
	    }
	}

	function btnList_click()
	{   
		global $MIOLO, $module, $self, $theme, $action;
        $this->setFieldsVisible(false);

        $this->clearFields();
        $this->clearButtons();
        $this->defaultButton = false;
                                
        $fields = array(
            array(
               new MTextField('txtGroup','','Grupo',25),
               new MButton('btnList','Relação')
            )
        );
        $this->setFields($fields);


        $columns = array(
           new DataGridColumn('idgroup','Id','right', true, '10%',true),
           new DataGridColumn('m_group','Group','left', true, '90%',true)
        );
		$query = $this->objGroup->listAll( );
		$href_datagrid = $MIOLO->getActionURL($module,$self,'', Array('event'=>'btnList_click'));
        
        $datagrid = new mGrid($query, $columns, $href_datagrid,20);
        $datagrid->setTitle('Relação de Grupos de Acesso');
 	    $href_edit = $MIOLO->getActionURL($module,$self,'%0%',Array('event'=>'btnEdit:click'));
	    $href_dele = $MIOLO->getActionURL($module,$self,'%0%',Array('event'=>'btnDelete:click'));
        $datagrid->addActionUpdate($href_edit);
	    $datagrid->addActionDelete($href_dele);

        $datagrid->headerLink('new', 'Novo Registro',$MIOLO->getActionURL($module,$self,'',Array('event'=>'btnNew:click')));
		$this->addField($datagrid);
	}

	function btnEdit_click($sender, $key='')
	{   
        global $item;
        if( ! $item )
            $item  = $this->getFieldValue('txtIdGroup');
        $group = $this->getFieldValue('txtGroup');
        // verifica se está sendo executado através do evento do grid

        if ($item != '')
        {
            $this->objGroup->getById($item);
        }		
        else
        {
            $this->objGroup->getByGroup($group);
        }

        if ($this->objGroup->idGroup)
        {
            // coloca os dados do objeto nos campos do formulário
            $this->setData($this->objGroup->getData());
            // exibe os campos
            $this->setFieldsVisible(true);
            $this->setFieldAttr('txtGroup','readonly',false);
            $this->setFieldValue('key',$this->objGroup->idGroup);
            $this->addButton(new MButton('btnCancel', 'Cancelar', $this->home));
            $this->setButtonAttr('btnEdit','name','btnPost');
            $this->setButtonAttr('btnPost','label','Gravar');
            $this->setButtonAttr('btnNew','visible', false);

            $this->setButtonAttr('btnDelete', 'visible', false);
	        $this->setButtonAttr('btnList'  , 'visible', false);
        }
        else
        {
            $this->addError("Group [$group] não encontrado!");
        }
	}

	function btnNew_click()
	{
       $this->objGroup->setData($data=$this->getData());

       if($data->idGroup && $data->group)
       {
            if ( $this->objGroup->save( ) )
	        {
			   $this->manager->prompt(Prompt::information("Grupo [$data->group] acrescentado com sucesso.",$this->listURL));
	        }
	        else
	        {
			   $this->manager->prompt(Prompt::information("Erro ao acrescentar o grupo [$data->group]!",$this->listURL));
            }
            return true;
       }
       $this->setFieldsVisible(true);
       $this->addButton(new MButton('btnCancel', 'Cancelar', $this->home));
       $this->setButtonAttr('btnEdit','name','btnPost');
       $this->setButtonAttr('btnPost','label','Gravar');
       $this->setButtonAttr('btnNew','visible', false);
       $this->setButtonAttr('btnDelete','visible', false);
       $this->setButtonAttr('btnList','visible', false);
	}

	function btnDelete_click()
	{   
		global $MIOLO, $module, $item, $self, $action;

        $idgroup = isset($item) ? $item : $this->getFieldValue('key'); // $item (get) ou $this->key (post)
        $MIOLO->assert( isset($idgroup), 'Group não foi informado!', $action);
        $objGroup = &$this->objGroup;
        $objGroup->getById($idgroup);
        $conf = $this->getFormValue('conf');
	    if ( $conf == 'sim')
	    {
            if ( $objGroup->delete() )
	        {
			   $MIOLO->prompt(Prompt::information("Group [$objGroup->group] excluído com sucesso.",$this->listURL));
	        }
	        else
	        {
		       $MIOLO->prompt(Prompt::information( $objGroup->getErrors(),$action));
            }
	    }
	    elseif ( $conf == 'nao')
        {
	       $MIOLO->prompt(Prompt::information('Exclusão cancelada.',$this->listURL));
        }
	    else
	    {
		    $action_sim = $MIOLO->getActionURL($module,$self,$idgroup, array('event'=>'btnDelete:click','conf'=>'sim'));
		    $action_nao = $MIOLO->getActionURL($module,$self,$idgroup, array('event'=>'btnDelete:click','conf'=>'nao'));
	        $MIOLO->prompt(Prompt::question("Confirma a exclusão do group [$objGroup->group]?", 
				$action_sim, $action_nao));
	    }
	}

    public function chunkRs($rs, $key=0, $value=1, $showKeyVal=true)
    {
        foreach ($rs as $rs1)
        {
            if (is_array($rs1))
            {
                if ($showKeyVal)
                {
                    $rsNew[trim($rs1[$key])] = trim($rs1[$key])." - ".trim($rs1[$value]);
                }
                else
                {
                    $rsNew[trim($rs1[$key])] = trim($rs1[$value]);
                }
            }
            else
            {
                return $rs;
            }
        }
    
        return $rsNew;
    }

    public function getColumn($array, $col=null)
    {
       if (isset($col))
       {
          if (is_array($col))
          {
             for ($i=0; $i < count($array); $i++)
             {
                foreach($col as $c)
                {
                   $rs[][$c] = $array[$i][$c];
                }
             }
          }
          else
          {
             for ($i=0; $i < count($array); $i++)
             {
                $rs[] = $array[$i][$col];
             }
          }
       }
	   return $rs;
    }


}

?>
