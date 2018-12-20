<?php
/**
 * <--- Copyright 2005-2011 de Solis - Cooperativa de Soluções Livres Ltda. e
 * Univates - Centro Universitário.
 * 
 * Este arquivo é parte do programa Gnuteca.
 * 
 * O Gnuteca é um software livre; você pode redistribuí-lo e/ou modificá-lo
 * dentro dos termos da Licença Pública Geral GNU como publicada pela Fundação
 * do Software Livre (FSF); na versão 2 da Licença.
 * 
 * Este programa é distribuído na esperança que possa ser útil, mas SEM
 * NENHUMA GARANTIA; sem uma garantia implícita de ADEQUAÇÃO a qualquer MERCADO
 * ou APLICAÇÃO EM PARTICULAR. Veja a Licença Pública Geral GNU/GPL em
 * português para maiores detalhes.
 * 
 * Você deve ter recebido uma cópia da Licença Pública Geral GNU, sob o título
 * "LICENCA.txt", junto com este programa, se não, acesse o Portal do Software
 * Público Brasileiro no endereço www.softwarepublico.gov.br ou escreva para a
 * Fundação do Software Livre (FSF) Inc., 51 Franklin St, Fifth Floor, Boston,
 * MA 02110-1301, USA --->
 *
 * @author Eduardo Bonfandini [eduardo@solis.coop.br]
 *
 * @version $Id$
 *
 * \b Maintainers \n
 * Eduardo Bonfandini [eduardo@solis.coop.br]
 * Jamiel Spezia [jamiel@solis.coop.br]
 * Jader Osvino Fiegenbaum [jader@solis.coop.br]
 *
 * @since
 * Class created on 06/08/2008
 *
 **/
$MIOLO->getClass('gnuteca3', 'controls/GFileUploader');
class FrmPerson extends GForm
{
    public $MIOLO;
    public $module;
    public $busLibraryUnit;
    private $busBond;

    function __construct()
    {
        $this->MIOLO  = MIOLO::getInstance();
        $this->module = MIOLO::getCurrentModule();
        $this->busLibraryUnit = $this->MIOLO->getBusiness($this->module, 'BusLibraryUnit');
        $this->busBond = $this->MIOLO->getBusiness($this->module, 'BusBond');

        $this->setAllFunctions('Person', null, array('personId'), array('personName'));
        parent::__construct();

        //limpa as repetitiveFields
        if  ( $this->primeiroAcessoAoForm() && ($this->function != 'update') )
        {
            GRepetitiveField::clearData('personPhone');
            GRepetitiveField::clearData('bond');
            GRepetitiveField::clearData('penalty');
            GRepetitiveField::clearData('personLibraryUnit');
            GRepetitiveField::clearData('documents');
        }
    }

