<?
class frmModule extends MForm
{
	var $home;
    public $objModule;

	function __construct()
    {   global $MIOLO, $module, $action;

        $this->home      = $MIOLO->getActionURL($module,$action);
        $this->objModule = $MIOLO->getBusiness($module,'module');
		parent::__construct('Modules');
        $this->setWidth('65%');
        $this->setIcon($MIOLO->getUI()->getImage('admin','system1.png'));
        $this->setClose($MIOLO->getActionURL('admin','main'));
	    $this->eventHandler();
	}

    public function createFields()
	{  global $MIOLO;

       $fields = array(
           new MTextField('edtIdModule','','Módulo',50),
           new MTextField('edtNome','','Nome',50),
           new MMultiLineField( 'edtDescricao','','Descrição',30,5,30),
       );
	   $this->setFields($fields);

       $this->setFieldsVisible(false);
	   $this->setFieldAttr('edtIdModule','visible',true);

       $buttons = array(
           new MButton('btnEdit',   'Editar'),
		   new MButton('btnNew',    'Incluir'),
           new MButton('btnDelete', 'Excluir'),
	       new MButton('btnList',   'Relação')
       );
	   $this->setButtons($buttons);
       var_dump(ok);
	}

    public function setFieldsVisible($value)
    {
	   $this->setFieldAttr('edtIdModule','visible',$value);
	   $this->setFieldAttr('edtNome','visible',$value);
	   $this->setFieldAttr('edtDescricao','visible',$value);
    }

/*
    GetData: obtém os valores fornecidos no formulario e cria um objeto FormData
             cujos attributos têm o mesmo nome dos atributos do objeto que vai receber os valores.
    A implementação default do GetData cria um objeto FormData cujos atributos têm
    o mesmo nome dos campos do formulário.   
*/
	function getData()
	{
        $data = new FormData();
		$data->idModule = $this->getFieldValue('edtIdModule');
		$data->nome     = $data->name = $this->getFieldValue('edtNome');
		$data->descricao= $data->description = $this->getFieldValue('edtDescricao');
        return $data;
	}

/*
    SetData: obtém os valores fornecidos através do parâmetro $data (geralmente um
             objeto de negócio) e preenche os campos do formulário.
    A implementação default do SetData assume que os atributos do objeto $data têm
    o mesmo nome dos campos do formulário.   
*/
	function setData($data)
	{
		$this->setFieldValue('edtIdModule' , $data->idModule);
		$this->setFieldValue('edtNome'     , $data->nome);
		$this->setFieldValue('edtDescricao', $data->descricao);
	}

	function btnPost_click()
	{
		global $MIOLO;

        $module = $this->getFieldValue('edtIdModule');  // inclusão ou edição?
        
        if ($module != '')
        {
            $this->objModule->getById($module); // se for edição, obtem os dados atuais do objeto
        }
        // seta os atributos do objeto com os valores dos campos do formulario
		$this->objModule->setData($this->getData()); 

        try
        {
            $this->objModule->save();
            $MIOLO->information('Módulo atualizado com sucesso.', $this->home );
        }
        catch (EMioloException $e)
        {
            $this->addError($e->getMessage());
	    }
	}

	function btnList_click()
	{   
		global $MIOLO, $module, $action;

        // limpa o formulário
        $this->clearFields();
        $this->clearButtons();
        $this->defaultButton = false;
 
        // define o campo para fazer o filtro
        $fields = array(
            array(
               new MTextField('txtId'  ,'' ,'Módulo',25),
               new MButton   ('btnList','Relação')
            )
        );
        $this->setFields($fields);

        // colunas do DataGrid
        $columns = array(
           new MDataGridColumn('idmodule' ,'Id'       ,'left', true, '40%',true),
           new MDataGridColumn('name'     ,'Nome'     ,'left', true, '60%',true, NULL, true,true),
        );

        // link de referencia para o grid
		$hrefDatagrid = $MIOLO->getActionURL($module,$action,'', Array('event'=>'btnList_click'));

        // valor definido como filtro
        $id = MUtil::NVL($this->getFieldValue('txtId'), '');

        // executa a query
        $query = $this->objModule->listById($id);

        // instancia o datagrid
        $datagrid = new MDataGrid($query, $columns, $hrefDatagrid, 20);
        $datagrid->setTitle('Relação de Módulos');
        $datagrid->setClose($MIOLO->getActionURL($module,$action));

 	    $href_edit = $MIOLO->getActionURL($module,$action,'%0%',Array('event'=>'btnEdit:click'));
	    $href_dele = $MIOLO->getActionURL($module,$action,'%0%',Array('event'=>'btnDelete:click'));
        $datagrid->addActionUpdate($href_edit);
	    $datagrid->addActionDelete($href_dele);
        // coloca o datagrid no formulário
		$this->addField($datagrid);
	}

