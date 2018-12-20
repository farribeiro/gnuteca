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
 * @author Luiz Gilberto Gregory F [luiz@solis.coop.br]
 *
 * @version $Id$
 *
 * \b Maintainers \n
 * Eduardo Bonfandini [eduardo@solis.coop.br]
 * Jamiel Spezia [jamiel@solis.coop.br]
 *
 * @since
 * Class created on 18/11/2008
 *
 **/
class GrdChangeMaterial extends GSearchGrid
{
    public $MIOLO;
    public $module;
    protected $busSearchFormat;
    protected $realData; //dados reais armazenados pois a grid zoa os dados passados

    public function __construct($data)
    {
        $this->MIOLO  = MIOLO::getInstance();
        $this->module = MIOLO::getCurrentModule();
        $this->busSearchFormat = $this->MIOLO->getBusiness($this->module, 'BusSearchFormat');
        
        $columns = array
        (
            new MGridColumn(_M('Número de controle',    $this->module), MGrid::ALIGN_LEFT,    null, null, true, null, true),
            new MGridColumn(_M('Informações',      $this->module), MGrid::ALIGN_LEFT,     null, null, true, null, true),
        );

        parent::__construct($data, $columns );

        $hrefUpdate = $this->MIOLO->getActionURL($this->module, 'main:catalogue:material', null, array ('function' => 'update', 'controlNumber' => '%0%' ) );
        $this->addActionUpdate( $hrefUpdate );

        $this->addActionDelete( GUtil::getAjax('tbBtnDelete_click', array ( 'function' => 'delete', 'controlNumber'     => '%0%') ) );

        $args = array ('function'=> 'duplicate', 'controlNumber'=> '%0%');

        if ( GPerms::checkAccess($this->transaction, 'insert', false ) )
        {
            $this->addActionIcon(_M('Duplicar material', $this->module), GUtil::getImageTheme('duplicateMaterial-16x16.png'), $this->MIOLO->getActionURL('gnuteca3', 'main:catalogue:material', null, $args) );
        }

        $this->setIsScrollable();
        $this->setRowMethod($this, 'checkValues');
    }
    
    public function setData($data)
    {
        $this->realData = $data;
        parent::setData( $data );
    }
    
    public function checkValues($i, $row, $actions, $columns)
    {
        $myData = $this->realData[$i];
        $tempData = $this->busSearchFormat->formatSearchData( ADMINISTRATION_SEARCH_FORMAT_ID , $myData );
        $columns[1]->control[$i]->setValue($tempData);
    }
}
?>