    public function mainFields()
    {
        $tabControl = new GTabControl('tabControlPerson');
        
        if ( ($this->function == 'insert') && (USER_ESPECIFICAR_CODIGO_MANUALMENTE == DB_TRUE) )
        {
            $fields[] = new MTextField('personId', '', _M('Código', $this->module), FIELD_ID_SIZE);
            $validators[] = new MRequiredValidator('personId');
            $validators[] = new MIntegerValidator('personId');
        }
        elseif($this->function != 'insert')
        {
            $personId = new MTextField('personId', '', _M('Código', $this->module), FIELD_ID_SIZE);
            $personId->setReadOnly(TRUE);
            $fields[]     = $personId;
            $validators[] = new MRequiredValidator('personId');
        }

        if (MUtil::getBooleanValue(CHANGE_WRITE_PERSON) == TRUE)
        {
            $read = '';
            $validators[] = new MCepValidator('zipCode','','');
        }
        else
        {
            $read = 'TRUE';
        }

        $fields[]       = new MTextField('personName', $this->personName->value, _M('Nome',$this->module), FIELD_DESCRIPTION_SIZE, null, null, $read);
        $fields[]       = new MTextField('city', $this->city->value, _M('Cidade',$this->module), FIELD_DESCRIPTION_SIZE, null, null, $read);
        $lblZipCode     = new MLabel(_M('CEP', $this->module) . ':');
        $lblZipCode->setWidth(FIELD_LABEL_SIZE);
        $zipCode        = new MTextField('zipCode', $this->zipCode->value, null, FIELD_ID_SIZE,null,null, $read);
        $lblFormat      = new MLabel(_M('99999-999', $this->module) );
        $fields[]       = new GContainer('hctZipCode', array($lblZipCode, $zipCode, $lblFormat));
        $fields[]       = new MTextField('location', $this->location->value, _M('Logradouro',$this->module), FIELD_DESCRIPTION_SIZE, null, null, $read);
        $fields[]       = new MTextField('number', $this->number->value, _M('Número',$this->module), FIELD_ID_SIZE,null, null, $read);
        $fields[]       = new MTextField('complement', $this->complement->value, _M('Complemento',$this->module), FIELD_DESCRIPTION_SIZE,null, null, $read);
        $fields[]       = new MTextField('email', $this->email->value, _M('E-mail',$this->module), FIELD_DESCRIPTION_SIZE,null, null, $read);
        
        //domínios do sexo
        $fields[] = new GRadioButtonGroup( 'sex', _M('Sexo', $this->module).':' , BusinessGnuteca3BusDomain::listForRadioGroup('SEX'));
        $fields[] = new MCalendarField('dateBirth', null, _M('Data de nascimento', $this->module), FIELD_DATE_SIZE);
        $fields[] = new MTextField('profession', null, _M('Profissão',$this->module), FIELD_DESCRIPTION_SIZE);
        $fields[] = new MTextField('workPlace', null, _M('Local de trabalho',$this->module), FIELD_DESCRIPTION_SIZE);
        $fields[] = new MTextField('school', null, _M('Escola',$this->module), FIELD_DESCRIPTION_SIZE);
        
        //FIXME: quando usado o  id "description", valor não aparece no getData() do form
        $fields[] = new MMultiLineField('observation_', NULL, _M('Observação', $this->module), NULL, 5, 65);
        
        $password = new MPasswordField('password', $this->password->value, _M('Senha', $this->module), 10);
        $password->setReadOnly($read);

        $login = new MTextField('loginU', '', _M('Usuário',$this->module), FIELD_DESCRIPTION_SIZE,null, null, $read);
         
        if ( MY_LIBRARY_AUTHENTICATE_TYPE == BusinessGnuteca3BusAuthenticate::TYPE_AUTHENTICATE_LOGIN_BASE )
        {
            $bases =  BusinessGnuteca3BusAuthenticate::listMultipleLdap();
            $ldapBase = new GSelection('baseLdap', '', _M('Base', $this->module), $bases, false, '','', true);
            $fields[] = new MBaseGroup('groupPassword', _M('Autenticação Ldap'), array($password, $login, $ldapBase), 'vertical','css' , MControl::FORM_MODE_SHOW_SIDE );
            $validators[] = new MRequiredValidator('baseLdap');
        }
        else if ( MY_LIBRARY_AUTHENTICATE_TYPE == BusinessGnuteca3BusAuthenticate::TYPE_AUTHENTICATE_LOGIN )
        {
            $fields[] = new MBaseGroup('groupPassword', _M('Autenticação Ldap'), array($password, $login), 'vertical','css' , MControl::FORM_MODE_SHOW_SIDE  );
        }
        else
        {
            $fields[] = $password;
        }
        
        //campo para selecionar o grupo
        $personGroups = BusinessGnuteca3BusDomain::listForSelect('PERSON_GROUP');
        
        if ( $personGroups != null ) //Se tiver a preferencia PERSON_GROUP
        {
            $fields[] = new GSelection('personGroup', null, _M('Grupo', $this->module), $personGroups); //Mostra campo de person Group
        }
        
        $tabControl->addTab('tabMain', _M('Gerais'), $fields);

        unset($fields);
        $fields[] = $tabControl;
              
        //Bond
        $fldBond[] = new GSelection('linkId', '', _M('Código do grupo de usuário', $this->module), $this->busBond->listBond(true));
        $dateValidate   = new MCalendarField('dateValidate', $this->dateValidate->value, _M('Data de validade', $this->module) . ':', FIELD_DATE_SIZE, null);
        $fldBond[]      = $cont = new GContainer('hctDateValidate', array($lblDV, $dateValidate));
        $fldBond['oldDateValidate'] = new MTextField('oldDateValidate');
        $fldBond['oldDateValidate']->addStyle('display', 'none');
        $fldBond[]      = new MSeparator();
        $valids[]       = new MDATEDMYValidator('dateValidate', _M('Data de validade', $this->module), 'required');
        $valids[]       = new MIntegerValidator('linkId', _M('Código do grupo de usuário', $this->module), 'required');

        //Phone
        $fldPhone[]     = new GSelection('type', null, _M('Tipo', $this->module), BusinessGnuteca3BusDomain::listForSelect('TIPO_DE_TELEFONE'));
        $fldPhone[]     = new MTextField('phone', null, _M('Telefone', $this->module), FIELD_DESCRIPTION_SIZE);
        $validsPhone[]  = new MRequiredValidator('type',_M('Tipo',    $this->module));
        $validsPhone[]  = new GnutecaUniqueValidator('type',_M('Tipo',    $this->module));
        $validsPhone[]  = new MRequiredValidator('phone',_M('Telefone', $this->module));

        $phoneColumns[] = new MGridColumn( _M('Tipo',    $this->module), 'left', true, null, false, 'type' );
        $phoneColumns[] = new MGridColumn( _M('Tipo',    $this->module), 'left', true, null, true, 'typeDesc' );
        $phoneColumns[] = new MGridColumn( _M('Telefone', $this->module), 'left', true, null, true, 'phone' );
       
        $telephone = new GRepetitiveField('personPhone', _M('Telefone', $this->module), NULL, NULL, array('remove'));
        $telephone->setFields( $fldPhone );
        $telephone->setValidators( $validsPhone );
        $telephone->setColumns($phoneColumns);
        $telephone->setReadOnly($read);
        $tabControl->addTab('tabPhone',_M('Telefones', $this->module),array( $telephone));
        
        //documentos
        $document = new GRepetitiveField('documents', _M('Documento', $this->module), NULL, NULL, array('edit', 'remove'));
        $fldDocument[] = new GSelection('documentTypeId', null, _M('Tipo', $this->module), BusinessGnuteca3BusDomain::listForSelect('DOCUMENT_TYPE'));
        $fldDocument[] = $old = new MTextField('oldDocumentTypeId');
        $old->addStyle('display', 'none');
        $fldDocument[] = new MTextField('content', NULL, _M('Conteúdo', $this->module), FIELD_DESCRIPTION_SIZE);
        $fldDocument[] = new MTextField('organ', null, _M('Orgão', $this->module), FIELD_DESCRIPTION_SIZE);
        $fldDocument[] = new MCalendarField('dateExpedition', null, _M('Data de expedição', $this->module), FIELD_DATE_SIZE);
        $fldDocument[] = new MMultiLineField('observationD', NULL, _M('Observação', $this->module), NULL, 5, 65);
        
        $document->setFields( $fldDocument );

        $documentColumns[] = new MGridColumn( _M('Tipo',    $this->module), 'left', true, null, false, 'documentTypeId' );
        $documentColumns[] = new MGridColumn( _M('Tipo',    $this->module), 'left', true, null, true, 'documentTypeIdDesc' );
        $documentColumns[] = new MGridColumn( _M('Tipo',    $this->module), 'left', true, null, false, 'oldDocumentTypeId' );
        $documentColumns[] = new MGridColumn( _M('Conteúdo',    $this->module), 'left', true, null, true, 'content' );
        $documentColumns[] = new MGridColumn( _M('Orgão',    $this->module), 'left', true, null, true, 'organ' );
        $documentColumns[] = new MGridColumn( _M('Data de expedição',    $this->module), 'left', true, null, true, 'dateExpedition' );
        $documentColumns[] = new MGridColumn( _M('Observação',    $this->module), 'left', true, null, true, 'observationD' );

        $document->setColumns($documentColumns);
           
        $validsDocument[] = new MRequiredValidator('documentTypeId', _M('Tipo', $this->module));
        $validsDocument[] = new MRequiredValidator('content', _M('Conteúdo', $this->module));
        $validsDocument[] = new GnutecaUniqueValidator('documentTypeId');
        
        $document->setValidators($validsDocument);
        $tabControl->addTab('tabDocument',_M('Documentos', $this->module),array( $document));
        
        //repetitive bond
        $bond = new GRepetitiveField('bond', _M('Vínculo', $this->module), NULL, NULL, array('edit', 'remove'));
        $bond->setFields( $fldBond );
        $bond->setValidators( $valids );
        $tabControl->addTab('tabBond',_M('Vínculos', $this->module),array( $bond));

        $columns   = null;
        $valids    = null;
        $columns[] = new MGridColumn( _M('Código',    $this->module), 'left', true, null, true, 'linkId' );
        $columns[] = new MGridColumn( _M('Grupo de usuário',    $this->module), 'left', true, null, true, 'linkIdName' );
        $columns[] = new MGridColumn( _M('Data de validade', $this->module), 'left', true, null, true, 'dateValidate' );
        $columns[] = new MGridColumn( _M('Old date validate', $this->module), 'left', true, null, false, 'oldDateValidate' );

        $bond->setColumns($columns);

        //Penalty
        $fldPenalty['penaltyId'] = new MDiv('divPenaltyId', new MTextField('penaltyId'));
        $fldPenalty['penaltyId']->addStyle('display', 'none');
        $fldPenalty[] = new MTextField('observationP', $this->observation->value, _M('Observação', $this->module), FIELD_DESCRIPTION_SIZE);
        $valids[]     = new MRequiredValidator('observationP', _M('Observação', $this->module));

        $fldPenalty[] = new MTextField('internalObservation', $this->internalObservation->value, _M('Observação interna', $this->module), FIELD_DESCRIPTION_SIZE, _M('Não é visto pelos usuários', $this->module));
        $fldPenalty[] = new MCalendarField('penaltyDate', $this->penaltyDate->value, _M('Data da penalidade', $this->module), FIELD_DATE_SIZE, null);
        $valids[]     = new MDATEDMYValidator('penaltyDate', _M('Data da penalidade', $tihs->module), 'required');
        $fldPenalty[] = new MCalendarField('penaltyEndDate', $this->penaltyEndDate->value, _M('Data final de penalidade', $this->module) , FIELD_DATE_SIZE, null);

        $lblOperator = new MLabel(_M('Operador', $this->module) . ':');
        $lblOperator->setWidth(FIELD_LABEL_SIZE);
        $operator = new MTextField('operator', GOperator::getOperatorId());
        $operator->setReadOnly(true);
        $fldPenalty[] = new GContainer('hctOperator', array($lblOperator, $operator));
        $valids[] = new MRequiredValidator('operator', _M('Operador', $this->module));

        $lblLibraryUnit = new MLabel(_M('Unidade de biblioteca', $this->module) . ':');
        $lblLibraryUnit->setWidth(FIELD_LABEL_SIZE);
        $this->busLibraryUnit->filterOperator = TRUE;
        $libraryUnitId = new GSelection('libraryUnitId1', null, null, $this->busLibraryUnit->listLibraryUnit());
        $fldPenalty[] = new GContainer('hctLibraryUnit', array($lblLibraryUnit, $libraryUnitId));

        $tablePenalty = new GRepetitiveField('penalty', _M('Penalidade', $this->module), NULL, NULL, array('edit', 'remove'),'vertical' );
        $tablePenalty->setFields($fldPenalty);
        $tablePenalty->setValidators($valids);

        $tabControl->addTab('tabPenalty',_M('Penalidades', $this->module),array( $tablePenalty ));

        unset($columns, $valids);
        $columns[] = new MGridColumn( _M('Código',             $this->module), 'left', true, null, false,'penaltyId' );
        $columns[] = new MGridColumn( _M('Observação',      $this->module), 'left', true, null, true, 'observationP' );
        $columns[] = new MGridColumn( _M('Observação interna', $this->module), 'left', true, null, true, 'internalObservation' );
        $columns[] = new MGridColumn( _M('Data da penalidade',     $this->module), 'left', true, null, true, 'penaltyDate' );
        $columns[] = new MGridColumn( _M('Data final de penalidade', $this->module), 'left', true, null, true, 'penaltyEndDate' );
        $columns[] = new MGridColumn( _M('Operador',         $this->module), 'left', true, null, true, 'operator' );
        $columns[] = new MGridColumn( _M('Código da biblioteca',$this->module), 'left', true, null, false,'libraryUnitId1' );
        $columns[] = new MGridColumn( _M('Unidade de biblioteca',     $this->module), 'left', true, null, true, 'libraryName' );
        $tablePenalty->setColumns($columns);

        //Person library unit
        $labelName = array(
            'BusPersonLibraryUnit'      => _M('Permitir acesso a biblioteca', $this->module),
            'BusNotPersonLibraryUnit'   => _M('Negar acesso a biblioteca', $this->module),
        );
        $labelName = $labelName[CLASS_USER_ACCESS_IN_THE_LIBRARY];
        $this->busLibraryUnit->filterOperator = TRUE;
        $vctPersonLibraryUnit[] = new GSelection('libraryUnitId', null, _M('Unidade de biblioteca', $this->module), $this->busLibraryUnit->listLibraryUnit());

        $personLibraryUnit = new GRepetitiveField('personLibraryUnit', $labelName, NULL, NULL, array('edit', 'remove'));
        $personLibraryUnit->setFields($vctPersonLibraryUnit);

        if ( $labelName )
        {
            $tabControl->addTab('tabAcesso',_M('Acesso a biblioteca', $this->module),array( $personLibraryUnit ));
        }

        unset($columns);
        $columns[] = new MGridColumn( _M('Código da biblioteca',$this->module), 'left', true, null, false, 'libraryUnitId' );
        $columns[] = new MGridColumn( _M('Unidade de biblioteca',     $this->module), 'left', true, null, true, 'libraryName' );
        $personLibraryUnit->setColumns($columns);

        $validsAccess[] = new MRequiredValidator('libraryUnitId');
        $validsAccess[] = new GnutecaUniqueValidator('libraryUnitId');

        $personLibraryUnit->setValidators($validsAccess);
        
        //caso a integração de fotos com o sagu esteja ativada não mostra a aba de fotos
        if ( ! MUtil::getBooleanValue(SAGU_PHOTO_INTEGRATION) )
        {
            $photo[] = new GFileUploader(_M('Foto',$this->module) );
            GFileUploader::setLimit(1); //somente uma imagem por pessoa
            GFileUploader::setExtensions(array('png','jpg','jpeg','gif'), $deny);

            $tabControl->addTab('tabPhoto',_M('Foto', $this->module), $photo);
        }

        //seta os campos no formulário
        $this->setFields($fields);

        //validadores
        $validators[] = new MRequiredValidator('personName');
        $validators[] = new MEmailValidator('email', '', '');
     
        $this->setValidators($validators);
    }


