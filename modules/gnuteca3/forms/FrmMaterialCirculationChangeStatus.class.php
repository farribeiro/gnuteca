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
 *
 * @author Eduardo Bonfandini [eduardo@solis.coop.br]
 *
 * @version $Id$
 *
 * \b Maintainers \n
 * Eduardo Bonfandini [eduardo@solis.coop.br]
 * Jamiel Spezia [jamiel@solis.coop.br]
 * Luiz Gregory Filho [luiz@solis.coop.br]
 * Moises Heberle [moises@solis.coop.br]
 * Sandro Roberto Weisheimer [sandro@solis.coop.br]
 *
 * @since
 * Class created on 12/01/2009
 *
 **/
class FrmMaterialCirculationChangeStatus extends FrmMaterialCirculationUserHistory
{
	public $MIOLO;
	public $module;
	public $busExemplaryStatus;


    public function __construct()
    {
    	$this->MIOLO  = MIOLO::getInstance();
    	$this->module = MIOLO::getCurrentModule();
    	$this->busExemplaryStatus = $this->MIOLO->getBusiness($this->module, 'BusExemplaryStatus');
        parent::__construct();
    }


    /**
    * Mount the ChangeStatus form , called when user press F12
    *
    **/
    public function onkeydown123( $args ) //F12
    {
    	$module = MIOLO::getCurrentModule();
        $this->setMMType('123');
        $this->changeTab('btnAction123');

        //Só tem acesso se tiver permissão gtcMaterialMovementChangeStatus
        if (GPerms::checkAccess('gtcMaterialMovementChangeStatus', NULL, false))
        {
            $functionButtons[]  = new MButton('btnChange',      _M('[F2] Alterar',   $module),   ':onkeydown113');
        }

        //Só mostra função de agendamento se operador tiver permissão
        if (GPerms::checkAccess('gtcMaterialMovementExemplaryFutureStatusDefined', NULL, false))
        {
            $functionButtons[]  = new MButton('btnSchedule',    _M('[F3] Agendar', $module),   ':onkeydown114');
        }
        
        $functionButtons[]  = new MButton('btnFinalize',    _M('[F4] Finalizar', $module),   ':onkeydown115');
        $functionButtons[]  = new MButton('btnCleanData',   _M('[ESC] Limpar', $module),':onkeydown27');

        $fields[]           = $this->getButtonContainer($functionButtons);
        $line               = null;
        $line[0][]          = $this->getLibrarySelection();

        //Monta lista de status válidos
        $busExemplaryStatus = $this->MIOLO->getBusiness($this->module, 'BusExemplaryStatus');
        $statusList         = $busExemplaryStatus->listExemplaryStatus(null, true);

        if (GPerms::checkAccess('gtcMaterialMovementChangeStatusInitial', null, false))
        {
            $levelStatus['level0'] = _M('Estado Anterior', $this->module);
            $statusList = array_merge($levelStatus, $statusList);
        }

        $line[1][0] = new MLabel( _M('Estado futuro', $this->module) );
        $line[1][1] = $exemplaryStatusId = new GSelection('exemplaryStatusId', '', null,$statusList, false, false, false,false) ;
        $exemplaryStatusId->addAttribute('onPressEnter', GUtil::getAjax('exemplaryStatusIdOnkeyDown'));
        $exemplaryStatusId->addEvent('change', GUtil::getAjax('exemplaryStatusIdOnkeyDown') );

        $downFields[] = new MVContainer('lowDateDiv', array(new MLabel('Data de baixa', $this->module), new MCalendarField('lowDate', GDate::now())));
        $downFields[] = new MMultiLineField('observation','',_M('Observação',$this->module), null, 8, 40);

        $line[3][1] = $divDown = new MBaseGroup('divDown',_M('Baixa',$this->module), $downFields, 'vertical');
        $divDown->addStyle('display','none');

        $lblItemNumber = new MLabel( _M('Número do exemplar', $this->module) . ':' );
        $itemNumber = new MTextField('itemNumber');
        $itemNumber->addAttribute('onPressEnter', GUtil::getAjax('itemNumberOnKeyDownChangeStatus'));
        $itemNumber->setReadOnly(true);

        $btnAdd = new MImageButton('btnAdd', NULL, "javascript:" . GUtil::getAjax('itemNumberOnKeyDownChangeStatus'), GUtil::getImageTheme('add-16x16.png'));
        $btnAdd->addAttribute('title', _M('Adicionar', $this->module));

        $line[2][0] = new MDiv('hctAdd', array($lblItemNumber, $itemNumber, $btnAdd));

        $tableChangeStatus  = new GRepetitiveField('tableChangeStatus', _M('Itens', $module), null, null, array('noButtons'));
        $tableChangeStatus->setShowButtons(false);

        $tableChangeStatusColumns  = array
        (
            new MGridColumn( _M('Número do exemplar', $module)         , 'left', true, "20%", true, 'itemNumber' ),
            new MGridColumn( _M('Dados',  $module)               , 'left', true, "64%", true, 'exemplaryData' ),
            new MGridColumn( _M('Estado do exemplar',  $module)   , 'left', true, "64%", true, 'exemplaryStatusDescription' ),
            new MGridColumn( _M('Data da baixa',  $module)           , 'left', true, "64%", false, 'lowDate' ),
            new MGridColumn( _M('Descrição da baixa',  $module)    , 'left', true, "64%", false, 'observation' ),
        );

        $tableChangeStatus->setColumns($tableChangeStatusColumns);
        $tableChangeStatus->addAction('removeItemNumberChangeStatus', 'table-delete.png', $module);

        $line[4][0]         = $tableChangeStatus;
        $fields             = array_merge($fields, $this->mountContainers($line) );
        $divChangeStatus    = new MDiv('divChangeStatus', $fields);

        $this->jsSetFocus('exemplaryStatusId', false);

        return $this->addResponse( $fields, $args );
    }


