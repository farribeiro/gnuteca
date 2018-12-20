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
 * Class GmainMenu
 *
 * @author Eduardo Bonfandini [eduardo@solis.coop.br]
 * @author Moises Heberle [moises@solis.coop.br]
 *
 * @version $Id$
 *
 * \b Maintainers: \n
 * Eduardo Bonfandini [eduardo@solis.coop.br]
 * Jamiel Spezia [jamiel@solis.coop.br]
 * Moises Heberle [moises@solis.coop.br]
 * Jader Osvino Fiegenbaum [jader@solis.coop.br]
 *
 *
 * @since
 * Class created on 06/10/2010
 *
 **/
class GMainMenu extends MOptionList
{
    private $menuOptions;
    private $template;
    private $action;
    private $target;
    private $items;
    private $jsItems;
    private $jsMenu;
    public  $isSubMenu;
    static $linearItems = array();
    public $fatherName;
    public $fatherImage;

    /**
     * Constroí um menu
     * //TODO separar em duas classes GMenu e GMainMenu
     *
     * @param string $name id/nome do menu
     * @param string $title título de menu
     * @param string $image url da imagem
     */
    public function __construct( $name='', $title =null, $image = null )
    {
        $MIOLO = MIOLO::getInstance();
        parent::__construct($name);

        $this->items        = NULL;
        $this->template     = $template;
        $this->action       = $action;
        $this->target       = '_blank';
        $this->isSubMenu    = false;
        $this->menuOptions  = array();

        $this->setTitle($title, $image);
    }

    /**
     * Define o título de menu
     *
     * //TODO separar em funções uma para definir o título, uma para imagem e outra para o link
     *
     * @param string $title título do menu
     * @param string $image1 imagem do menu
     * @param string $image2 imagem do menu TODO verificar onde é usada
     * @param string $module módulo do link
     * @param string $action ação do link
     * @param string $item item do link
     * @param array $args argumentos do link
     */
    public function setTitle($title, $image1=null, $image2=null, $module=null, $action=null, $item=null, $args=null) 
    {
        if ( sizeof($this->menuOptions) )
        {
            $this->menuOptions[0][1] = $title;
            $this->menuOptions[0][3] = 'root';
            $this->menuOptions[0][4] = $image1;
        }
        else
        {
            if ( $module && $action )
            {
                $control = new MLink(NULL,$label);
                $control->setAction($module,$action,$item,$args);
                $link = $control->href;
            }

            $this->menuOptions[] = array('0',$title,'','root', $image1, $image2, $link);
        }
    }

    /**
     * Adiciona um item/opção ao menu.
     * Internamente alimenta o array linear
     *
     * @param string $label rótulo/título do item
     * @param string $module módulo do link
     * @param string $action ação do link
     * @param string $item item do link
     * @param string $args argumentos do link
     * @param string $normalImage url da imagem
     */
    public function addOption($label, $module = 'common', $action = 'main', $item = null, $args = null, $normalImage = '')
    {
        $MIOLO = MIOLO::getInstance();
        
        if ( stripos( $action, 'javascript:') === 0 )
        {
            $href = $action;
        }
        else
        {
            $href = $MIOLO->getActionURL( $module, $action, $item, $args );
        }

        $this->menuOptions[] = array($href, $label, $normalImage);

        //TODO não necesitar mais dessas pogs abaixo
        //caso de 3 níveis que não pega o certo
        if ( stripos($action , 'main:configuration') === 0 )
        {
            $this->fatherName = _M('Configuração', $module);
            $this->fatherImage = 'config-16x16.png';
        }

        //caso de 3 níveis que não pega o certo
        if ( stripos($action , 'main:administration') === 0 )
        {
            if ( stripos($action , 'adminReport') > 0 )
            {
                $this->fatherName = _M('Relatório', $module);
                $this->fatherImage = 'report-16x16.png';
            }
            else
            {
                $this->fatherName = _M('Administração', $module);
                $this->fatherImage = 'administration-16x16.png';
            }
        }

        //caso de 3 níveis que não pega o certo
        if ( stripos($action , 'main:catalogue') === 0 && $this->menuOptions[0][1] != _M( 'Catalogação','gnuteca3') )
        {
            $this->fatherName = _M('Catalogação', $module);
            $this->fatherImage = 'catalogue-16x16.png';
        }

        //a label é transformada em um array, para levar o histórico completo do caminho
        $fullLabel[] = $this->fatherName;
        $fullLabel[] = $this->menuOptions[0][1];
        $fullLabel[] = $label;

        $fullImage[] = $this->fatherImage;
        $fullImage[] = $this->menuOptions[0][4];
        $fullImage[] = $normalImage;

        $this->addToLinearArray($action, $fullLabel, $fullImage);
    }

    /**
     * Adiciona item do menu para o array linear, que é utilizado para montar a navbar
     *
     * @param string $action ação/link
     * @param string $label rótulo/título
     * @param string $image url imagem
     */
    public function addToLinearArray($action, $label, $image)
    {
        $menuItem = new stdClass();

        $menuItem->label = $label;
        $menuItem->image = $image;

        GMainMenu::$linearItems[$action] = $menuItem;
    }

