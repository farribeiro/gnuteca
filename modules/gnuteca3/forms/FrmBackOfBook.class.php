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
 *
 * @since
 * Class created on 05/11/2008
 *
 **/
$MIOLO->uses( 'forms/FrmBarCode.class.php', $module );
class FrmBackOfBook extends FrmBarCode
{
    public $MIOLO;
    public $module;
    public $business;
    public $busExemplaryControl;
    public $busLibraryUnit;

    const OPTION_CONTROL_NUMBER = 1;
    const OPTION_ITEM_NUMBER    = 2;

    public function __construct()
    {
        $this->MIOLO    = MIOLO::getInstance();
        $this->module   = MIOLO::getCurrentModule();
        $this->business            = $this->MIOLO->getBusiness($this->module, 'BusFormatBackOfBook');
        $this->busExemplaryControl = $this->MIOLO->getBusiness($this->module, 'BusExemplaryControl');
        $this->busLibraryUnit      = $this->MIOLO->getBusiness($this->module, 'BusLibraryUnit');

        //Define internal format options
        define('OPTION_ILABEL_NO',       1);
        define('OPTION_ILABEL_YES_SAME', 2);
        define('OPTION_ILABEL_YES_DIFF', 3);
        define('OPTION_ILABEL_ONLY',     4);

        $this->forceCreateFields = true;
        $this->setTransaction('gtcBackOfBook');
        parent::__construct( _M('Lombada', $this->module) );

        if (GForm::primeiroAcessoAoForm())
        {
            GRepetitiveField::clearData('codes');
        }

        //força formulário de busca
        $this->setSearchFunction('test');
    }

    public function mainFields()
    {
        $lbl = new MLabel( _M('Intervalo', $this->module) . ':' );
        $lbl->setWidth(FIELD_LABEL_SIZE);
        $interval   = new MRadioButtonGroup('interval', null, $this->getIntervalList(), FrmBarCode::INTERVAL_CONTINUOUS, null, 'vertical');
        $form       = $this->manager->page->getFormId();
        $interval->addAttribute('onchange', "miolo.doAjax( (dojo.byId('interval_0').checked ? 'getContinuousFields' : 'getDiscreteFields') ,'','{$form}');");
        $fields[]   = new GContainer('hctInterval', array($lbl, $interval));

        $options = array(
            array(_M('Número do exemplar', $this->module), self::OPTION_ITEM_NUMBER),
            array(_M('Número de controle', $this->module), self::OPTION_CONTROL_NUMBER),
        );

        $fields[] = new GRadioButtonGroup('exemplarys', _M('Exemplares', $this->module), $options, self::OPTION_ITEM_NUMBER, null, 'vertical');
        $fields[] = $divInterval = new MDiv('divInterval', $this->getContinuousFields(TRUE));

        $options = array(
            OPTION_ILABEL_NO       => _M('Não', $this->module),
            OPTION_ILABEL_YES_SAME => _M('Sim, na mesma etiqueta', $this->module),
            OPTION_ILABEL_YES_DIFF => _M('Sim, em etiqueta diferente', $this->module),
            OPTION_ILABEL_ONLY     => _M('Somente etiqueta interna', $this->module)
        );
        
        $fields[] = new GSelection('internalLabel', 1, _M('Etiqueta interna', $this->module), $options);
        $fields[] = new GSelection('formatBackOfBookId', 1, _M('Formato da lombada', $this->module), $this->business->listFormatBackOfBook());
        $fields[] = new MSeparator();
        $fields[] = $fontSize = new GSelection('fontSize', '10', _M('Tamanho da fonte', $this->module) , $this->getSizeList() , false, null, null, true);
        $fontSize->addStyle('width','60px');
        
        $fields[] = new MIntegerField('beginLabel', '1', _M('Etiqueta inicial', $this->module), 5);

        $labelLayout = new MLabel( _M('Modelo de etiqueta','gnuteca3'));
        $labelLayout->setWidth(FIELD_LABEL_SIZE);
        $labelLayoutId = new GLookupTextField ('labelLayout',  DEFAULT_BARCODE_LABEL_LAYOUT, '', FIELD_LOOKUPFIELD_SIZE, null, null, 'labelLayoutDescription, lines, columns, topMargin, leftMargin, verticalSpacing, horizontalSpacing, labelHeight, labelWidth, pageFormat', $this->module, 'LabelLayout');
        $labelLayoutId->setContext($this->module, $this->module, 'LabelLayout', 'filler', 'labelLayout,labelLayoutDescription,lines,columns,topMargin,leftMargin,verticalSpacing,horizontalSpacing,labelHeight,labelWidth,pageFormat', '', true);
        $labelLayoutDescription = new MTextField ('labelLayoutDescription', '', null, FIELD_DESCRIPTION_LOOKUP_SIZE);
        $labelLayoutDescription->setReadOnly(true);
        $fields[] = new GContainer('labelLayoutContainer', array($labelLayout, $labelLayoutId, $labelLayoutDescription));
        $fields[] = $this->getLabelFields();

        $fields[] = new MButton('BtnPrint', _M('Gerar', $this->module) , GUtil::getAjax('tbBtnPrint_click'), GUtil::getImageTheme('print-16x16.png'));

        $this->forceFormContent = TRUE;
        $this->setFields($fields);
        $this->setLabelWidth(FIELD_LABEL_SIZE);
        $this->setShowPostButton(false);

        //desabilita botões da toolbar
        $this->_toolBar->disableButton( MToolBar::BUTTON_DELETE );
        $this->_toolBar->disableButton( MToolBar::BUTTON_NEW );
        $this->_toolBar->disableButton( MToolBar::BUTTON_RESET );
        $this->_toolBar->disableButton( MToolBar::BUTTON_SAVE );
        
        if ( $this->primeiroAcessoAoForm()  && ( $this->GetField('interval')->value == self::INTERVAL_DISCRETE ) ) 
        {
            $this->page->onload(  GUtil::getAjax('getDiscreteFields') );
        }

    }

