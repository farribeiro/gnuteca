<?php

/**
 * <--- Copyright 2005-2011 de Solis - Cooperativa de Soluções Livres Ltda. e
 * Univates - Centro Universitário.
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
 * \b Maintainers: \n
 * Eduardo Bonfandini [eduardo@solis.coop.br]
 * Jamiel Spezia [jamiel@solis.coop.br]
 * 
 * @since
 * Class created on 06/01/2011
 *
 **/

$MIOLO = MIOLO::getInstance();
$db = new BDatabase('gnuteca3');

global $messagesG;
$messagesG = array();

function addMessage( $message )
{
    global $messagesG;
    $messagesG[][] = $message;
}

$gtcRootGroupId = 1000;
$rights['Acesso'] = 1;
$rights['Inserção'] = 2;
$rights['Remoção'] = 4;
$rights['Atualização'] = 8;


// Permissões
addMessage('Removendo acessos gtcRoot');
$db->query( "DELETE FROM miolo_access WHERE idgroup = $gtcRootGroupId;" );

foreach ( $rights as $perm => $right )
{
    addMessage( "Inserindo acessos para gtcRoot - ".$perm);
    $db->query( "INSERT INTO miolo_access ( idtransaction, idgroup ,rights ) ( SELECT idtransaction,$gtcRootGroupId, $right FROM miolo_transaction );" );
}

/**
  Direito de empréstimo momentâneo
  O código abaixo realiza a insersão dos direitos de empréstimo momentâneo. A inserção deve ser executada somente uma vez, devido a isso não é possível ter um XML para isso.
  */

// Obtém o código do tipo de empréstimo momentâneo
$idOperationMomentary = $db->query("SELECT value FROM basConfig WHERE parameter = 'ID_OPERATION_LOAN_MOMENTARY';");
$idOperationMomentary = $idOperationMomentary[0][0];

// Obtém o código do tipo de empréstimo padrão
$idOperationLoan = $db->query("SELECT value FROM basConfig WHERE parameter = 'ID_LOANTYPE_DEFAULT';");
$idOperationLoan = $idOperationLoan[0][0];

// Obtém a quantidade de direitos de empréstimo momentâneo
$countRight = $db->query($sql = "SELECT count(*) FROM gtcRight WHERE operationid = $idOperationMomentary;");
$countRight = $countRight[0][0];

// Caso já tiver algum direito de empréstimo momentâneo, não insere os direitos
if ( $countRight == 0 )
{
    addMessage( "Adicionando direito de empréstimo momentâneo");
    $db->query("INSERT INTO gtcright (SELECT privilegegroupid, linkid, materialgenderid, $idOperationMomentary FROM gtcright where operationid = $idOperationLoan);");
}

// TODO: Adicionar todos os direitos caso não houver nenhum
// TODO: arrumar sequências

$fields[] = new MTableRaw( 'Script de sincronização', $messagesG, array(_M('Message','gnuteca3')), 'message');

$fields[] = new MSeparator('<br/>');
$theme->appendContent( $fields );

?>