    /**
     * Adiciona um item/opção, verificação a permissão do usuário
     *
     * @param string $transaction a transação da permissão
     * @param string $access tipo de acesso a verificar
     * @param string $label rótulo/título
     * @param string $module módulo do link
     * @param string $action ação do link
     * @param string $item item do link
     * @param string $args argumentos do link
     * @param string $normalImage url da imagem
     */
    public function addUserOption( $transaction, $access, $label, $module = 'common', $action = 'main', $item = '',$args = null, $normalImage = '' )
    {
        if ( $this->manager->perms->checkAccess( $transaction, $access ) )
        {
            $this->addOption($label, $module, $action, $item, $args, $normalImage);
        }
    }

    /*public function addLink($label, $link = '#', $target = '_self', $normalImage=null)
    {
        $this->menuOptions[] = array($link, $label, "link", $target, $normalImage);
    }*/

    /**
     * Adiciona um menu caso tenha item
     * Desconsidera separadores na contagem
     *
     * @param GMainMenu $menu
     * @return boolean
     */
    public function addMenu( GMainMenu $menu )
    {
        $count = $menu->countOption();

        if ( $count > 0 )
        {
            $menu->fatherName = $this->menuOptions[0][1];
            $menu->fatheImage = $this->menuOptions[0][4];
            $this->menuOptions[] = $menu;
            return true;
        }
       
        return false;
    }

    /**
     * Conta quantos items (reais) tem o menu
     * Items reais não contam root nem separadores.
     * 
     * @return int
     */
    public function countOption()
    {
        $count = 0;

        //caso o primeiro item for um separador remove-o,
        //pois o menu javascript não suporta primeiro item como separador
        if ( is_array( $this->menuOptions[1] ) )
        {
            if ( $this->menuOptions[1][3] == 'separator' )
            {
                unset( $this->menuOptions[1] );

                //caso tenha conseguido remover o primeiro separador verifica se não tem mais um logo abaixo
                //TODO fazer for procurando mais opções (mas acho dificil ter mais que 3)
                if ( is_array( $this->menuOptions[2] ) )
                {
                    if ( $this->menuOptions[2][3] == 'separator' )
                    {
                        unset( $this->menuOptions[2] );
                    }
                }
            }
        }
  
        foreach ( $this->menuOptions as $option )
        {
            if ( is_array( $option ))
            {
                if ( $option[3] != 'root' &&  $option[3] != 'separator' )
                {
                    $count++;
                }
            }
            else if ( $option instanceof GMainMenu ) //possui submenu
            {
                if ( $option->countOption() > 0 )
                {
                    $count++;
                }
            }
        }

        return $count;
    }

    /**
     * Adiciona um separador ao menu
     */
    public function addSeparator()
    {
        $this->menuOptions[] = array('-', '', '', 'separator');
    }

    /**
     * Verifica se o menu tem itens/opções nele
     *
     * @return integer
     */
    public function hasOptions()
    {
        return ( count($this->menuOptions) > 0 );
    }

    /**
     * Obtem o html de uma imagem
     *
     * @global MTheme $theme
     * @param <type> $menu
     * @param <type> $start
     * @return string
     */
    private function getOptionImage($menu, $start)
    {
        global $theme;
        $img   = '';
        $start = (int) $start;

        if ( $menu[$start] )
        {
            if ( $menu[$start+1] )
            {
                $seq1 = 'class="seq1"';
            }

            $img = '<img '. $seq1 .' src="'. GUtil::getImageTheme($menu[$start]) .'" />';
        }

        if ( $menu[$start+1] )
        {
            $img .= '<img class="seq2" src="'. GUtil::getImageTheme($menu[$start+1]) .'" />';
        }

        if ( $img == '' )
        {
            $img = null;
        }
        else
        {
            $img = "'". $img ."'";
        }

        return $img;
    }

    /**
     * Monta o html do menu.
     *
     * É uma função recursiva que chama os menus internos
     *
     * @global string $module módulo atual
     * @global MTheme $theme tema do miolo
     * @return string javascript com o menu
     */
    private function createMenu()
    {
        global $module, $theme;
        $MIOLO = $this->manager;
        $start = $startSub = true;

        foreach ( $this->menuOptions as $menu )
        {
            if ( ! $startSub )
            {
                $compl =  ',';
            }
            else
            {
                $compl = '';
            }

            if ( is_object($menu) ) // sub-menu
            {
                $this->jsMenu .= $compl . $menu->createMenu();

                $startSub = false;
            }
            else if ( $menu[0] == '0' && $menu[3] ) //main option
            {
                if ( ! $start ) // close the existing option
                {
                    echo "],";
                }

                $img = $this->getOptionImage($menu, 4);

                $this->jsMenu .= "[".$img.", \"".$menu[1]."\", \"".$menu[6]."\", null, null,\n";

                $start    = false;
                $startSub = true;
            }
            else if ( $menu[3] == 'separator' )
            {
                $this->jsMenu .= ', _cmSplit';

            }
            else if ( $menu[2] == 'link' )
            {
                $img        = $this->getOptionImage($menu, 4);
                $linkURL    = "<a href=\"$menu[0]\" target=\"$menu[3]\">$menu[1]</a><br/>\n";

                $this->jsMenu .=  $compl . "    [".$img.", \"$menu[1]\", \"$menu[0]\", \"$menu[3]\", null]\n";

                $startSub = false;
            }
            else
            {
                $img = $this->getOptionImage($menu, 2);

                $this->jsMenu .=  $compl . "    [".$img.", \"$menu[1]\", \"$menu[0]\", null, null]\n";

                $startSub = false;
            }
        }

        $this->jsMenu .=  ']';

        return $this->jsMenu;
    }

