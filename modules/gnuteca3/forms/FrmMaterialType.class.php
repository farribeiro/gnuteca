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
 * @author Moises Heberle [moises@solis.coop.br]
 *
 * @version $Id$
 *
 * \b Maintainers \n
 * Eduardo Bonfandini [eduardo@solis.coop.br]
 * Jamiel Spezia [jamiel@solis.coop.br]
 * Luiz Gregory Filho [luiz@solis.coop.br]
 * Moises Heberle [moises@solis.coop.br]
 *
 * @since
 * Class created on 19/01/2009
 *
 **/
class FrmMaterialType extends GForm
{
    public function __construct()
    {
        $this->setAllFunctions('MaterialType', 'description', 'materialTypeId', array('description', 'isRestricted', 'level'));
        parent::__construct();
    }

    public function mainFields()
    {
        if ( $this->function == 'update' )
        {
            $fields[] = new MTextField('materialTypeId', null, _M('Código', $this->module), FIELD_ID_SIZE,'',null, true);
            $validators[] = new MRequiredValidator('materialTypeId');
        }

        $fields[] = new MTextField('description', null, _M('Descrição', $this->module), FIELD_DESCRIPTION_SIZE);
        $fields[] = new MMultiLIneField ('observation', NULL, _M('Observação', $this->module), NULL, FIELD_MULTILINE_ROWS_SIZE, FIELD_MULTILINE_COLS_SIZE);
        $fields[] = new GRadioButtonGroup('isRestricted', _M('É restrita', $this->module) , GUtil::listYesNo(1), DB_FALSE);
        $fields[] = new MTextField('level', null, _M('Nível', $this->module), FIELD_ID_SIZE);

        $this->setFields($fields);
        
        $validators[] = new MRequiredValidator('description');
        $validators[] = new MIntegerValidator('level');

        $this->setValidators($validators);
    }
}
?>