    public function tbBtnSave_click($sender=NULL)
    {
        $data = $this->getData();
        $data->login = $data->loginU;
        
        $data->observation = $data->observation_; //FIXME: necessário, pois não funciona se id do campo for "description"
        $data->document = $data->documents; //FIXME: as repetitives não funcionam se usar o id "document", foi usado como "documents"
      
        //trata os dados da repetitive de documentos para salvar
        if ( is_array($data->documents) )
        {
            $data->document = $data->documents; //FIXME: as repetitives não funcionam se usar o id "document", foi usado como "documents"

            foreach ( $data->document as $key => $values )
            {
                if ( ($this->function != 'insert') && ( $values->updateData ) )
                {
                    if ( $values->oldDocumentTypeId != $values->documentTypeId )
                    {
                        $this->error(_M('O tipo de documento não pode ser alterado', $this->module));
                        return;
                    }
                }
                
                $data->document[$key]->observation = $values->observationD;
            }
        }        
        
        //Parse penalty data
        $penalty = GRepetitiveField::getData('penalty');
        $data->phone = $data->personPhone;

        if ($penalty)
        {
        	foreach ($penalty as $v)
        	{
                $v->observation = $v->observationP;
                $v->libraryUnitId = $v->libraryUnitId1;
        	}
        }

        $data->penalty = $penalty;
        $coverData = GFileUploader::getData();
        
        if (  parent::tbBtnSave_click($sender, $data) )
        {
            if ( ! MUtil::getBooleanValue(SAGU_PHOTO_INTEGRATION) )
            {
                $this->savePhoto( $this->business->personId, $coverData );
            }
        }
    }