    /**
     * Retorna o html do menu principal.
     * Inclui o html de todo o menu
     *
     * @return string
     */
    public function generateInner()
    {
        if ($this->isSubMenu) return;

        $this->createMenu();
        $this->inner = "";

        $code .= "function carregaMenu() { cmDraw( [ " . $this->jsMenu . "] ); } ";

        //colaca o menu na sessão para poder utilizar na montagem da barra de navegação
        $_SESSION['menuItems'] = GMainMenu::$linearItems;

        return $code;
    }

    /**
     * Cria os itens do menu do gnuteca
     *
     */
    public function createMainMenu()
    {
        //segurança para não efetuar os sqls em funções ajax
        if ( GUtil::getAjaxFunction() )
        {
            return false;
        }
        
        $MIOLO          = MIOLO::getInstance();
        $module         = 'gnuteca3';
        $adminModule    = $MIOLO->mad;

        $this->setTitle( '', 'gnuteca3-16x16.png' );
        $this->addUserOption('gtcMaterialMovement', A_ACCESS, _M('Circulação de material', $module), $module, 'main:materialMovement','','','materialMovement-16x16.png');

        //SEARCH MENU
        unset($menuItem);
        $home = 'main:search';
        $searchMenu = new GMainMenu('search',_M('Pesquisa', $this->module), 'search-16x16.png');
        //Busca pesquisas definidas pelo administrador
        $busFormContent = $MIOLO->getBusiness($module, 'BusFormContent');
        
        //segurança para base zerada
        $FORM_CONTENT_TYPE_ADMINISTRATOR = FORM_CONTENT_TYPE_ADMINISTRATOR;
        
        if ( $FORM_CONTENT_TYPE_ADMINISTRATOR == 'FORM_CONTENT_TYPE_ADMINISTRATOR' )
        {
            $FORM_CONTENT_TYPE_ADMINISTRATOR = 1;
        }
        
        $busFormContent->formContentType = $FORM_CONTENT_TYPE_ADMINISTRATOR  ;
        $search = $busFormContent->searchFormContent(TRUE);

        if ($search)
        {
            foreach ($search as $v)
            {
                //nome especifico somente usado dentro da circulação de material, então pula ele na relação
                if ( $v->name == 'materialMovement')
                {
                    continue;
                }
                //Lista todas as pesquisas criadas pelo administrador
                $menuItem[] = array($v->name, 'search-16x16.png', "{$home}:simpleSearch", '', $v->formContentId);
            }
        }

        if (GPerms::checkAccess('gtcZ3950', null, false))
        {
            $menuItem[] = array(_M('Z3950',$module), 'search-16x16.png', "$home:simpleSearch&subForm=Z3950");
        }

        if ( GB_INTEGRATION == DB_TRUE )
        {
            $menuItem[] = array(_M('Google Book',$module), 'search-16x16.png', "$home:simpleSearch&subForm=GoogleBook");
        }

        $menuItem[] = array(_M('Biblioteca nacional',$module), 'search-16x16.png', "$home:simpleSearch&subForm=FBN");

        foreach ( $menuItem as $m )
        {
            $formContentId = $m[4];

            if ( $formContentId )
            {
                $args = array( 'formContentId' => $formContentId, 'formContentTypeId' => FORM_CONTENT_TYPE_ADMINISTRATOR);
            }
            else
            {
                $args = array();
            }

            $searchMenu->addOption($m[0], $module, $m[2], null, $args, $m[1]);
        }

        $this->addMenu($searchMenu);

        //DOCUMENTOS
        $documentMenu = new GMainMenu('document', _M('Documentos', $module), 'report-16x16.png');
        $reportAdminMenu = new GMainMenu('report', _M('Relatório', $module), 'report-16x16.png');
        $busReport  = $MIOLO->getBusiness( 'gnuteca3', 'BusReport' );
        $reportGroup = BusinessGnuteca3BusDomain::listForSelect('REPORT_GROUP');
        //cria os submenus
        if ( is_array( $reportGroup ) )
        {
            foreach ( $reportGroup as $line => $group )
            {
                $reportMenus[$group[0]] = new GMainMenu( 'report'.$group[0], $group[1], 'folder-16x16.png');
            }
        }

        $printAdminMenu = new GMainMenu('printAdmin', _M('Impressão', $module), 'print-16x16.png');
        $printAdminMenu->addUserOption( 'gtcBackOfBook', A_ACCESS, _M('Lombada',$module), $module, "main:administration:backofbook", null, array("function" => "search"), 'backofbook-16x16.png' );
        $printAdminMenu->addUserOption( 'gtcBarcode', A_ACCESS, _M('Código de barras',$module), $module, "main:administration:barcode", null, array("function" => "search"), 'barcode-16x16.png' );

        //lista somente ativos
        $busReport->isActiveS = 't';
        $reportList = $busReport->searchReport(true, true);

        if ( is_array($reportList) )
        {
            foreach ( $reportList as $line => $info)
            {
                if ( $info[9] )
                {
                    if ( $info[9] == 'IMP' ) //O grupo impressão é adicionado no menu de impressões
                    {
                        $printAdminMenu->addUserOption( 'gtcAdminReport', A_ACCESS, $info[1], $module, "main:administration:adminReport&menuItem=".$info[0], null, array('reportId'=>$info[0]), 'report-16x16.png');
                    }
                    elseif ( $reportMenus[$info[9]] ) //Adiciona em um grupo
                    {
                        $reportMenus[$info[9]]->addUserOption( 'gtcAdminReport', A_ACCESS, $info[1], $module, "main:administration:adminReport&menuItem=".$info[0], null, array('reportId'=>$info[0]), 'report-16x16.png');
                    }
                    else
                    {
                        $reportAdminMenu->addUserOption( 'gtcAdminReport', A_ACCESS, $info[1], $module, "main:administration:adminReport&menuItem=".$info[0], null, array('reportId'=>$info[0]), 'report-16x16.png');
                    }
                }
                else
                {
                    $reportAdminMenu->addUserOption( 'gtcAdminReport', A_ACCESS, $info[1], $module, "main:administration:adminReport&menuItem=".$info[0], null, array('reportId'=>$info[0]), 'report-16x16.png');
                }
            }
        }

        foreach ($reportMenus as $repMenu)
        {
            $reportAdminMenu->addMenu($repMenu);
        }
        $documentMenu->addMenu($reportAdminMenu);
        $documentMenu->AddMenu($printAdminMenu);

        $this->addMenu($documentMenu);

        //ADMINISTRATION MENU
        $home = 'main:administration';
        $adminMenu = new GMainMenu('administration', _M('Administração', $module), 'administration-16x16.png');

        $adminMaterialMovementMenu = new GMainMenu('adminMaterialMovement', _M('Circulação de material', $module), 'materialMovement-16x16.png');
        $adminMaterialMovementMenu->addUserOption('gtcLoan',A_ACCESS,_M('Empréstimo',$module),$module,"$home:loan",null,null,'loan-16x16.png');
        $adminMaterialMovementMenu->addUserOption('gtcReserve',A_ACCESS,_M('Reserva',$module),$module,"$home:reserve",null,null,'reserve-16x16.png');
        $adminMaterialMovementMenu->addUserOption('gtcRenew',A_ACCESS,_M('Renovação',$module),$module,"$home:renew",null,null,'renew-16x16.png');
        $adminMaterialMovementMenu->addUserOption('gtcFine',A_ACCESS,_M('Multa',$module),$module,"$home:fine",null,null,'fine-16x16.png');
        $adminMaterialMovementMenu->addSeparator();
        $adminMaterialMovementMenu->addUserOption('gtcInterchange', A_ACCESS, _M('Permuta/Doação', $module), $module, 'main:administration:interchange',null,null,'interchange-16x16.png');
        $adminMaterialMovementMenu->addUserOption('gtcLoanbetweenLibrary', A_ACCESS, _M('Empréstimo entre bibliotecas', $module), $module, 'main:administration:loanbetweenlibrary',null,null,'loanbetweenlibrary-16x16.png');
        $adminMaterialMovementMenu->addUserOption('gtcPurchaseRequest',A_ACCESS,_M('Solicitação de compras',$module),$module,"$home:purchaseRequest",null,null,'purchaseRequest-16x16.png');
        $adminMaterialMovementMenu->addUserOption('gtcExemplaryFutureStatusDefined', A_ACCESS, _M('Estado futuro do exemplar', $module), $module, 'main:administration:exemplaryFutureStatusDefined',null,null,'exemplaryfuturestatusdefined-16x16.png');
        $adminMaterialMovementMenu->addUserOption('gtcRequestChangeExemplaryStatus', A_ACCESS, _M('Requisição de alteração de estado', $module), $module, 'main:administration:requestChangeExemplaryStatus',null,null,'requestChangeExemplaryStatus-16x16.png');
        $adminMenu->addMenu($adminMaterialMovementMenu);

        $adminPessoaMenu = new GMainMenu('adminPessoa', _M('Pessoas', $module), 'person-16x16.png');
        $adminPessoaMenu->addUserOption('gtcPerson',A_ACCESS,_M('Pessoa',$module),$module,"$home:person",null,null,'person-16x16.png');
        $adminPessoaMenu->addUserOption('gtcBond',A_ACCESS,_M('Vínculo',$module),$module,"$home:bond",null,null,'bond-16x16.png');
        $adminPessoaMenu->addUserOption('gtcPenalty',A_ACCESS,_M('Penalidade',$module),$module,"$home:penalty",null,null,'penalty-16x16.png');
        $adminPessoaMenu->addUserOption('gtcSupplier',A_ACCESS,_M('Fornecedor',$module),$module,"$home:supplier",null,null,'supplier-16x16.png');
        $adminMenu->addMenu($adminPessoaMenu);

        $procAdminMenu = new GMainMenu('proccess',_M('Tarefas', $module), 'proccess-16x16.png');
        $procAdminMenu->addUserOption('gtcSendMailReturn', A_ACCESS, _M('Devolução',$module), $module, 'main:administration:devolution', null, null, 'devolution-16x16.png' );
        $procAdminMenu->addUserOption('gtcSendMailDelayedLoan', A_ACCESS, _M('Empréstimo atrasado',$module), $module, 'main:administration:delayedLoan', null, null, 'delayedloan-16x16.png' );
        $procAdminMenu->addUserOption('gtcSendMailNotifyAcquisition', A_ACCESS, _M('Notificação de aquisições',$module), $module, 'main:administration:notifyacquisition', null, null, 'notifyacquisition-16x16.png' );
        $procAdminMenu->addUserOption('gtcSendMailAnsweredReserves', A_ACCESS, _M('Comunicação de reservas',$module), $module, 'main:administration:answeredreserves', null, null, 'answeredreserves-16x16.png' );
        $procAdminMenu->addUserOption('gtcSendMailReserveQueue', A_ACCESS, _M('Reorganização da fila de reserva',$module), $module, 'main:administration:reservequeue', null, null, 'reservequeue-16x16.png' );
        $procAdminMenu->addUserOption('gtcVerifyLinks', A_ACCESS, _M('Verificação links',$module), $module, 'main:administration:verifyLinks', null, null, 'reservequeue-16x16.png' );
        $procAdminMenu->addUserOption('gtcSendMailNotifyEndRequest', A_ACCESS, _M('Notificação de fim de requisição',$module), $module, 'main:administration:notifyEndRequest', null, null, 'answeredreserves-16x16.png' );
        $procAdminMenu->addUserOption('gtcDeleteValuesOfSpreadSheet', A_ACCESS, _M('Exclusão de valores das planilhas',$module), $module, 'main:administration:deleteValuesOfSpreadSheet', null, null, 'deleteValuesOfSpreadSheet-16x16.png' );
        $adminMenu->addMenu($procAdminMenu);

        $geralAdminMenu = new GMainMenu('geralAdmin',_M('Geral', $module), 'gnuteca3-16x16.png');
        $geralAdminMenu->addUserOption('gtcNews',A_ACCESS,_M('Notícias',$module),$module,"$home:news",null,null,'news-16x16.png');
        $geralAdminMenu->addUserOption('gtcCostCenter',A_ACCESS,_M('Centro de custo',$module),$module,"$home:costCenter",null,null,'costCenter-16x16.png');
        $geralAdminMenu->addUserOption('gtcFile',A_ACCESS,_M('Arquivo',$module),$module,"$home:file",null,null,'folder-16x16.png');
        $geralAdminMenu->addSeparator();
        $geralAdminMenu->addUserOption('gtcBackgroundTaskLog', A_ACCESS, _M('Tarefas em segundo plano', $module), $module, "main:administration:backgroundTaskLog", null, null, 'backgroundTaskLog-16x16.png');
        $geralAdminMenu->addUserOption('gtcanalytics',A_ACCESS,_M('Acesso',$module),$module,"main:administration:analytics",null,null,'access-16x16.png');
        $geralAdminMenu->addUserOption('gtcMaterialEvaluation',A_ACCESS,_M('Avaliações de material',$module),$module,"main:administration:materialEvaluation",null,null,'materialEvaluation-16x16.png');
        $geralAdminMenu->addUserOption('gtcMyLibrary',A_ACCESS,_M('Moderação da minha biblioteca',$module),$module,"main:administration:myLibrary",null,null,'myLibrary-16x16.png');
        $adminMenu->addMenu($geralAdminMenu);

        $acervoAdminMenu = new GMainMenu('acervoAdmin',_M('Acervo', $module), 'catalogue-16x16.png');
        //gtcReturnType
        $acervoAdminMenu->addUserOption( 'gtcReturnRegister', A_ACCESS, _M('Registro de tipo de devoluções', $module), $module, 'main:administration:returnregister',null,null,'returnregister-16x16.png');
        $acervoAdminMenu->addUserOption( 'gtcExemplaryStatusHistory', A_ACCESS, _M('Histórico de estados do exemplar',$module), $module, "main:administration:exemplarystatushistory", null, array("function" => "search"), 'exemplarystatushistory-16x16.png' );
        $acervoAdminMenu->addUserOption( 'gtcMaterialHistory', A_ACCESS, _M('Histórico de alteração do material',$module), $module, "main:administration:materialhistory", null, null, 'exemplarystatushistory-16x16.png' );
        $acervoAdminMenu->addUserOption( 'gtcInventoryCheck', A_ACCESS, _M('Verificação do inventário',$module), $module, "main:administration:inventoryCheck", null, null, 'inventoryCheck-16x16.png' );
        
        $adminMenu->addMenu($acervoAdminMenu);
   
        $this->addMenu( $adminMenu );

        //CATALOGUE MENU
        $home = 'main:catalogue';
        $catMenu = new GMainMenu('catalogue',_M('Catalogação', $module), 'catalogue-16x16.png');

        if ( ($this->manager->perms->checkAccess( 'gtcPreCatalogue', A_INSERT, false )) || ($this->manager->perms->checkAccess( 'gtcMaterial', A_INSERT, false )) )
        {
            $newMaterialCatMenu = new GMainMenu('newMaterial',_M('Novo material', $module), 'newMaterial-16x16.png');
            $newMaterialCatMenu->addOption( _M('Padrão', $module), $module, "$home:material", null, array('function' => 'new'), 'newMaterial-16x16.png');
            $businessSpreadsheet = $MIOLO->getBusiness('gnuteca3', 'BusSpreadsheet');
            $menus = $businessSpreadsheet->getMenus();

            if( $menus )
            {
                foreach ( $menus as $content )
                {
                    $args = array('function' => 'dinamicMenu', "leaderString" => str_replace("#", "*", $content->menuoption));
                    $newMaterialCatMenu->addOption($content->menuname, $module, "$home:material", null, $args, 'newColection-16x16.png');
                }
            }

            $catMenu->addMenu($newMaterialCatMenu);
        }
        
        if ( $this->manager->perms->checkAccess( 'gtcPreCatalogue', A_INSERT, false ) )
        {
            $catMenu->addUserOption('gtcPreCatalogue', A_ACCESS, _M('Catalogação facilitada', $module), $module, "$home:easyCatalogue", null, array('function' => 'insert'), 'easyCatalogue-16x16.png');
        }
        
        $catMenu->addUserOption('gtcMaterial', A_ACCESS, _M('Material', $module), $module, "$home:material", null, array('function' => 'search'), 'changeMaterial-16x16.png');
        $catMenu->addUserOption('gtcKardexControl', A_ACCESS, _M('Controle do Kardex', $module), $module, "$home:kardexControl", null, array('function' => 'search'), 'kardexControl-16x16.png');
        $catMenu->addUserOption('gtcPreCatalogue', A_ACCESS, _M('Pré-catalogação', $module), $module, "$home:preCatalogue", null, array('function' => 'search'), 'preCatalogue-16x16.png');

        $confCatMenu = new GMainMenu('configuration',_M('Dicionário', $module), 'config-16x16.png');
        $confCatMenu->addUserOption( 'gtcDictionary', A_ACCESS, _M('Cadastro',$module), $module, "$home:dictionary", null, null, 'dictionary-16x16.png' );
        $confCatMenu->addUserOption( 'gtcDictionaryContent', A_ACCESS, _M('Conteúdo',$module), $module, "$home:dictionarycontent", null, null, 'dictionarycontent-16x16.png' );
        $catMenu->addMenu($confCatMenu);
        //menu ISO
        $confCatMenu = new GMainMenu('import',_M('Importação', $module), 'iso2709-16x16.png');
        $confCatMenu->addUserOption('gtcISO2709Import' , A_ACCESS, _M('ISO2709', $module), $module, 'main:catalogue:iso2709:import', null, array('function' => 'insert'), 'importIso2709-16x16.png' );
        $confCatMenu->addUserOption('gtcMarc21Import' , A_ACCESS, _M('Marc21', $module), $module, 'main:catalogue:marc21import', null, array('function' => 'insert'), 'importIso2709-16x16.png' );
        $catMenu->addMenu($confCatMenu);
        $this->addMenu($catMenu);

        $home = 'main:configuration';
        $confMenu = new GMainMenu('configuration',_M('Configuração', $module), 'config-16x16.png');

        $libraryMenu = new GMainMenu( 'library',_M('Unidade de biblioteca', $module), 'libraryUnit-16x16.png' );
        $libraryMenu->addUserOption('gtcLibraryUnit', A_ACCESS, _M('Unidade', $module), $module, "$home:libraryUnit", null, null, 'libraryUnit-16x16.png');
        $libraryMenu->addUserOption('gtcHoliday', A_ACCESS, _M('Feriado', $module), $module, "$home:holiday", null, null, 'holiday-16x16.png');
        $libraryMenu->addUserOption('gtcAssociation', A_ACCESS, _M('Associação', $module), $module, "$home:libraryAssociation", null, null, 'libraryAssociation-16x16.png');
        $libraryMenu->addUserOption('gtcPrivilegeGroup', A_ACCESS, _M('Grupo de privilégio', $module), $module, "$home:privilegeGroup", null, null, 'groupRight-16x16.png');
        $libraryMenu->addUserOption('gtcLibraryGroup', A_ACCESS, _M('Grupos de unidade', $module), $module, "$home:libraryGroup", null, null, 'libraryGroup-16x16.png');
        $confMenu->addMenu($libraryMenu);
        
        $rapMenu = new GMainMenu('circulation', _M('Circulação', $module), 'policy-16x16.png');
        $rapMenu->addUserOption('gtcUserGroup', A_ACCESS, _M('Grupo de usuário', $module), $module, "$home:userGroup", null, null, 'userGroup-16x16.png');
        $rapMenu->addUserOption('gtcRight', A_ACCESS, _M('Direito', $module), $module, "$home:groupRight", null, null, 'groupRight-16x16.png');
        $rapMenu->addUserOption('gtcPolicy', A_ACCESS, _M('Política', $module), $module, "$home:policy", null, null, 'generalPolicy-16x16.png');
        $rapMenu->addUserOption('gtcGeneralPolicy', A_ACCESS, _M('Política geral', $module), $module, "$home:generalPolicy", null, null, 'privilegeGroup-16x16.png');
        $rapMenu->addSeparator();
        $rapMenu->addUserOption('gtcLocationForMaterialMovement', A_ACCESS, _M('Local', $module), $module, 'main:configuration:locationForMaterialMovement',null, null, 'locationForMaterialMovement-16x16.png');
        $rapMenu->addUserOption('gtcRulesForMaterialMovement', A_ACCESS, _M('Regra', $module), $module, 'main:configuration:rulesForMaterialMovement',null, null, 'rulesForMaterialMovement-16x16.png');
        $rapMenu->addUserOption('gtcOperation', A_ACCESS, _M('Operação', $module), $module, 'main:configuration:operation',null, null, 'operation-16x16.png');
        $rapMenu->addSeparator();
        $rapMenu->addUserOption('gtcClassificationArea', A_ACCESS, _M('Área de classificação', $module), $module, "$home:classificationArea", null, null, 'classificationArea-16x16.png');
        $rapMenu->addUserOption('gtcReturnType', A_ACCESS, _M('Tipo de devolução', $module), $module, 'main:configuration:returntype',null, null, 'returntype-16x16.png');
        $rapMenu->addUserOption('gtcExemplaryStatus', A_ACCESS, _M('Estado do exemplar', $module), $module, 'main:configuration:exemplaryStatus',null, null, 'exemplaryStatus-16x16.png');
        $rapMenu->addUserOption('gtcFineStatus', A_ACCESS, _M('Estado da multa', $module), $module, 'main:configuration:fineStatus',null, null, 'finestatus-16x16.png');
        $confMenu->addMenu($rapMenu);

        $searchMenu = new GMainMenu('search',_M('Pesquisa', $module), 'search-16x16.png');
        $searchMenu->addUserOption('gtcSearchableField', A_ACCESS, _M('Campos pesquisáveis', $module), $module, "main:configuration:searchablefield", null, null, 'searchablefield-16x16.png');
        $searchMenu->addUserOption('gtcSearchFormat', A_ACCESS, _M('Formato da pesquisa', $module), $module, "main:configuration:searchformat", null, null, 'searchformat-16x16.png');
        $searchMenu->addUserOption('gtcz3950servers', A_ACCESS, _M('Servidores Z39.50', $module), $module, "main:configuration:z3950servers", null, null, 'z3950Servers-16x16.png');
        $confMenu->addMenu($searchMenu);
        
        $prefMenu = new GMainMenu( 'libraryPreference',_M('Preferência', $module), 'libraryPreference-16x16.png' );

        $preferences = BusinessGnuteca3BusDomain::listForSelect('ABAS_PREFERENCIA', true, false);

        if ( is_array( $preferences ) )
        {
            foreach ( $preferences as $line => $preference )
            {
                $prefMenu->addUserOption('gtcLibraryPreference', A_ACCESS, $preference->label, $module, "$home:libraryPreference&menuItem=".$preference->key, null, array('function'=>'update', 'tabId' => $preference->key,'tabName' => $preference->label  ), 'libraryPreference-16x16.png');
            }
        }

        $confMenu->addMenu($prefMenu);

        $otherMenu = new GMainMenu('system',_M('Sistema', $module), 'policy-16x16.png');
        $otherMenu->addUserOption( 'gtcConfigReport', A_ACCESS, _M('Relatório', $module), $module, "main:configuration:configReport", null, null, 'report-16x16.png');
        $otherMenu->addUserOption( 'gtcPreference', A_ACCESS, _M('Preferência', $module), $module, "$home:preference", null, null, 'preference-16x16.png');
        $otherMenu->addUserOption( 'gtcRequestChangeExemplaryStatusAccess', A_ACCESS, _M('Permissão para alteração de estado', $module), $module, "$home:requestChangeExemplaryStatusAccess", null, null, 'requestChangeExemplaryStatus-16x16.png');
        $otherMenu->addUserOption( 'gtcFormatBackOfBook', A_ACCESS, _M('Formato da lombada',$module), $module, "main:configuration:formatbackofbook", null, array("function" => "search"), 'formatbackofbook-16x16.png' );
        $otherMenu->addUserOption( 'gtcLabelLayout', A_ACCESS, _M('Modelo de etiqueta',$module), $module, "main:configuration:labelLayout", null, array("function" => "search"), 'labelLayout-16x16.png' );
        $otherMenu->addUserOption( 'gtcDomain', A_ACCESS, _M('Domínio', $module), $module, "$home:domain", null, null, 'domain-16x16.png');
        $otherMenu->addUserOption( 'gtcHelp', A_ACCESS, _M('Ajuda', $module), $module, "$home:help", null, null, 'help-16x16.png');
        $otherMenu->addSeparator();
        $otherMenu->addUserOption( 'gtcConfigWorkflow', A_ACCESS, _M('Estado do workflow', $module), $module, "main:configuration:workflowStatus", null, null, 'supplier-16x16.png');
        $otherMenu->addUserOption( 'gtcConfigWorkflow', A_ACCESS, _M('Transição do workflow', $module), $module, "main:configuration:workflowTransition", null, null, 'supplier-16x16.png');
        $otherMenu->addSeparator();
        $otherMenu->addUserOption( 'gtcScheduleTask', A_ACCESS, _M('Agendamento de tarefa', $module), $module, "main:configuration:scheduletask", null, null, 'scheduleTask-16x16.png');
        $otherMenu->addUserOption( 'gtcDependencyCheck', A_ACCESS, _M('Conferir dependências', $module), $module, "$home:dependencyCheck", null, null, 'preference-16x16.png');

        if ( MUtil::getBooleanValue( $MIOLO->getConf('gnuteca.debug') ) && GOperator::hasSomePermission() )
        {
            $otherMenu->addOption( _M('Teste unitário', $module), 'gnuteca3', 'unitTest', null,null, 'unitTest-16x16.png');
        }
    
        $otherMenu->addUserOption( 'gtcFormContent', A_ACCESS, _M('Conteúdo do formulário', $module), $module, "main:administration:formContent", null, null, 'formContent-16x16.png');
        $otherMenu->addUserOption( 'gtcBackup', A_ACCESS, _M('Cópia de segurança', $module), $module, "$home:backup", null, null, 'backup-16x16.png');
      
        $confMenu->addMenu($otherMenu);
        $this->addMenu($confMenu);

        $materialMenu = new GMainMenu('material', _M('Catalogação', $module), 'catalogue-16x16.png' );
        $materialMenu->addUserOption('gtcSpreadsheet', A_ACCESS, _M('Planilha',$module), $module, "main:catalogue:spreadsheet", null, null, 'spreadsheet-16x16.png' );
        $materialMenu->addUserOption('gtcTag', A_ACCESS, _M('Etiqueta',$module), $module, "main:catalogue:tag", null, null, 'tag-16x16.png' );
        $materialMenu->addUserOption('gtcMarcTagListing', A_ACCESS, _M('Listagem de campos Marc', $module), $module, "$home:marcTagListing", null, null, 'marcTagListing-16x16.png');
        $materialMenu->addUserOption('gtcRulesToCompleteFieldsMarc', A_ACCESS, _M('Regras para completar campos marc',$module), $module, "main:catalogue:rulestocompletefieldsmarc", null, null, 'rulestocompletefieldsmarc-16x16.png' );
        $materialMenu->addUserOption('gtcLinkOfFieldsBetweenSpreadsheets', A_ACCESS, _M('Relação de campos entre planilhas',$module), $module, "main:catalogue:linkoffieldsbetweenspreadsheets", null, null, 'linkoffieldsbetweenspreadsheets-16x16.png' );
        $materialMenu->addSeparator();
        $materialMenu->addUserOption('gtcSeparator', A_ACCESS, _M('Separador', $module), $module, "main:catalogue:separator", null, null, 'separator-16x16.png');
        $materialMenu->addUserOption('gtcPrefixSuffix', A_ACCESS, _M('Prefixo Sufixo',$module), $module, "main:catalogue:prefixsuffix", null, null, 'prefixsuffix-16x16.png' );
        $materialMenu->addUserOption('gtcMaterialType', A_ACCESS, _M('Tipo', $module), $module, "$home:materialType", null, null, 'materialType-16x16.png');
        $materialMenu->addUserOption('gtcMaterialPhysicalType', A_ACCESS, _M('Tipo físico', $module), $module, "$home:materialPhysicalType", null, null, 'materialPhysicalType-16x16.png');
        $materialMenu->addUserOption('gtcMaterialGender', A_ACCESS, _M('Gênero', $module), $module, "$home:materialGender", null, null, 'materialGender-16x16.png');
        $confMenu->addMenu($materialMenu);

        $operatorMenu = new GMainMenu('operator', _M('Operador', $module), 'operatorlibraryunit-16x16.png' );
        $operatorMenu->addUserOption('gtcOperatorLibraryUnit',A_ACCESS,_M('Operador',$module),$module,"main:configuration:operatorlibraryunit",null,null,'operatorlibraryunit-16x16.png');
        $operatorMenu->addUserOption('gtcOperatorGroup', A_ACCESS, _M('Grupo de operador', $module), $module, "$home:operatorGroup", null, null, 'operatorGroup-16x16.png');
        $confMenu->addMenu($operatorMenu);

        //caso estiver logado
        if ( $this->manager->getLogin()->id )
        {
            $this->addOption( _M('Trocar unidade','gnuteca3'), 'gnuteca3', 'javascript:'.GUtil::getAjax('statusChangeLoggedLibrary',null,null,null, 'gnuteca') , '', '', 'libraryUnit-16x16.png');
            $this->addOption( _M('Sobre'), 'gnuteca3', 'javascript:'.GUtil::getAjax('statusAbout') , '', '', 'info-16x16.png');
            $this->addOption( _M('Sair','gnuteca3'), 'gnuteca3', 'logout', '', '', 'exit-16x16.png');
        }
    }
}
?>
