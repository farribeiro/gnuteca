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
 * \b Maintainers: \n
 * Eduardo Bonfandini [eduardo@solis.coop.br]
 * Jamiel Spezia [jamiel@solis.coop.br]
 * Jader Osvino Fiegenbaum [jader@solis.coop.br]
 * Guilherme Soldateli [guilherme@solis.coop.br]
 *
 * @since
 * Class created on 06/11/2008
 *
 **/
$MIOLO = MIOLO::getInstance();
//$autoload->setFile('GDate',$MIOLO->getModulePath('basic', 'classes/GDate.class.php'));
$MIOLO->getClass( 'gnuteca3', 'GBusiness');
$MIOLO->getClass( 'gnuteca3', 'GString');
$MIOLO->getClass( 'gnuteca3', 'GOperator');
$MIOLO->getClass( 'gnuteca3', 'GForm');
$MIOLO->getClass( 'gnuteca3', 'controls/GContainer');
$MIOLO->getClass( 'gnuteca3', 'controls/GPrompt');
$MIOLO->getClass( 'gnuteca3', 'controls/GRadioButtonGroup');
$MIOLO->getClass( 'gnuteca3', 'controls/GGridActionIcon');
$MIOLO->getClass( 'gnuteca3', 'controls/GGrid');
$MIOLO->getClass( 'gnuteca3', 'controls/GAddChildGrid');
$MIOLO->getClass( 'gnuteca3', 'controls/GSearchGrid');
$MIOLO->getClass( 'gnuteca3', 'GMessages');
$MIOLO->getClass( 'gnuteca3', 'GMail');
$MIOLO->getClass( 'gnuteca3', 'GSendMail');
$MIOLO->getClass( 'gnuteca3', 'GOperation');
$MIOLO->getClass( 'gnuteca3', 'GUtil');
$MIOLO->getClass( 'gnuteca3', 'GFunction');
$MIOLO->getClass( 'gnuteca3', 'GPerms');
$MIOLO->getClass( 'gnuteca3', 'controls/GSelection');
$MIOLO->getClass( 'gnuteca3', 'GValidators');
$MIOLO->getClass( 'gnuteca3', 'controls/GUserMenu');
$MIOLO->getClass( 'gnuteca3', 'controls/GStatusBar');
$MIOLO->getClass( 'gnuteca3', 'controls/GWidget');
$MIOLO->getClass( 'gnuteca3', 'controls/GSubForm');
$MIOLO->getClass( 'gnuteca3', 'GDate');
$MIOLO->getClass( 'gnuteca3', 'controls/GToolBar');
$MIOLO->getClass( 'gnuteca3', 'controls/GMainMenu');
$MIOLO->getClass( 'gnuteca3', 'controls/GTabControl');
$MIOLO->getClass( 'gnuteca3', 'controls/GRealLinkButton');
$MIOLO->getClass( 'gnuteca3', 'controls/GRepetitiveField');
$MIOLO->getClass( 'gnuteca3', 'controls/GLookupField');
$MIOLO->getClass('gnuteca3', 'controls/GPersonLookup');
$MIOLO->uses('classes/controls/GEditor.class.php', 'gnuteca3');
$MIOLO->uses( "/db/BusFile.class.php", 'gnuteca3');
$MIOLO->uses( "/db/BusDomain.class.php", 'gnuteca3');

?>