	function btnEdit_click($sender, $key='')
	{   
        global $item;

        $module = $this->getFieldValue('edtIdModule');
        // verifica se está sendo executado através do evento do grid
        $item = ($module != '') ? $module : $item;
        $this->objModule->getById($item);
        
        if ($this->objModule->nome)
        {
            // coloca os dados do objeto nos campos do formulário
            $this->setData($this->objModule);
            // exibe os campos
            $this->setFieldsVisible(true);
            $this->setFieldAttr('idModule','readonly',true);
            $this->addButton(new MButton('btnCancel', 'Cancelar', $this->home));
            $this->setButtonAttr('btnEdit','name'    ,'btnPost');
            $this->setButtonAttr('btnPost','label'   ,'Gravar');
            $this->setButtonAttr('btnNew' ,'visible' , false);
        }
        else
        {
            $this->addError("Módulo [$module] não encontrado!");
        }
	}

	function btnCancel_click()
	{   
        $this->setFieldValue('edtIdModule','');
    }

	function btnNew_click($sender)
	{   
        $data = new FormData();
        $data->idModule = $this->getFieldValue('edtIdModule');
        if ($data->idModule != '')
        {
            $this->setData($data);
            $this->setFieldsVisible(true);
            $this->addButton(new MButton('btnCancel', 'Cancelar', $this->home));
            $this->setButtonAttr('btnEdit','name'   ,'btnPost');
            $this->setButtonAttr('btnPost','label'  ,'Gravar');
            $this->setButtonAttr('btnNew' ,'visible', false);
            $this->addValidator(new RequiredValidator('edtIdModule'));
            $this->addValidator(new RequiredValidator('edtNome'));
        }
        else
        {
            $this->addError("Por favor, informe a identificação para o novo módulo!");
        }
	}

	function btnDelete_click($sender, $key='')
	{   
		global $MIOLO, $module, $item, $self, $action, $url;

        $objModule = $this->objModule;
        $modulo    = $this->getFieldValue('edtIdModule');
        // verifica se está sendo executado através do evento do grid
        $item = ($key != '') ? $key : $item;
        $objModule->getById($item);
        
        if ($objModule->idModule)
        {
            $conf = $this->getFormValue('conf');
	        if ( $conf == 'sim')
	        {
                try
                {
                     $objModule->delete();
                     $MIOLO->prompt(Prompt::information("Módulo [$objModule->idModule] excluído com sucesso.",$this->home));
                }
                catch (EMioloException $e)
                {
		             $MIOLO->prompt(Prompt::information( $objModule->getErrors(),$this->home));
                }
	        }
	        elseif ( $conf == 'nao')
            {
	            $MIOLO->prompt(Prompt::information('Exclusão cancelada.',$this->home));
            }
	        else
	        {
		        $action_sim = $MIOLO->getActionURL($module,$action,$objModule->idUser, array('event'=>'btnDelete:click','conf'=>'sim'));
		        $action_nao = $MIOLO->getActionURL($module,$action,$objModule->idUser, array('event'=>'btnDelete:click','conf'=>'nao'));
	            $MIOLO->prompt(Prompt::question("Confirma a exclusão do módulo [$objModule->idModule]?", $action_sim, $action_nao));
            }
        }
        else
        {
            $this->addError("Módulo [$modulo] não encontrado!");
        }
	}

}

?>