    public function savePhoto( $personId , $coverData )
    {
        if ( !$personId )
        {
            throw new Exception ( _M('Falha ao enviar capa. Pessoa não definida!','gnuteca3') );
        }

        $busFile        = $this->MIOLO->getBusiness('gnuteca3','BusFile');
        $busCatalogue   = $this->MIOLO->getBusiness( 'gnuteca3', 'BusCataloge');
        $folder         = 'person';

        if ( $coverData )
        {
            //converte o nome do arquivo para o código da pessoa, foreach caso o id seja diferente de i
            foreach ( $coverData as $line => $info)
            {
                if ( $info->tmp_name )
                {
                    $extension = explode('.',$coverData[$line]->basename);
                    $extension = $extension[ count($extension)-1 ];
                    $coverData[$line]->basename = $personId.'.'.$extension;
                }
            }

            //caso já exista uma photo estocada, remove-a, só pode existir uma capa por arquivo
            if ( $busFile->fileExists( $folder, $personId, 'png') && $coverData[0]->tmp_name )
            {
                $filePath = $busFile->getAbsoluteFilePath( $folder, $personId, $extension );
                $busFile->deleteFile($filePath);
            }

            $busFile->folder = $folder;
            $busFile->files = $coverData;
            $ok = $busFile->insertFile(); //insere o arquivo
            GFileUploader::clearData(); //limpa o sessão para evitar fazer 2 vezes a mesma coisa
        }
    }


