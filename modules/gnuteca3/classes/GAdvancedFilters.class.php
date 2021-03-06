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
 * Filtros avançados para a pesquisa
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
 * Sandro Roberto Weisheimer [sandrow@solis.coop.br]
 *
 * @since
 * Class created on 28/07/2009
 *
 * TODO esse arquivo deveria ser uma classe (orientação a objetos)
 *
 **/
function AFMaterialStatus( $args )
{
    $MIOLO = MIOLO::getInstance();
    $fields[0] = new MLabel( _M('Estado do exemplar', 'gnuteca3') );
    $operator = !GOperator::isLogged();
    $status = false;

    // LISTA DE EXEMPLARES A IGNORAR NA PESQUISA
    if($operator && SIMPLE_SEARCH_EXCLUDE_EXEMPLARY_STATUS != 'SIMPLE_SEARCH_EXCLUDE_EXEMPLARY_STATUS' && strlen(SIMPLE_SEARCH_EXCLUDE_EXEMPLARY_STATUS))
    {
        $status = explode(",", SIMPLE_SEARCH_EXCLUDE_EXEMPLARY_STATUS);
    }

    $busExemplaryStatus = $MIOLO->getBusiness('gnuteca3', 'BusExemplaryStatus' );
    $options = $busExemplaryStatus->listExemplaryStatus(false, false, true, false, $status, "NOT IN");

    $fields[1] = new GSelection('exemplaryStatusId', $args->exemplaryStatusId, null, $options, null, null, null, true);

    if ( isset( $_REQUEST['exemplaryStatusId']) )
    {
    	unset($fields);
    }

    return $fields;
}


function AFEditionYear($args)
{
    $fields[0] = new MLabel( _M('Período do ano de edição de', 'gnuteca3') );
    $fields[1] = new MTextField('editionYearFrom', $args->editionYearFrom );
    $fields[2] = new MSpan( '', _M('até', 'gnuteca3') );
    $fields[3] = new MTextField('editionYearTo', $args->editionYearTo );

    if ( isset( $_REQUEST['editionYearFrom'] ) && (GUtil::getAjaxFunction() != 'changeFormContent') )
    {
        unset($fields);
    }

    return $fields;
}


function AFOrder($args)
{
    $MIOLO = MIOLO::getInstance();
    $busSearchableField = $MIOLO->getBusiness('gnuteca3','BusSearchableField');
	$fields[0] = new MLabel( _M('Ordem', 'gnuteca3') );
    $fields[1] = new GSelection('orderField', $args->orderField, null, $busSearchableField->listSearchableField(false), null, null, null, true );

    $opts[SORT_ASC]     = _M('Ascendente',     'gnuteca3');
    $opts[SORT_DESC]    = _M('Descendente',    'gnuteca3');

    $fields[2] = new GSelection('orderType', $args->orderType, null, $opts ,null, null, null, true );

    if ( isset( $_REQUEST['orderField']) && (GUtil::getAjaxFunction() != 'changeFormContent') )
    {
        unset($fields);
    }

    return $fields;
}

function AFLetter($args)
{
    $letters        = 'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,#';
    $letters        = explode(',', $letters);

    $selectedLetter = $args->letter;

    foreach ( $letters as $line => $letter )
    {
        $buttons[$letter] = new MButton($letter, strtoupper($letter), "gnutecaSearch.changeLetter('$letter');");
        //$buttons[$letter]->addAttribute('class','btnLetter');
        $buttons[$letter]->setClass('m-button btnLetter');

        if ( $selectedLetter == $letter)
        {
            $buttons[$letter]->addStyle('color','blue');
            $buttons[$letter]->addStyle('font-weight','bold');
        }
    }

    $buttons[] = new MHiddenField('letter');
    $buttons[] = new MHiddenField('letterField', MARC_TITLE_TAG );
    $fields[] = new MDiv('letters', $buttons);
        
    if ( isset( $_REQUEST['letterField']) && (GUtil::getAjaxFunction() != 'changeFormContent') )
    {
        unset($fields);
    }
    
    return $fields;
}

/**
 * Monta filtro avançado de aquisição
 */
function AFAquisition($args)
{
    $MIOLO = MIOLO::getInstance();

    //escolhe os dados para montar os campos, normalmente quando ver do Args é porque foi salvo pelo operador
    $aquisitionFrom = $args->aquisitionFrom ? $args->aquisitionFrom : GDate::now()->addDay(-15);
    $aquisitioTo = $args->aquisitionTo ? $args->aquisitionTo : GDate::now();

    $fields[0] = new MLabel( _M('Período de aquisição de', 'gnuteca3') );
    $fields[1] = new MCalendarField('aquisitionFrom', $aquisitionFrom);
    $fields[2] = new MSpan('', _M('até', 'gnuteca3') );
    $fields[3] = new MCalendarField('aquisitionTo', $aquisitioTo );

    //TODO documentar o que faz essa condição
    if ( isset( $_REQUEST['aquisitionFrom'] ) && (GUtil::getAjaxFunction() != 'changeFormContent') )
    {
        unset($fields);
    }

    //monta os calendários de forma correta
    $MIOLO->page->onload('dojo.parser.parse();');

    return $fields;
}

function getFilterList()
{
	$advancedFilters['AFMaterialStatus'] = _M('Estado do Exemplar', 'gnuteca3' );
    $advancedFilters['AFEditionYear']    = _M('Período do ano de edição', 'gnuteca3' );
    $advancedFilters['AFAquisition']     = _M('Período de aquisição', 'gnuteca3' );
    $advancedFilters['AFOrder']          = _M('Ordem', 'gnuteca3' );
    $advancedFilters['AFLetter']         = _M('Pesquisa por Letras', 'gnuteca3' );

    return $advancedFilters;
}
?>