    /**
     * Function called when user press F2 change
     *
     * @param array $args
     */
    public function onkeydown113_123( $args )
    {
    	//Só mostra função de alterar se operador tiver permissão
        if (GPerms::checkAccess('gtcMaterialMovementChangeStatus', NULL, false))
        {
	        $this->setMMOperation('CHANGE');
	        $this->cleanData123( $args );
	    	$this->busOperationChangeStatus->setChangeType(1);
	        $this->jsChangeButtonColor('btnChange');
	        $this->jsEnabled('exemplaryStatusId');
	        $this->jsEnabled('libraryUnitId');
	        $this->jsShow('lowDateDiv');

	        if ( !$args->return )
	        {
	            $this->setResponse('','limbo');
	        }
        }
        else
        {
            $this->setResponse('','limbo');
            $this->onkeydown114_123();
        }
    }


    /**
     * Function called when user press F3 schedule
     *
     * @param array $args
     */
    public function onkeydown114_123( $args )
    {
        //Só mostra função de agendamento se operador tiver permissão
        if (GPerms::checkAccess('gtcMaterialMovementExemplaryFutureStatusDefined', NULL, false))
        {
	        $this->setMMOperation('SCHEDULE');
	    	$this->cleanData123( $args );
			$this->busOperationChangeStatus->setChangeType(2);
			$this->jsChangeButtonColor('btnSchedule');
			$this->jsEnabled('exemplaryStatusId');
	        $this->jsEnabled('libraryUnitId');
	        $this->jsHide('lowDateDiv');

			if ( !$args->return )
	        {
			  $this->setResponse('','limbo');
	        }
        }
        else
        {
            $this->setResponse('','limbo');
        }
    }


    /**
     * Function called when user press F4 (finalize)
     *
     * @param array $args
     */
    public function onkeydown115_123( $args )
    {
    	$ok                            = $this->busOperationChangeStatus->finalize();
    	$extraColumns['itemNumber']    = _M('Número do exemplar', $this->module );
    	$extraColumns['currentStatus'] = _M('Estado atual', $this->module );
    	$extraColumns['futureStatus']  = _M('Estado futuro', $this->module );
    	$table  = $this->busOperationChangeStatus->getMessagesTableRaw(null, null, $extraColumns);
        //é necessário dar o foco para o botão fechar para o esc funcionar
    	$this->jsSetFocus('btnClose');
    	$this->injectContent( $table, true, true );
        $this->cleanData123( $args );
    }