    public function loadFields()
    {
        try
        {
            $data = $this->business->getPerson( MIOLO::_REQUEST('personId') );
            
            $data->observation_ = $data->observation; //FIXME: necessário, pois não funciona se id do campo for "description"
           
            $data->personPhone = $data->phone;
            unset($data->phone);
            
            $data->loginU = $this->business->login;
            
            //setData no formulário
            $this->setData($data);
            
            //Parse penalty data
            $penalty = $data->penalty;
            if ($penalty)
            {
                foreach ($penalty as $i => $v)
                {
                    $penalty[$i]->observationP = $v->observation;
                	$penalty[$i]->libraryUnitId1 = $v->libraryUnitId;
                }
            }
            
            //setData das repetitive
            GRepetitiveField::setData($this->personPhoneParse($data->personPhone), 'personPhone');
            GRepetitiveField::setData($this->personDocumentParse($data->document, true), 'documents');
            GRepetitiveField::setData($this->personBondParse($data->bond), 'bond');
            GRepetitiveField::setData($penalty, 'penalty');
            GRepetitiveField::setData($data->personLibraryUnit, 'personLibraryUnit');

            //obtem a foto caso existe
            $busFile = $this->MIOLO->getBusiness('gnuteca3','BusFile');
            $busFile->folder    = 'person';
            $busFile->fileName  = MIOLO::_REQUEST('personId').'.';

            GFileUploader::clearData();
            GFileUploader::setData( $busFile->searchFile(true) );
        }
        catch( EDatabaseException $e )
        {
            $this->error( $e->getMessage() );
        }
    }

    
    public function addToTable($args, $forceMode = FALSE)
    {
        $errors = array();
    	$item = $args->GRepetitiveField;
    	switch($item)
    	{
    		case 'penalty':
    			$args = $this->penaltyParse($args);
    			break;
    		case 'personLibraryUnit':
    			$args = $this->personLibraryUnitParse($args);
                break;
    		case 'personPhone':
    			$args = $this->personPhoneParse($args);
    			break;
            case 'bond':
                $args = $this->personBondParse($args);
            case 'documents':
                $args = $this->personDocumentParse($args);
                break;    
                
                $arrayItem = $args->arrayItemTemp;
                $data = GRepetitiveField::getData($args->GRepetitiveField);
                if ( is_array($data) )
                {
                    foreach( $data as $key => $value )
                    {
                        //identifica o item da repetitive
                        if ( ($value->arrayItem == $arrayItem) && ($args->__mainForm__EVENTTARGETVALUE == 'addToTable') )
                        {
                            if ( $value->linkId != $args->linkId )
                            {
                                $errors[] = _M('O grupo de usuário não pode ser alterado', $this->module);
                            }
                        }
                    }
                }
                
                break;
    	}
        
        $error = null;
        if ( count($errors) > 0 )
        {
            $error = $errors;
        }

    	($forceMode) ? parent::forceAddToTable($args, null, $error) : parent::addToTable($args, null, $error);

    	if ($item == 'penalty')
    	{
    		$operator = GOperator::getOperatorId();
    		$this->page->onLoad("document.getElementById('operator').value = '{$operator}'");
    	}
    }


