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
 *  Teste unitário
 *
 * @author Eduardo Bonfandini [eduardo@solis.coop.br]
 *
 * @version $id$
 *
 * \b Maintainers: \n
 * Eduardo Bonfandini [eduardo@solis.coop.br]
 * Jader Osvino Fiegenbaum [jader@solis.coop.br]
 *
 * @since
 * Creation date 03/11/2011
 *
 **/
include_once '../classes/GBusinessUnitTest.class.php';
class TestMarcTagListing extends GBusinessUnitTest
{
    public function setUp()
    {
        parent::setUp('MarcTagListing');
        
        $data = new stdClass();
        $data->marcTagListingId = $data->marcTagListingIdS = '666';
        $data->description_ = $data->description_S = 'Sjon';
        $data->option = $data->optionS = '';
        $data->description = $data->descriptionS = '';
        $data->isModified = $data->isModifiedS = 't';
        $data->functionMode = $data->functionModeS = 'manage';
        $data->MarcTagListingOptions = $data->MarcTagListingOptionsS = array (  0 =>   stdClass::__set_state(array(     'module' => 'gnuteca3',     'action' => 'main:configuration:marcTagListing',     '__mainForm__EVENTTARGETVALUE' => 'forceAddToTable',     'function' => 'insert',     'marcTagListingId' => '666',     'description_' => 'Sjon',     'option' => '1',     'description' => 'Des',     'GRepetitiveField' => 'MarcTagListingOptions',     'arrayItemTemp' => NULL,     'keyCode' => '18',     'isModified' => 't',     'functionMode' => 'manage',     'frm4eb289a2552b5_action' => 'http://gnutecatrunk.guilherme/index.php?module=gnuteca3&action=main:configuration:marcTagListing&__mainForm__EVENTTARGETVALUE=tbBtnNew:click&function=insert',     '__mainForm__VIEWSTATE' => '',     '__mainForm__ISPOSTBACK' => 'yes',     '__mainForm__EVENTARGUMENT' => '',     '__FORMSUBMIT' => '__mainForm',     '__ISAJAXCALL' => 'yes',     '__THEMELAYOUT' => 'dynamic',     '__MIOLOTOKENID' => '',     '__ISFILEUPLOAD' => 'no',     '__ISAJAXEVENT' => 'yes',     'cpaint_response_type' => 'json',     'insertData' => true,     'arrayItem' => 0,  )),);

        $this->business->setData($data);
    }
}
?>