    public function tbBtnPrint_click($data = null)
    {
        $beginCode     = $this->beginCode->value;
        $endCode       = $this->endCode->value;
        $interval      = $data->interval;
        $exemplarys    = $data->exemplarys;
        
        if ( ($interval == FrmBarCode::INTERVAL_CONTINUOUS) && ($exemplarys == self::OPTION_ITEM_NUMBER) )
        {
            $lengthFirst = strlen(trim($beginCode));

            for ($x=$beginCode; $x<=$endCode; $x++)
            {
                $itemNumber = GUtil::strPad($x, $lengthFirst, '0', STR_PAD_LEFT);
                $codes[$x] = $this->busExemplaryControl->getExemplaryControl( $itemNumber );
            }
        }

        if ( ($interval == FrmBarCode::INTERVAL_DISCRETE) && ($exemplarys == self::OPTION_ITEM_NUMBER) )
        {
            $codeList = GRepetitiveField::getData('codes');
            $codes    = null;

            if ($codeList)
            {
                foreach ($codeList as $key => $c)
                {
                    //Não adicionar exemplares excluídos
                    if (!$c->removeData)
                    {
                        $codes[$key] = $this->busExemplaryControl->getExemplaryControl($c->itemNumber);
                    }
                }
            }
        }

        if ( ($interval == FrmBarCode::INTERVAL_CONTINUOUS) && ($exemplarys == self::OPTION_CONTROL_NUMBER) )
        {
            $lengthFirst = strlen(trim($beginCode));

            for ($x=$beginCode; $x<=$endCode; $x++)
            {
                $itemNumber = GUtil::strPad($x, $lengthFirst, '0', STR_PAD_LEFT);
                $exemplary = $this->busExemplaryControl->getExemplaryOfMaterial($itemNumber);

                if ($exemplary)
                {
                    foreach ($exemplary as $ex)
                    {
                        $codes[ $ex->itemNumber ] = $ex;
                    }
                }
            }
        }

        if ( ($interval == FrmBarCode::INTERVAL_DISCRETE) && ($exemplarys == self::OPTION_CONTROL_NUMBER) )
        {
            $codeList = GRepetitiveField::getData('codes');
            $codes    = null;
            if ($codeList)
            {
                foreach ($codeList as $c)
                {
                    //Não adicionar números de controle excluídos
                    if (!$c->removeData)
                    {
                        $exemplary = $this->busExemplaryControl->getExemplaryOfMaterial($c->itemNumber);

                        if ($exemplary)
                        {
                            foreach ($exemplary as $ex)
                            {
                                $codes[ $ex->itemNumber ] = $ex;
                            }
                        }
                    }
                }
            }
        }
        
        $this->MIOLO->getClass($this->module, 'GPDFLabel');
        $this->MIOLO->getClass($this->module, 'report/rptBackOfBook');

        $report = new rptBackOfBook($data, $codes);
        $report->showDownloadInfo();
    }
}
?>