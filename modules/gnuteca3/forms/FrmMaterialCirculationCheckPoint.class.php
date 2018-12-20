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
 *
 * @since
 * Class created on 12/01/2009
 *
 **/
class FrmMaterialCirculationCheckPoint extends FrmMaterialCirculationChangePassword
{
    /**
    * Mount the form of checkPoint
    *
    */
    public function checkPoint( $args = NULL )
    {
        $MIOLO  = MIOLO::getInstance();
        $module = MIOLO::getCurrentModule();
        $this->setMMType('checkPoint');
        $this->changeTab('checkPoint');
        $labelWidth = '120px';

        $fields[]  = new MDiv(null, $lbl = new MLabel( _M('CheckPoint', $module), 'blue', true ));
        $lbl->addStyle('font-size','20px');
        $fields[]  = $itemNumberCheckPoint = new MTextField('itemNumberCheckPoint','',  _M('Código do Exemplar', $this->module) );
        $itemNumberCheckPoint->addAttribute('onPressEnter', GUtil::getAjax('check'));

        $fields[] = new MDiv( '', new MButton( 'btnCheck', _M('Conferir','gnuteca3'), "javascript:" . GUtil::getAjax('check'), $this->imageAccept ));
        $fields[] = new MDiv('checkResponse' );

        $this->setFocus('itemNumberCheckPoint');
        return $this->addResponse(  GUtil::alinhaForm($fields), $args );
    }

    public function check( $args )
    {
		if ($args->itemNumberCheckPoint)
		{
	        $hasLoan = $this->busLoan->getLoanOpen($args->itemNumberCheckPoint);
	        $hasLoan = $hasLoan ? true : false; //converta pra boolean

	        if ( $hasLoan )
	        {
	            $fields[] = new MLabel( $args->itemNumberCheckPoint . ' - '.  _M('Material emprestado.'), 'green', true);
	            $this->setResponse( $fields, 'checkResponse');
	            $this->jsSetValue('itemNumberCheckPoint', '');
	        }
	        else
	        {
	            $this->jsSetReadOnly('itemNumberCheckPoint', true);
                GForm::jsSetFocus('itemNumberCheckPoint');
                $this->jsSetValue('itemNumberCheckPoint', '');

                $this->error( _M('O exemplar @1 não está emprestado.','gnuteca3', $args->itemNumberCheckPoint) , GUtil::getCloseAction(true) . " itemNumber = dojo.byId('itemNumberCheckPoint'); itemNumber.className = 'mTextField'; itemNumber.value = '' ; itemNumber.readOnly = null;" ); //no clique do fechar deve habilitar novamente o campo de checagem.
	            $this->setResponse('', 'checkResponse'); //limpa a div de resposta
	        }
		}
		else
		{
			$this->setResponse('','limbo');
		}
    }
}
?>