    public function forceAddToTable($args)
    {
        $this->addToTable($args, TRUE);
    }


    /**
     * Trata os dados da multa ao adicionar um valor
     * 
     * @param $data
     */    
    function penaltyParse($data)
    {
        if (is_array($data))
        {
            $arrData = array();
            for ($i=0, $c=count($data); $i < $c; $i++)
            {
                $arrData[] = $this->penaltyParse($data[$i]);
            }
            return $arrData;
        }
        else if (is_object($data))
        {
            if ($data->libraryUnitId1)
            {
                $data->libraryUnitId = $data->libraryUnitId1;
            }
            $data->libraryName    = $this->busLibraryUnit->getLibraryUnit($data->libraryUnitId)->libraryName;
            return $data;
        }
    }


    /**
     * Trata os dados da uniade de biblioteca ao adicionar um valor
     * 
     * @param $data
     */
    public function personLibraryUnitParse($data)
    {
    	if (is_array($data))
    	{
    		$arr = array();
    		foreach ($data as $val)
    		{
    			$arr[] = $this->personLibraryUnitParse($val);
    		}
    		return $arr;
    	}
    	else if (is_object($data))
    	{
    		$data->libraryName = $this->busLibraryUnit->getLibraryUnit($data->libraryUnitId)->libraryName;
            return $data;
    	}
    }
    
    
    /**
     * Trata os dados do telefone ao adicionar um valor
     * 
     * @param $data
     * @return dados tratados
     */
    public function personPhoneParse($data)
    {
        if (is_array($data))
        {
            $arr = array();
            foreach ($data as $val)
            {
                $arr[] = $this->personPhoneParse($val);
            }
            
            return $arr;
        }
        else if (is_object($data))
        {
        	$domain = BusinessGnuteca3BusDomain::listForSelect('TIPO_DE_TELEFONE', false, true);
            $data->typeDesc = $domain[$data->type];

            return $data;
        }
    }