    /**
     * Clean change status Data
     *
     * @param object $args
     */
    public function cleanData123( $args )
    {
    	$this->jsChangeButtonColor('btnCleanData');

    	$this->jsSetValue('itemNumber', '' );
    	$this->jsSetReadOnly('itemNumber', true );

    	$this->jsDisabled('libraryUnitId');

    	$this->jsDisabled('exemplaryStatusId');
    	$this->jsSetValue('exemplaryStatusId','' );

    	$this->jsSetValue('observation', '' );
    	$this->jsHide('divDown');

        $this->busOperationChangeStatus->clearItems();

        if ( !$args->cleanData )
        {
            $args->cleanData = true;
            $op = $this->getMMOperation();
            //ifs de ultima ação e dados salvos
            if ($op == 'SCHEDULE')
            {
                $this->onkeydown114_123( $args );
            }
            else
            {
                $this->onkeydown113_123( $args );
            }
        }

        if ( !$args->return )
        {
        	$items = null ; //FIXME colocado pois o $items esta indefinido
            GRepetitiveField::update( $items , 'tableChangeStatus');
        }
    }


    /**
     * Event called when user press enter or tab in exemplaryStatus field
     *
     * @param object $args stdclass
     */
    public function exemplaryStatusIdOnkeyDown( $args )
    {
        $this->busOperationChangeStatus->setLibraryUnit( $args->libraryUnitId );

        //determina se é por level ou por estado futuro
        if ($args->exemplaryStatusId == 'level0')
        {
        	$this->busOperationChangeStatus->setLevel('0');
        }
        else
        if ($args->exemplaryStatusId == 'level1')
        {
        	$this->busOperationChangeStatus->setLevel('1');
        }
        else
        {
            $exemplaryStatus = $this->busOperationChangeStatus->setExemplaryFutureStatus( $args->exemplaryStatusId );
        }

        if ( MUtil::getBooleanValue( $exemplaryStatus->isLowStatus ) )
        {
        	$this->jsShow('divDown');
        }
        else
        {
        	$this->jsHide('divDown');
        }

        $this->page->onload( 'dojo.parser.parse();'); //faz o parse dos campos de calendário
        $this->jsSetReadOnly('itemNumber', false);
        $this->jsSetFocus('itemNumber');
        $this->setResponse('','limbo');
    }


    /**
     * Event called when user press enter or tab in itemNumber field
     *
     * @param object $args
     */
    public function itemNumberOnKeyDownChangeStatus( $args )
    {
        $ok = $this->busOperationChangeStatus->addItemNumber( $args->itemNumber , $args->lowDate, $args->observation );

        $this->jsSetValue('itemNumber', '' );
        $this->jsSetFocus('btnClose');
        $this->jsDisabled('exemplaryStatusId');
        $this->jsDisabled('libraryUnitId');

        if ( $ok )
        {
        	$items  = $this->busOperationChangeStatus->getItems();
        	GRepetitiveField::update( $items, 'tableChangeStatus');
        }
        else
        {
        	$table  = $this->busOperationChangeStatus->getMessagesTableRaw();
            $this->injectContent($table, "dojo.byId('itemNumber').focus();", TRUE);
        }
    }


    /**
     * Enter description here...
     *
     * @param unknown_type $args
     */
    public function removeItemNumberChangeStatus($args)
    {
        $items = $this->busOperationChangeStatus->getItems();
        if (is_array($items))
        {
            foreach ($items as $line => $info)
            {
                if ( $args->arrayItemTemp == $info->arrayItem)
                {
                	$this->busOperationChangeStatus->deleteItemNumber($info->itemNumber);
                }
            }
        }
        $newItems = $this->busOperationChangeStatus->getItems();
        GRepetitiveField::setData($newItems,'tableChangeStatus');
        $this->setResponse(   GRepetitiveField::generate(false, 'tableChangeStatus') , 'divtableChangeStatus');
    }
}
?>
