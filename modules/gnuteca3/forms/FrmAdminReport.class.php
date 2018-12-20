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
 *
 * @since
 * Class created on 29/07/2008
 *
 **/
$MIOLO->GetClass('gnuteca3', 'codabar');
class FrmAdminReport extends GForm
{
    public $business;
    public $reportData;

    const INTERVAL_CONTINUOUS   = 1;
    const INTERVAL_DISCRETE     = 2;
    const OPTION_CONTROL_NUMBER = 1;
    const OPTION_ITEM_NUMBER    = 2;

    public function __construct()
    {
    	global $navbar;
        $this->MIOLO = $MIOLO = MIOLO::getInstance();
        $module = MIOLO::getCurrentModule();
        
        $MIOLO->getClass($module, 'GPDFTable');        
        $this->business = $MIOLO->getBusiness( $module, 'BusReport');
                
        $this->setTransaction('gtcAdminReport');
        $this->reportData = $this->getReportData();
        parent::__construct();
        $this->setTitle( _M('Relatório', $module). ' - ' . $this->reportData->Title );
        
    }

    /**
     * Return all Data of current Report
     *
     * @return object the report data
     */
    public function getReportData()
    {
    	$data      = $this->business->getReport( $this->getReportId());
    	return $data;
    }

    /**
     * Return the selected reportId
     *
     * @return the selected reportId
     */
    public function getReportId()
    {
        return MIOLO::_REQUEST('reportId');
    }

    /*public function setGridColumnsArray( $columns)
    {
        $this->columns = $columns;
    }*/

    /**
     * Create the Fields of the Form
     *
     */
    public function createFields()
    {
    	$GFunction = new GFunction();
    	$GFunction->SetExecuteFunctions(true);
    	$data = $this->getReportData( );

        //Descrição do relatório a ser mostrada no topo da tela
        if ($data->description)
        {
            $fields[] = new MDiv('divDescription', $data->description, 'reportDescription');
        }

    	if ( $data->parameters )
    	{
    		foreach ( $data->parameters as $line => $info)
    		{
    			$value       = $GFunction->interpret( $info->defaultValue );
    			$identifier  = $GFunction->interpret( $info->identifier );
    			$label       = $GFunction->interpret( $info->label );
    			$lastValue   = $GFunction->interpret( $info->lastValue );

    			$value = ( $lastValue ) ? $lastValue : $value ;
                $value = $value ? $value : MIOLO::_REQUEST($identifier);

    			if ( $info->type == 'string' )
    			{
                    $fields[] = new MTextField( $identifier, $value, $label, FIELD_DESCRIPTION_SIZE);
    			}
                else if ( $info->type == 'int' )
                {
                    $fields[] = new MTextField( $identifier, $value, $label, FIELD_DESCRIPTION_SIZE);
                    $valids[] = new MIntegerValidator( $identifier );
                }
                else if ( $info->type == 'date' )
                {
                	$fields[] = new MCalendarField( $identifier, $value, $label );
                	$valids[] = new MDATEDMYValidator( $identifier );
                }
    			else if ( $info->type == 'select')
    			{
    				$options = $GFunction->interpret( $info->options );

       				if ( !is_array( $options ) ) //se sobrou string tentar fazer parser
    				{
       				    $optionsTemp = explode("\n", $options);

    				    unset( $options );

	    				if ( $optionsTemp )
	    				{
	    					foreach ( $optionsTemp as $l => $i )
	    					{
	    						$temp =  explode(' ', $i );
	    						$options[ $temp[0] ] = $temp[1];
	    					}
	    				}
    				}

    				$fields[] = new GSelection( $identifier, $value, $label, $options);
    			}
                else if ( $info->type == 'itemNumber')
                {
                    $options = array(
                        array(_M('Contínuo', $this->module), self::INTERVAL_CONTINUOUS),
                        array(_M('Discreto', $this->module), self::INTERVAL_DISCRETE),
                    );

                    $controls[] = $interval = new GRadioButtonGroup( $identifier, _M('Intervalo', $this->module), $options, self::INTERVAL_CONTINUOUS, null, 'vertical');
                    $form       = $this->manager->page->getFormId();
                    $jsOnchangeInterval = "miolo.doAjax( (dojo.byId('{$identifier}_0').checked ? 'getContinuousFields' : 'getDiscreteFields') ,'','{$form}');";
                    $interval->addAttribute('onchange', $jsOnchangeInterval );

                    //se primeiro acesso recarregado campo de intervalo
                    if ( $this->primeiroAcessoAoForm() )
                    {
                        $this->page->onload( $jsOnchangeInterval );
                        //caso for primeiro acesso ao form limpa o repetitive
                        GRepetitiveField::clearData( 'codes' );
                    }

                    $options = array(
                        array(_M('Número do exemplar', $this->module), self::OPTION_ITEM_NUMBER),
                        array(_M('Número de controle', $this->module), self::OPTION_CONTROL_NUMBER),
                    );

                    $controls[] = new GRadioButtonGroup('exemplarys', _M('Exemplares', $this->module), $options, self::OPTION_ITEM_NUMBER, null, 'vertical');
                    $controls[] = new MDiv('divInterval', $this->getContinuousFields(TRUE));

                    $fields[] = new MBaseGroup('', $label , $controls );
                    $fields[] = new MSeparator('</br>');
                }

    			$valids[] = new MRequiredValidator( $identifier );
    		}
    	}

        $this->forceFormContent = true;
        $this->setFields( $fields );
        $this->setValidators($valids);

        $this->_toolBar->disableButtons( array( MToolBar::BUTTON_NEW , MToolBar::BUTTON_SEARCH ) );

        //ler dados do formulário
        $form = 'frmadminreport'.MIOLO::_REQUEST('reportId');
        $this->className = $form;

        $this->busFormContent->loadFormValues( $this ); //forma padrão

        $formContent = $this->busFormContent->loadFormValues( $this, true ); //obter coluna total

        if ( $formContent['total'] )
        {
            $totalField = $this->GetField('total');

            if ( $totalField )
            {
                $totalField->setChecked( true );
            }
        }
    }