    /**
     * Método que trata os dados da repetitive de vínculos
     *
     */
    public function personBondParse($data)
    {
        if (is_array($data))
        {
            $arr = array();
            foreach ($data as $val)
            {
                $arr[] = $this->personBondParse($val);
            }

            return $arr;
        }
        else if (is_object($data))
        {
            $link = $this->busBond->listBond();
            
            if ( is_array($link) )
            {
                foreach( $link as $key => $values )
                {
                    if ( $values[0] == $data->linkId )
                    {
                        $data->linkIdName = $values[1];
                        break;
                    }
                }
            }
            
            $dataRepetitive = GRepetitiveField::getDataItem($data->arrayItemTemp, $data->GRepetitiveField);
            $data->oldDateValidate = $dataRepetitive->dateValidate;

            return $data;
        }
    }
    
     /**
     * Método que trata os dados da repetitive de vínculos
     * 
     */
    public function personDocumentParse($data, $loadFields = false)
    {
        if (is_array($data))
        {
            $arr = array();
            foreach ($data as $val)
            {
                $arr[] = $this->personDocumentParse($val, $loadFields);
            }

            return $arr;
        }
        else if (is_object($data))
        {
            //quando for edição, grava qual o tipo de documento original, pois ele compara no salvar, para ver se o usuário mudou o tipo de documento
            if ( $loadFields )
            {
                $data->observationD = $data->observation;
                $data->oldDocumentTypeId = $data->documentTypeId; //grava o tipo anterior para comparar no salvar, pois o usuário não pode mudar o tipo na edição
            }
            
            $domain = BusinessGnuteca3BusDomain::listForSelect('DOCUMENT_TYPE', false, true);
            
            //obtém a descrição do documento
            if ( is_array($domain) )
            {
                $data->documentTypeIdDesc = $domain[$data->documentTypeId];
            }
            
            return $data;
        }
    }
}
?>