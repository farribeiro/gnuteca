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
 * Grid
 *
 * @author Jader Osvino Fiegenbaum [jader@solis.coop.br]
 *
 * @version $Id$
 *
 * \b Maintainers \n
 * Jader Osvino Fiegenbaum [jader@solis.coop.br]
 *
 * @since
 * Class created on 29/12/2010
 *
 **/
class GrdZ3950Servers extends GSearchGrid
{
    public $MIOLO;
    public $module;

    public function __construct($data)
    {
        $this->MIOLO  = MIOLO::getInstance();
        $this->module = MIOLO::getCurrentModule();

        $columns = array(
            new MGridColumn(_M('Código', $this->module), MGrid::ALIGN_RIGHT, null, null, true, null, true),
            new MGridColumn(_M('Descrição', $this->module), MGrid::ALIGN_LEFT,  null, null, true, null, true),
            new MGridColumn(_M('Endereço', $this->module), MGrid::ALIGN_LEFT,  null, null, true, null, true),
            new MGridColumn(_M('Tipo', $this->module), MGrid::ALIGN_LEFT,  null, null, true, null, true),
            new MGridColumn(_M('Sintaxe', $this->module), MGrid::ALIGN_LEFT,  null, null, true, null, true),
            new MGridColumn(_M('Usuário', $this->module), MGrid::ALIGN_LEFT,  null, null, true, null, true),
            new MGridColumn(_M('Senha', $this->module), MGrid::ALIGN_LEFT,  null, null, true, null, true),
            new MGridColumn(_M('País', $this->module), MGrid::ALIGN_LEFT,  null, null, true, null, true)
        );

        parent::__construct($data, $columns);

        $hrefUpdate = $this->MIOLO->getActionURL($this->module, MIOLO::getCurrentAction(), null, array( 'function' => 'update', 'serverId' => '%0%' ) );

        $this->setIsScrollable();
        $this->addActionUpdate( $hrefUpdate );
        $this->addActionDelete( GUtil::getAjax('tbBtnDelete_click', array( 'function' => 'delete', 'serverId' => '%0%' )) );
    }
}
?>