    /**
     * Salva dados do formulário
     * @param stdClass
     */
    public function tbBtnFormContent_click($args)
	{
		$data = $this->getData();

        $form = 'frmadminreport'.MIOLO::_REQUEST('reportId');

		if ( $this->busFormContent->saveFormValues( $form , $data) )
		{
		  $this->information(_M('Configurações salvas', $this->module), GUtil::getCloseAction(true) );
		}
		else
		{
			$this->error(_M('Error saving settings', $this->module), GUtil::getCloseAction(true) );
		}
	}

    /**
     * Obtem os fields para modo contínuo
     *
     * @param unknown_type $return
     * @return unknown
     */
    public function getContinuousFields($return = FALSE)
    {
        $lbl = new MLabel( _M('Código inicial', $this->module) );
        $lbl->setWidth(FIELD_LABEL_SIZE);
        $flds[] = $lbl;
        $flds[] = new MTextField('beginCode', null, null, FIELD_ID_SIZE);

        $flds[] = new MSeparator();
        $lbl = new MLabel( _M('Código final', $this->module) );
        $lbl->setWidth(FIELD_LABEL_SIZE);
        $flds[] = $lbl;
        $flds[] = new MTextField('endCode', null, null, FIELD_ID_SIZE);

        $hct = new MDiv('hctContinuous', $flds);

        if ($return)
        {
            return $hct;
        }
        
        $this->setResponse($hct, 'divInterval');
        $this->setFocus('beginCode');
    }


    /**
     * Obtem os fields para modo discreto
     *
     */
    public function getDiscreteFields()
    {
        $flds[] = new MTextField('itemNumber_', null, _M('Número do exemplar', $this->module), FIELD_ID_SIZE);
        $cols[] = new MGridColumn(_M('Número do exemplar', $this->module), MGrid::ALIGN_LEFT, true, null, true, 'itemNumber_');
        $valids[] = new GnutecaUniqueValidator('itemNumber_', _M('Número do exemplar', $this->module), 'required');
        $interval = new GRepetitiveField('codes', _M('Itens', $this->module), $cols, $flds);
        $interval->setValidators($valids);
        $fields[] = $interval;

        $this->setResponse( $fields, 'divInterval' );
        $this->setFocus('itemNumber');
    }


