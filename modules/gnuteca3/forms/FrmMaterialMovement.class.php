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
 * Sandro R. Weisheimer [sandrow@solis.coop.br]
 *
 * @since
 * Class created on 06/08/2008
 *
 **/
//adiciona suporte a adião do código da unidade ao código do exemplar
if ( defined('EXEMPLAR_PLUS_UNIT') && EXEMPLAR_PLUS_UNIT == DB_TRUE && $_REQUEST['action'] == 'main:materialMovement' )
{
    //campo de inserção padrão
    if ( $_REQUEST['itemNumber'] && $_REQUEST['option'] !=  '[F5] Obra') //caso especial da reserva na catalogação
    {
        $_REQUEST['itemNumber'] = GOperator::getLibraryUnitLogged() . $_REQUEST['itemNumber'];
    }

    //checkpoint
    if ( $_REQUEST['itemNumberCheckPoint'] )
    {
        $_REQUEST['itemNumberCheckPoint'] = GOperator::getLibraryUnitLogged() . $_REQUEST['itemNumberCheckPoint'];
    }
}

class FrmMaterialMovement extends FrmMaterialCirculationCheckPoint
{
    public $perms;

    public function __construct()
    {
        parent::__construct( _M('Circulação de material','gnuteca3'));
    }

    /**
     * Make the base form fields
     *
     */
    public function mainFields( $args , $setFields = true )
    {
    	//se tiver evento que dizer que nao é a primeira vez, então não faz nada
    	if ( $this->getEvent() )
    	{
    		return null;
    	}

        $type       = $this->getMMType();
        $fields[1]  = new MDiv('divRight', $this->loadForm( $args ) );
        $fields[2]  = new MDiv('limbo');
        $mainDiv    = new MDiv('divMain', $fields);

        if ( $setFields )
        {
            $this->forceFormContent = true;
            $this->setFields( $fields );
        }

        $this->keyDownHandler(27, 113, 114, 115, 116, 117, 118,119,120,121,122,123);
    }

    public function getToolBar()
    {
        $MIOLO  = MIOLO::getInstance();
		$module = MIOLO::getCurrentModule();
		$action = MIOLO::getCurrentAction();

        $this->imageMaterialMoviment= GUtil::getImageTheme('materialMovement-32x32.png');
        $this->imageReserve         = GUtil::getImageTheme('toolbar-reserve.png');
        $this->imageVerifyMaterial  = GUtil::getImageTheme('search-32x32.png');
        $this->imageVerifyUser      = GUtil::getImageTheme('toolbar-person.png');
        $this->imageUserHistory     = GUtil::getImageTheme('toolbar-bond.png');
        $this->imageChangeStatus    = GUtil::getImageTheme('toolbar-changeStatus.png');
        $this->imageVerifyProof     = GUtil::getImageTheme('report-32x32.png');
        $this->imageChangePassword  = GUtil::getImageTheme('toolbar-changePassword.png');
        $this->imageAccept          = GUtil::getImageTheme('toolbar-checkpoint.png');

		$this->_toolBar = new GToolBar('toolBar', $MIOLO->getActionURL($module, $action));

        $this->_toolBar->removeButtons(array( MToolBar::BUTTON_NEW, MToolBar::BUTTON_SAVE, MToolBar::BUTTON_DELETE, MToolBar::BUTTON_EXIT, MToolBar::BUTTON_RESET, MToolBar::BUTTON_SEARCH, MToolBar::BUTTON_PRINT) );

        if ( $this->checkAcces('gtcMaterialMovementLoan') || $this->checkAcces('gtcMaterialMovementReturn') )
        {
            $this->_toolBar->addButton('btnAction118', null,  ':onkeydown118', '[F7] '. _M('Emprestar / Devolver', $module), true, $this->imageMaterialMoviment, $this->imageMaterialMoviment);
        }

        if ( $this->checkAcces('gtcMaterialMovementRequestReserve') || $this->checkAcces('gtcMaterialMovementAnswerReserve'))
        {
            $this->_toolBar->addButton('btnAction119', null ,':onkeydown119', '[F8] '. _M('Reservar material',  $module), true, $this->imageReserve);
        }

        if ( $this->checkAcces('gtcMaterialMovementVerifyMaterial'))
        {
            $this->_toolBar->addButton('btnAction120',null ,':onkeydown120',  '[F9] ' ._M('Verificar material',   $module) , true, $this->imageVerifyMaterial);
        }

        if ( $this->checkAcces('gtcMaterialMovementVerifyUser'))
        {
            $this->_toolBar->addButton('btnAction121', null  ,':onkeydown121', '[F10]'._M('Verificar usuário',      $module), true, $this->imageVerifyUser);
        }

        if ( $this->checkAcces('gtcMaterialMovementUserHistory') )
        {
            $this->_toolBar->addButton('btnAction122', null  ,':onkeydown122', '[F11] '._M('Histórico do usuário',      $module), true, $this->imageUserHistory);
        }

        if ( ($this->checkAcces('gtcMaterialMovementChangeStatus')) || ( $this->checkAcces('gtcMaterialMovementExemplaryFutureStatusDefined')) )
        {
            $this->_toolBar->addButton('btnAction123',null ,':onkeydown123', '[F12] '._M('Alterar estado',      $module) , true, $this->imageChangeStatus);
        }

        if ( $this->checkAcces('gtcMaterialMovementVerifyProof'))
        {
            //FIXME fazer funcionar
            //$this->_toolBar->addButton('verifyProof',null  ,':verifyProof',  _M('Verify proof',      $module), true, $this->imageVerifyProof);
        }

        if ( $this->checkAcces('gtcMaterialMovementChangePassword'))
        {
            $this->_toolBar->addButton('changePassword', null ,':changePassword', _M('Alterar senha',      $module) , true, $this->imageChangePassword);
        }

        if ( $this->checkAcces('gtcMaterialMovementCheckPoint') )
        {
            $this->_toolBar->addButton('checkPoint', null ,':checkPoint', _M('CheckPoint',      $module) , true, $this->imageAccept);
        }

        return $this->_toolBar;
    }

    //funcão chamada ao fechar a mWindow de verifyUser, chama a função da aba anterior
    function verifyUserOnClose( $args )
    {
        $this->mainFields( null, false);
        $this->setResponse('','limbo');
    }


    /**
     * Open VerifyUser window (MaterialMovement related)
     *
     * @param unknown_type $args
     */
    public function openVerifyUserWindow($args)
    {
        $personId = ($args->personId) ? $args->personId : $_SESSION['personId'];
        $urlWindow  = $this->manager->getActionURL($this->module, 'main:verifyUser', '', array('myEvent' => $args->event, 'personId' => $personId));
        $urlWindow  = str_replace('&amp;', '&', $urlWindow);

        $win = new MWindow( 'winVerifyUser' , array('url'=>$urlWindow,'title'=> _M( 'Verificação de usuário' , 'gnuteca3' ) ) );
        $this->page->onload("miolo.getWindow('winVerifyUser').open();");
        $this->setResponse('', 'limbo');
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
