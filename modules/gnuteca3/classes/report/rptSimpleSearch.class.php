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
 * SimpleSearch report
 *
 * @author Moises Heberle [moises@solis.coop.br]
 *
 * @version $Id$
 *
 * \b Maintainers: \n
 * Jamiel Spezia [jamiel@solis.coop.br]
 * Rafael Luís Spengler [rafael@solis.coop.br]
 * Tiago Gossmann [tiagog@solis.coop.br]
 *
 * @since
 * Class created on 23/03/2009
 *
 **/
class rptSimpleSearch extends GPDF
{
    public $MIOLO;
    public $module;
    public $busMaterialControl;
    public $fontScale;

    public function __construct( $sender )
    {
        $this->MIOLO        = MIOLO::getInstance();
        $this->module       = MIOLO::getCurrentModule();
        $leftMargin         = 20; //margem da esquerda
        $lineHeight         = 4;  //altura da linha
        $columnSizeStatus   = 35; //tamanhos de cada coluna da direita
        $columnSizeType     = 25;
        $columnSizePhysical = 18;
        $columnSizeTotal    = 12;
        $widthCol2          = $columnSizeStatus + $columnSizeType + $columnSizePhysical + $columnSizeTotal; //tamanho da coluna da direita
        $widthCol1          = 75; //tamanho da coluna da esquerda
        $widthCols          = $widthCol1 + $widthCol2; //tamanho total
        $this->fontScale    = 2.2; //comparativo em tamanho do pdf para tamanho da font, se mudar a fonte precisar mudar isto
        $this->filename     = 'simple_search_' . date('Ymd') . '.pdf';

        $this->busMaterialControl = $this->MIOLO->getBusiness($this->module, 'BusMaterialControl');

        parent::__construct( $this->pathFile );

        //Set config of document
        $this->SetLineWidth(0.3);
        $this->SetFont('Courier', 'B', 9);

        //monta cabeçalho
        $this->AddPage();
        $this->setY( $leftMargin );
        $this->setX( $leftMargin );
        $this->Cell( $widthCol1, $lineHeight, _M('Informação do material', $this->module), 1, 0, 'C' );
        $this->Cell( $widthCol2, $lineHeight, _M('Informações dos exemplares', $this->module), 1, 0, 'C' );
        $this->ln();
        $this->setBold( false );

        //Percorre os dados dos itens selecionados e imprime no PDF
        foreach ( $sender->selectgrdSimpleSearch as $x => $controlNumber )
        {
            $searchFormat = array();
            $exemplaryData = array();

            $v    = $_SESSION['SimpleSearchGridData'][$controlNumber]; //pega os dados da pesquisa ( estão guardados na sessão )

            $data = $v['data'];
            $data = preg_split('/<([ \/]{0,}?[bB][rR][ \/]{0,}?)>/U', $data);

            $i = 0;
            //trabalha o data para funcionar no pdf
            foreach ( $data as $linha )
            {
            	$linha = strip_tags( $linha ); //tira tags
            	$linha = trim( $linha, '/>');  //tira /> sobresalentes
                $linha = str_replace( array("\r","\t","\n"),'',trim( $linha ) ); //tira espaços, tab, enter

                $linha = str_replace( '  ' , ' ' , $linha); //diminiu espaços
                $linha = str_replace( '  ' , ' ' , $linha); //diminiu espaços
                $linha = str_replace( '  ' , ' ' , $linha); //diminiu espaços

                if (!$linha)
                {
                    continue;
                }

                $split          = wordwrap( $linha, $this->scale( $widthCol1 ), "\n");
                $split          = explode( "\n",$split );

                if ( is_array( $split ) )
                {
                	foreach ( $split as $line => $info )
                	{
                	   $searchFormat[] = $info;
                	}
                }
                else
                {
                	$searchFormat[] = $split;
                }
            }

            foreach ( $v['exemplarys'] as $libraryUnitId => $exemplaryStatus )
            {
                //if ( count($v['exemplarys']) > 1 )
                {
                    $exemplaryData[] = _M('Unidade de biblioteca', $this->module) . ': ' . $v['exemplaryLibrary'][$libraryUnitId];
                }

                //adiciona linha de exemplares do pai, caso precise
                if ( $isFatherExemplar == $v['isFatherExemplary'] )
                {
                    $exemplaryData[] = _M('Exemplares do fascículo', $this->module);
                }

                //Create table titles
                $exemplaryData[] = array(
                                 _M('Estado', $this->module),
                                 _M('Tipo', $this->module),
                                 _M('Físico', $this->module),
                                 _M('Total', $this->module),
                                 'bold' => true);

                foreach ($exemplaryStatus as $status => $materials)
                {
                    foreach ($materials as $materialTypeId => $materialPhysical)
                    {
                        foreach ($materialPhysical as $materialPhysicalId => $item)
                        {
                            foreach ($item as $line => $exemplary)
                            {
                            }
                        }
                    }

                    $exemplaryData[] = array(
                                     $exemplary->exemplaryStatusDescription,
                                     $exemplary->materialTypeDescription,
                                     $exemplary->materialPhysicalTypeDescription,
                                     count($item)
                                     );

                }
            }

            $lines = (count($searchFormat) > count($exemplaryData)) ? count($searchFormat) : count($exemplaryData); //get bigger column size in lines

            //Check page break
            if ( ($this->GetY() + ($lines * $lineHeight) + $lineHeight) >= $this->PageBreakTrigger )
            {
                $this->pageBreak();
            }

            for ( $i=0; $i < $lines; $i++ )
            {
                if ( $i == 0 )
                {
                    $this->SetX($leftMargin);
                    $this->Cell($widthCols, $lineHeight, '', 'T', 0); //BORDER bottom
                }

                $this->SetX($leftMargin);
                $this->Cell($widthCol1, $lineHeight, $searchFormat[$i], 'LR', 0);

                //celulas dos exemplares
                if ( is_array( $exemplaryData[$i] ) )
                {
                    if ($exemplaryData[$i]['bold'])
                    {
                        $this->setBold( true );
                    }

                    $this->Cell( $columnSizeStatus,   $lineHeight, $this->crop( $exemplaryData[$i][0] , $columnSizeStatus   ) , 1, 0, 'L');
                    $this->Cell( $columnSizeType,     $lineHeight, $this->crop( $exemplaryData[$i][1] , $columnSizeType     ) , 1, 0, 'L');
                    $this->Cell( $columnSizePhysical, $lineHeight, $this->crop( $exemplaryData[$i][2] , $columnSizePhysical ) , 1 ,0, 'L');
                    $this->Cell( $columnSizeTotal,    $lineHeight, $this->crop( $exemplaryData[$i][3] , $columnSizeTotal    ) , 1, 0, 'R');
                    $this->setBold( false );
                }
                else if ( $exemplaryData[$i] )
                {
                	$this->setBold( true );
                    $this->Cell($widthCol2, $lineHeight, $exemplaryData[$i], 1, 0, 'L');
                    $this->setBold( false );
                }
                else
                {
                    $this->Cell($widthCol2, $lineHeight, '', 'R');
                }

                $this->ln();
            }
            $this->SetX($leftMargin);
            $this->Cell($widthCols, $lineHeight, '', 'T', 0); //BORDER top
        }
    }

    public function pageBreak()
    {
        $this->AddPage();
        $this->setY(20);
    }

    /**
     * Escala um número do pdf para a escala da fonte
     *
     * @param $number
     * @return unknown_type
     */
    public function scale( $number )
    {
        return round( ( $number/ $this->fontScale ), 0 );
    }

    /**
     * Corta uma string para fechar com o tamanho da fonte e da escala
     *
     * @param $string
     * @param $number
     * @return unknown_type
     */
    public function crop( $string, $number )
    {
        return substr( $string ,  0, $this->scale( $number ) );
    }
}
?>