    /**
     * Set the fields adding needed fields to report system
     *
     * @param array $fields the fields array
     */
    public function setFields( $fields )
    {
        $busFile = $this->MIOLO->getBusiness('gnuteca3','BusFile');

    	$typeOpt['list']   = _M('Lista', $this->module );
        $typeOpt['pdf']    = _M('PDF', $this->module );
        $typeOpt['csv']    = _M('CSV', $this->module );

        if ( $busFile->fileExists( 'odt', BusinessGnuteca3BusFile::getValidFilename($this->reportData->reportId).'.') )
        {
            $typeOpt['odt'] = _M('Modelo ODT', $this->module );
        }

        $reportType = new GSelection('reportType', MIOLO::_REQUEST('reportType') ? MIOLO::_REQUEST('reportType') : 'list', _M('Tipo', $this->module ), $typeOpt);
    	$reportType->addAttribute('onchange', "
    	   var sel  = dojo.byId('reportType').selectedIndex;
    	   var type = dojo.byId('reportType').options[ sel ].value;
    	   dojo.byId('divPageOrientation').style.display = (type == 'pdf') ? 'block' : 'none';
    	");
    	$fields[] = $reportType;

        //ista linha é para funcionar o formcontent
        $this->page->onload( "dojo.byId('reportType').onchange();");
    	
    	$formats    = array(
    	   'P'     => _M('Retrato', $this->module),
    	   'L'     => _M('Paisagem', $this->module),
    	);

    	$lbl = new MLabel(_M('Formato da página') . ':');
    	$lbl->setWidth(FIELD_LABEL_SIZE);
    	$pageOrientation = new GSelection('pageOrientation', MIOLO::_REQUEST('pageOrientation'), null, $formats, null, null, null, true);
    	$fields[] = $hctPageOrientation = new GContainer('divPageOrientation', array($lbl, $pageOrientation));

   	
        $valids[] = new MRequiredValidator( 'reportType' );
        $fields[] = $total = new MCheckBox('total', 'total', _M('Total', $this->module), false) ;
        $total->addAttribute('onchange', "dojo.byId('totalColumn').parentNode.parentNode.style.display= this.checked ? 'block' : 'none';");
        $columns = $this->getSqlColumns( $this->reportData->reportSql, $this->reportData->reportSubSql);
        $fields[] = new GSelection( 'totalColumn', null , _M('Coluna', $this->module),$columns ,null, null, null, true);
        $fields[] = new MButton('btnSearch', _M('Gerar', $this->module), GUtil::getAjax( 'searchFunction' ), GUtil::getImageTheme('document-16x16.png'));
        $fields[] = new MDiv( self::DIV_SEARCH );

        //esconde a coluna do total por padrão (caso não tenha dados no post
        $this->page->onload( "dojo.byId('total').onchange();");

        parent::setFields( $fields );
        
        //dispara a pesquisa
        if ( $this->primeiroAcessoAoForm() &&  MIOLO::_REQUEST('doSearch') )
        {
            $this->page->onload(GUtil::getAjax('searchFunction'));
        }
    }

    public function searchFunction($args)
    {
        $data       = $this->reportData;
        $reportType = MIOLO::_REQUEST('reportType');
        $beginCode  = $args->beginCode;
        $endCode    = $args->endCode;
        $exemplarys = $args->exemplarys;

        //localiza um parametro com tipo itemNumber
        if ( $data->parameters )
    	{
    		foreach ( $data->parameters as $line => $param)
    		{
                if ( $param->type == 'itemNumber')
                {
                    $intervalName = $param->identifier;
                }
            }
        }

        //trata os dados caso exista um campo do tipo itemNumber
        if ( $intervalName )
        {
            $interval = $args->$intervalName;
            $busExemplaryControl = $this->manager->getBusiness('gnuteca3', 'BusExemplaryControl');

            if ( ( $interval == self::INTERVAL_CONTINUOUS ) && ( $exemplarys == self::OPTION_ITEM_NUMBER ) )
            {
                $lengthFirst = strlen(trim($beginCode));

                for ( $x = $beginCode; $x <= $endCode; $x++ )
                {
                    //completa os 0000 na frente
                    $itemNumber = GUtil::strPad($x, $lengthFirst, '0', STR_PAD_LEFT);
                    //$codes[$x] = $busExemplaryControl->getExemplaryControl( $itemNumber );
                    $codes[$itemNumber] = $itemNumber;
                }
            }
            else if ( ($interval == self::INTERVAL_CONTINUOUS) && ($exemplarys == self::OPTION_CONTROL_NUMBER) )
            {
                $lengthFirst = strlen(trim($beginCode));

                for ( $x=$beginCode; $x<=$endCode; $x++ )
                {
                    //completa os 0000 na frente
                    $itemNumber = GUtil::strPad($x, $lengthFirst, '0', STR_PAD_LEFT);
                    $exemplary = $busExemplaryControl->getExemplaryOfMaterial($itemNumber);

                    if ($exemplary)
                    {
                        foreach ($exemplary as $ex)
                        {
                            $codes[ $ex->itemNumber ] = $ex->itemNumber;
                        }
                    }
                }
            }
            else if ( ($interval == self::INTERVAL_DISCRETE) && ($exemplarys == self::OPTION_ITEM_NUMBER) )
            {
                $codeList = GRepetitiveField::getData('codes');
                $codes    = null;

                if ( $codeList )
                {
                    foreach ( $codeList as $key => $c )
                    {
                        //Não adicionar exemplares excluídos
                        if ( !$c->removeData )
                        {
                            //$codes[$key] = $busExemplaryControl->getExemplaryControl($c->itemNumber_);
                            $codes[$c->itemNumber_] = $c->itemNumber_;
                        }
                    }
                }
            }
            else if ( ($interval == self::INTERVAL_DISCRETE) && ($exemplarys == self::OPTION_CONTROL_NUMBER) )
            {
                $codeList = GRepetitiveField::getData('codes');
                $codes    = null;

                if ($codeList)
                {
                    foreach ($codeList as $c)
                    {
                        //Não adicionar números de controle excluídos
                        if (!$c->removeData)
                        {
                            $exemplary = $busExemplaryControl->getExemplaryOfMaterial($c->itemNumber_);

                            if ($exemplary)
                            {
                                foreach ($exemplary as $ex)
                                {
                                    $codes[ $ex->itemNumber ] = $ex->itemNumber;
                                }
                            }
                        }
                    }
                }
            }

            //colca no post e request para tudo funcionar corretamente.
            $itemNumber = "'".implode("','",$codes)."'";
            $_POST[$intervalName] = $itemNumber;
            $_REQUEST[$intervalName] = $itemNumber;
        }

        if ( $reportType == 'list' || ! $reportType)
        {
            $fields[] = $this->getGrid();
        }
        else if ($reportType == 'csv')
        {
            $csv      = $this->getCSV( ';' );
            $fields[] = new MLabel( str_replace("\n", '<br>', $csv ) ) ;
            BusinessGnuteca3BusFile::openDownload('report',"{$data->Title}.csv", $csv);
        }
        else if ($reportType == 'pdf')
        {
            BusinessGnuteca3BusFile::openDownload('report',"{$data->Title}.pdf", $this->getPDF());
        }
        else if ( $reportType == 'odt')
        {
            
            try
            {
                $filename = $this->getOdt();
            }
            catch (Exception $exc)
            {
                GForm::error( $exc->getMessage() );
            }

            if ( $filename )
            {
                BusinessGnuteca3BusFile::openDownload('report' , $filename);
            }
        }

        $this->setResponse( $fields, self::DIV_SEARCH);
    }

    /**
     * Adiciona o total ao array de dados, caso for necessário
     *
     * @param array $result os dados do relatório
     * @param array $columns array de colunas do relatório
     * @return array dados com adição de total
     */
    public function addTotal( $result , $columns )
    {
        $total = MIOLO::_REQUEST('total') == 'total' ? true : false ;
        $totalColumn = MIOLO::_REQUEST('totalColumn'); //para o usuário usar 1 ou maior

        if ( is_array($result) && $total && $totalColumn >= 0 )
        {
            //coloca a contagem de acordo com array considerando 0 como primeiro
            $collumCount = count( $result[0] ) - 1;

            if ( $collumCount <= $totalColumn)
            {
                foreach ( $result as $line => $info )
                {
                    $totalCount += $info[$totalColumn];
                }
            }

            $totalLine[] = _M('Total geral da coluna', $this->module) . ' ' . $columns[$totalColumn];

            //variável utilizada para alinhamento perfeito do total
            $extrasCol = count( $result[0] ) - 2;

            if ( $extrasCol > 0 )
            {
                for ( $i = 0; $i < $extrasCol ; $i++ )
                {
                    $totalLine[] = '';
                }
            }

            //adiciona o total na última linha
            $totalLine[] = $totalCount;

            $result[] = $totalLine;
        }

        return $result;
    }

    public function getSqlColumns($sql, $subSql = null )
    {
        if ( $sql )
        {
           $columns = $this->business->parseSqlToColumnsArray( $sql );

           if ( MIOLO::_REQUEST('reportType') != 'detail' )
           {
               if ($subSql)
               {
                   $columns = array_merge($columns, $this->business->parseSqlToColumnsArray( $subSql ) );
               }
           }
        }

        return $columns;
    }

    /**
     * Returns the grid ready to use
     *
     * @return object the grid object
     */
    public function getGrid()
    {
        $data   = $this->getReportData();
    	$args   = $this->getData();

        $errors = $this->validate($args);

        if ( !$errors )
        {
            return false;
        }
        
        $sql     = $data->reportSql;
    	$subSql  = $data->reportSubSql;
        $result  = $this->business->executeSelect( $sql , $subSql, $args);
        $columns = $this->business->getResultFields();
        $result  = $this->addTotal( $result, $columns);

        if ( $columns )
        {
            foreach ( $columns as $line => $info )
            {
            	$gridColumns[] = new MGridColumn( $info, MGrid::ALIGN_LEFT, null, null, true, null, true);
            }
        }
        
        $grid = new GGrid(null, $gridColumns );

        if ( MIOLO::_REQUEST('reportType') == 'detail' )
        {
	        $gridArgs['0']          = '%0%';
	        $gridArgs['event']      = 'showDetail';
	        $hrefDetail             = $this->MIOLO->getActionURL($this->module, $this->action, null, $gridArgs);
	        $grid->addActionIcon( _M('Detalhes', $this->module), 'select', $hrefDetail );
       	    unset( $subSql );
        }
        
        $grid->setData( $result );
        $grid->setIsScrollable();

        return $grid;
    }


    public function getOdt()
    {
        $this->manager->getClass('gnuteca3', 'GOdt');

        $busFile = $this->MIOLO->getBusiness('gnuteca3','BusFile');

        $busFile = $this->MIOLO->getBusiness('gnuteca3','BusFile');
        $busFile->folder = 'odt';
        $busFile->fileName = BusinessGnuteca3BusFile::getValidFilename( $this->reportData->reportId ).'.';
        $file = $busFile->searchFile(true);
        $ext = $file[0]->extension;

        $odt = new GOdt( $file[0]->absolute );
        $odt->setVars('GREPORT_ID', $this->reportData->reportId );
        $odt->setVars('GREPORT_TITLE', $this->reportData->Title );
        $odt->setVars('GREPORT_DESC', $this->reportData->description );
        $odt->setVars('GREPORT_PERMISSION', $this->reportData->permission );
        $odt->setVars('GREPORT_SQL', $this->reportData->reportSql );
        $odt->setVars('GREPORT_SCRIPT', $this->reportData->script );
        $odt->setVars('GREPORT_ACTIVE', $this->reportData->isActive );
        $odt->setVars('GREPORT_GROUP', $this->reportData->reportGroup );

        $params = $this->reportData->parameters;

        //define variáveis de todos parametros
        if ( is_array( $params ) )
        {
            foreach ( $params as $line => $param )
            {
                $odt->setVars('GREPORT_PARAM_LABEL_'.$line, $param->label );
                $odt->setVars('GREPORT_PARAM_TYPE_'.$line, $param->type );
                $odt->setVars('GREPORT_PARAM_ID_'.$line, $param->identifier );
            }
        }

        $postData = $this->getData();

        //criar variáveis de post no relatório, para poder mostrar os filtros
        if ( is_array( $postData ) )
        {
            foreach ( $postData as $line => $info )
            {
                //tira os dados padrão do miolo
                if ( ! ( stripos( $line, '__') === 0 ) && $line != 'cpaint_response_type' )
                {
                    $odt->setVars( $line, $info );
                }
            }
        }

        $result = $this->business->executeSelect( $this->reportData->reportSql , $this->reportData->reportSubSql, $this->getData() );
        $columns = $this->getSqlColumns($this->reportData->reportSql, $this->reportData->reportSubSql);
        $result = $this->addTotal($result, $columns);

        try
        {
            $content = $odt->setSegment('content');
            $this->setOdtContent($content, $result, $columns); //seta o conteúdo no segmento
            $odt->mergeSegment( $content );

            //salva o arquivo
            $filename = BusinessGnuteca3BusFile::getValidFilename( 'report_'.uniqid( $this->reportData->reportId,true)).'.odt';
            $odt->output( 'report', BusinessGnuteca3BusFile::getAbsoluteFilePath('report', $filename) );

            return $filename;

        }
        catch (Exception $exc)
        {
            echo Gform::error( $exc->getMessage()  );
            return false;
        }
    }

    /**
     * Seta o conteúdo no segmeto "content"
     * @param Segment $content objeto do segmento
     * @param array $result resultado
     * @param array $columns colunas do arquivo
     */
    protected function setOdtContent(Segment $content, $result, $columns )
    {
        //defini dados para multiplicação de seguimentos
        if ( is_array($result) && is_array( $columns ) )
        {
            foreach ( $result as $line => $info )
            {
                foreach ( $columns as $l => $column )
                {
                    try
                    {
                        if ( $column == 'image' )
                        {
                            $parts = explode('/', $info[$l]); //separa o arquivo do diretório

                            $busFile = $this->MIOLO->getBusiness('gnuteca3','BusFile');
                            $busFile->folder= $parts[0]; //seta o diretório
                            $busFile->fileName = $parts[1]; //seta o arquivo
                            $pathFile = $busFile->searchFile(true);

                            //procura imagem default caso não tenha encotrado a imagem
                            if ( count($pathFile) == 0 )
                            {
                                $busFile->fileName = 'default.';
                                $pathFile = $busFile->searchFile(true);
                            }

                            $pathFile = $pathFile[0]->absolute; //obtém caminho absoluto da imagem

                            $content->setImage('image', $pathFile, 60, 75); //seta a imagem 3x4
                        }
                        else
                        {
                            $content->$column( utf8_decode( $info[$l] ) );
                        }
                    }
                    catch (Exception $exc)
                    {
                        //caso o parametro não exista no content
                    }
                }

                $content->merge();
            }
        }  
    }
    
    public function getCSV( $separator = ';' )
    {
    	$data   = $this->getReportData();
        $args   = $this->getData();
        $sql    = $data->reportSql;
        $subSql = $data->reportSubSql;
        $result = $this->business->executeSelect( $sql , $subSql, $args);
        $columns = $this->business->getResultFields();
        $result = $this->addTotal( $result, $columns );

        if ($result && $columns)
        {
	        foreach ($columns as $line => $info)
	        {
                $csv .= $info.$separator;
	        }
	        $csv .=  "\n";

	        foreach ( $result as $line => $info )
	        {
	        	//$csv
	        	foreach ( $info as $l => $i )
	        	{
	        		$csv .= $i.$separator;
	        	}

	        	$csv .= "\n";
	        }
        }

        return $csv;
    }
    
    public function getPDF()
    {
        $data   = $this->getReportData();
        $args   = $this->getData();
        $sql    = $data->reportSql;
        $subSql = $data->reportSubSql;
        $result = $this->business->executeSelect($sql , $subSql, $args);
        $columns= $this->business->getResultFields();
        $result = $this->addTotal( $result, $columns );
        $output = '';
        
        $orientation = $args->pageOrientation ? $args->pageOrientation : 'P';
        
        if ($result && $columns)
        {
            $pdf = new GPDFTable( $orientation, 'pt');
            $pdf->addTable( new MTableRaw($data->Title, $result, $columns) );
            
            $output = $pdf->Output(null, 'S');
        }
        
        return $output;
    }
    
    public function getData()
    {
        return (object) $_REQUEST;
    }
    
    /**
     * Retorna modo de busca para evitar mensagem de campos modificados
     * 
     * @return string 'search'
     */
    public function getFormMode()
    {
        return 'search';
    }
}
?>