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
 * Back of book report
 *
 * @author Moises Heberle [moises@solis.coop.br]
 *
 * @version $Id$
 *
 * \b Maintainers: \n
 * Jamiel Spezia [jamiel@solis.coop.br]
 * Rafael Luís Spengler [rafael@solis.coop.br]
 * Tiago Gossmann [tiagog@solis.coop.br]
 * Sandro R. Weisheimer [sandrow@solis.coop.br]
 *
 * @since
 * Class created on 06/11/2008
 *
 **/

class rptBackOfBook extends GPDFLabel
{
    public $MIOLO, $module;
    public $busFormatBackOfBook;
    public $busLibraryUnitConfig;
    public $busMaterial;


    function __construct($data, $codes)
    {
        $this->MIOLO  = MIOLO::getInstance();
        $this->module = MIOLO::getCurrentModule();
        $this->busFormatBackOfBook = $this->MIOLO->getBusiness($this->module, 'BusFormatBackOfBook');
        $this->busMaterial         = $this->MIOLO->getBusiness($this->module, 'BusMaterial');
        $this->MIOLO->getClass($this->module, 'GFunction');

        parent::__construct($data);
        $this->setBeginLabel($data->beginLabel ? $data->beginLabel : 1);

        // Início da configuração do relatório
        $this->setSubject(_M('Lombada', $this->module));
        $this->setTitle(_M('Lombada', $this->module));
        $this->setFont('Arial', '', $data->fontSize ? $data->fontSize : 10);
        $cellSize = $data->fontSize / 20; //tamanho da célula

        for ( $i=1; $i < $data->initialLabel; $i++ )
        {
            $this->setBeginPositionOfTheLabel();
        }

        $gf         = new GFunction();
        $format     = $this->busFormatBackOfBook->getFormatBackOfBook($data->formatBackOfBookId);
        $tagsFormat = GUtil::extractMarcVariables($format->format);
        $tagsInternalFormat = GUtil::extractMarcVariables($format->internalFormat);
        $tags       = array_unique( array_merge($tagsFormat, $tagsInternalFormat) );

        foreach ($codes as $itemNumber => $ec)
        {
            $myFormat = $format->format;

            if (!$ec->controlNumber)
            {
                    continue;
            }

            $this->checkBreakLine();
            $this->checkBreakPage();

            //Coloca o ponteiro para desenhar a etiqueta
            $this->setBeginPositionOfTheLabel();

            $gf->clearVariables();
            $gf->setVariable('$CONTROL_NUMBER', $ec->controlNumber);

            //troca cada uma das variaveis de tag, pelo valor pelo buscado no banco
            foreach ($tags as $tag)
            {
                $tagMarc = substr($tag, 1);

                list ($field, $subfield) = explode('.', $tagMarc);

                $line = null;

                if ( $field == MARC_EXEMPLARY_FIELD )
                {
                    $line = $ec->line;
                }

               	$gf->setVariable($tag, $this->busMaterial->getContentTag($ec->controlNumber, $tagMarc, $line));
            }

            //isso passa a linha para o GFunction, dessa forma ele sabe como pegar o getTagDescription corretamente
            $gf->line = $ec->line;

            if ($data->internalLabel != OPTION_ILABEL_ONLY)
            {
                $content = explode("\n", $gf->interpret($myFormat ,false) );

                $newContent = null;

                //remove linhas sem conteúdo
                if (is_array($content))
                {
                    foreach ($content as $i => $line)
                    {
                        if ( strlen(trim($line)) )
                        {
                            //pega o tamanho da string
                            $stringWidth = $this->getStringWidth( $line );
                            $labelWidth  = $data->labelWidth;

                            //se o tamanho do texto for maior que o tamanho permitido pela etiqueta
                            if ( $stringWidth > $labelWidth )
                            {
                                $temp = $this->lineBreak($line, $stringWidth, $labelWidth);

                                //e adiciona todas elas ao novo conteúdo
                                foreach ( $temp as $y )
                                {
                                    $newContent[] = $y;
                                }
                            }
                            else
                            {
                                //só adiciona a linha normal
                                $newContent[] = $line;
                            }
                        }
                    }
                }

                $tamMax = 0;
                $yInicial = $this->getY(); //Pega o valor inicial do Y para gerar a etiqueta interna na mesma coluna

                //define as células de conteúdo
                foreach ($newContent as $value)
                {
                    $this->Cell($this->x, $cellSize, $value, 0, 2, 'L');

                    //Pega o maior tamanho para alinhar a etiqueta interna na mesma etiqueta
                    $tam = $this->GetStringWidth($value);
                    if ($tamMax < $tam )
                    {
                        $tamMax = $tam;
                    }
                }
            }
            $itext = array();

            if (in_array($data->internalLabel, array(OPTION_ILABEL_YES_SAME, OPTION_ILABEL_YES_DIFF, OPTION_ILABEL_ONLY)))
            {
                $itext = explode("\n", $gf->interpret($format->internalFormat, false));
            }

            if (count($itext))
            {
            	//calcula a largura certa para cada linha da etiqueta interna
                $internalLabel = array();
            	foreach ($itext as $line)
            	{
	            	//pega o tamanho da string
	                $stringWidth = $this->getStringWidth( $line );
	                $labelWidth  = $data->labelWidth;
	
	                //se o tamanho do texto for maior que o tamanho permitido pela etiqueta
	                if ( $stringWidth > $labelWidth )
	                {
	                    $temp = $this->lineBreak($line, $stringWidth, $labelWidth);
	                    //e adiciona todas elas ao novo conteúdo
	                    foreach ( $temp as $y )
	                    {
	                        $internalLabel[] = $y;
	                    }
	                }
	                else
	                {
	                    //só adiciona a linha normal
	                    $internalLabel[] = $line;
	                }
            	}   
            	
                if ($data->internalLabel == OPTION_ILABEL_YES_SAME)
                {
                      $this->setXY($this->x+$tamMax+0.2, $yInicial);
                }
                else if ($data->internalLabel == OPTION_ILABEL_YES_DIFF)
                {
                      $this->checkBreakLine();
                      $this->checkBreakPage();
                      $this->setBeginPositionOfTheLabel();
                }

                foreach ($internalLabel as $text)
                {

                    $this->Cell($this->x, $cellSize, $text, 0, 2, 'L');
                }
            }
        }

        $this->setFilename( 'backofbook_' . date('Ymd') . '.pdf' );
        $this->generate(false);
    }
   
    /**
     * Método para quebar a linha conforme o limite de caractéres
     * 
     * @param $string a quebrar
     * @param limite de caractéres
     * @return array
     */
    private function lineBreak($string, $stringSize, $limit)
    {
    	if ( strlen($stringSize) == 0 )
    	{
    		$stringSize = $this->getStringWidth( $string );
    	}

        //calcula o tamanho certo
        $cutLimit = ( strlen( $string ) * $limit ) / $stringSize;
        
        //quebra em linhas
        $lines = explode( "\n" , wordwrap( $string, $cutLimit ) );
    	
        return $lines;
    }
}
?>