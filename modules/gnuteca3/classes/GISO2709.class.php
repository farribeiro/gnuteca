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
 * Class
 *
 * @author Jamiel Spezia [jamiel@solis.coop.br]
 *
 * @version $Id$
 *
 * \b Maintainers: \n
 * Eduardo Bonfandini [eduardo@solis.coop.br]
 * Jader Fiegenbaum [jader@solis.coop.br]
 * Jamiel Spezia [jamiel@solis.coop.br]
 *
 * @since
 * Class created on 04/05/2009
 *
 **/

class GISO2709
{
    private $objetoDeSaida, //Registro lido             
            $registros, //todos os registros lido do arquivo ISO
            $errors, //Armazena os erros ocorridos
            $delimitadorDeRegistro, 
            $delimitadorDeCampo,
            $delimitadorDeSubCampo,
            $ascii;
            
    public  $registrosLidos, $registroAtual;

    /**
     * Construi o ISO com os parametros necessários para interpretação.
     *
     * @param string $arquivoISO caminho do arquivo iso
     * @param string $delimitadorDeRegistro
     * @param string $delimitadorDeCampo
     * @param string $delimitadorDeSubCampo
     * @param boolean $ascii
     */
    function __construct( $arquivoISO, $delimitadorDeRegistro, $delimitadorDeCampo, $delimitadorDeSubCampo, $ascii)
    {
        $this->ascii = $ascii;
        $this->defineDelimitadores($delimitadorDeRegistro, $delimitadorDeCampo, $delimitadorDeSubCampo);

        $conteudo = new GString(file_get_contents($arquivoISO) );
        //determina a quantidade de registros e separa cada registro na variavel de registros
        $this->registros = explode($this->delimitadorDeRegistro, $conteudo);
        
        $this->registroAtual = 0;
        $this->registrosLidos = count($this->registros)-1;
    }

    /**
     * Ao destruir retorna o encoding interno para o padrão
     */
    function  __destruct()
    {
        mb_internal_encoding('UTF-8');
    }

    /**
     * Define delimitadores de registro, campo e subcampo
     *
     * Caso em ASCII obtem o código chr do delimitador
     *
     * @param string $delimitadorDeRegistro
     * @param string $delimitadorDeCampo
     * @param string $delimitadorDeSubCampo
     */
    private function defineDelimitadores($delimitadorDeRegistro, $delimitadorDeCampo, $delimitadorDeSubCampo)
    {
        if ( $this->ascii == DB_TRUE )
        {
            $this->delimitadorDeRegistro = chr($delimitadorDeRegistro);
            $this->delimitadorDeCampo    = chr($delimitadorDeCampo);
            $this->delimitadorDeSubCampo = chr($delimitadorDeSubCampo);
        }
        else
        {
            $this->delimitadorDeRegistro = $delimitadorDeRegistro;
            $this->delimitadorDeCampo    = $delimitadorDeCampo;
            $this->delimitadorDeSubCampo = $delimitadorDeSubCampo;
        }
    }

    /**
     * Obtem um objeto de saída, um registro / um livro.
     * Retorna um array indexado pela etiqueta Ex. '100.a'
     *
     * @return array indexado pela etiqueta Ex. '100.a'
     */
    private function obterObjetoDeSaida()
    {
        $registro = $this->objetoDeSaida;
        $this->objetoDeSaida = array(); //Zera o atributo para utilizar na próxima leitura;
        return $registro;
    }

    /**
     * Adiciona uma mensagem de erro a classe
     *
     * @param string $mensagem
     */
    private function addError($mensagem)
    {   
        $this->erros[] = $mensagem;
    }

    /**
     * Obtem um array com as mensagem de erros
     *
     * @return array com as mensagem de erros
     */
    public function getErrors()
    {
        return $this->erros;
    }

    /**
     *  Verifica se existe o delimitador no conteúdo
     *
     * @param string $aprocurar conteúdo
     * @param string $delimiter delimitador
     * @return boolean
     */
    function checkDelimitador($aprocurar, $delimiter)
    {
        $fl_possui=false;

        for ( $n=0; $n<strlen($aprocurar); $n++ )
        {
            if (substr($aprocurar,$n, 1) == $delimiter)
            {
                $fl_possui=true;
            }
        }
        
        return $fl_possui;
    }
    
    function geraSaida($etiqueta, $i1, $i2, $subcampo, $conteudo )
    { 
        $tag[] = count($this->objetoDeSaida[$etiqueta . '.' . $subcampo]);
        $tag[] = $etiqueta;
        $tag[] = $i1;
        $tag[] = $i2;
        $tag[] = $subcampo;
        $tag[] = $conteudo;
        
        $this->objetoDeSaida[$etiqueta . '.' . $subcampo][] = $tag;

    }

    /**
     * Trata os dados do registro.
     * Recebe o registro como texto e converte para um array já tratado
     *
     * @param string $registro
     * @return void, não retorna nada
     * 
     */
    function trataRegistro($registro)
    {
        //Conta a quantidade de caracteres para validar o tamanho do registro. Feito isso pois o strlen e mb_strlen não conseguem contar certo dependendo da codificação
        $x = 0;

        while ( $registro[$x] != $this->delimitadorDeRegistro )
        {
            if ( is_null($registro[$x]) ) //verificação para não entrar em loop.
            {
                break;
            }
            
            $x++;
        }

        $tamanhoFisicoDoRegistro  = $x+1;
        $tamanhoLogicoDoRegistro  = substr($registro,0,5);
        $numeroDeIndicadores      = substr($registro,10,1);
        $tamanhoDoTamanho         = substr($registro,20,1);
        $tamanhoDaPosicaoInicial  = substr($registro,21,1);
        //de acordo com os teste é necessário definir a codificação como iso para que as contagens funcionem
        mb_internal_encoding('ISO-8859-1');

        $lider = substr($registro,0,24);
        $n = 24;
        $i = 1;

        
        while ( is_numeric(substr($registro,$n,3)) )
        {
            $codigoDaEtiqueta  = substr($registro,$n, 3); $n +=3;
            $tamanhoDaEtiqueta = substr($registro,$n, $tamanhoDoTamanho); $n += $tamanhoDoTamanho;
            $posicaoDaEtiqueta = substr($registro,$n, $tamanhoDaPosicaoInicial); $n += $tamanhoDaPosicaoInicial;
            
            $etiqueta["$codigoDaEtiqueta-$i"][1] = $posicaoDaEtiqueta; // Posicao Relativa
            $etiqueta["$codigoDaEtiqueta-$i"][2] = $tamanhoDaEtiqueta; // Tamanho do Campo

            if ($codigoDaEtiqueta == '001')
            {
                $GuardarEtiqueta = $i;
            }

            if ($i > $tamanhoLogicoDoRegistro)
            {
                $this->addError( _M('Não foi possível encontrar o delimitador de campo.', 'gnuteca3') );
                return false;
            }
            
            $i ++;
        }

        
        $i = $GuardarEtiqueta;
      
        if (($etiqueta["001-$i"]==null))  // Não possui número de controle
        {
            $this->addError("Não foi possível localizar o número de controle do registro {$this->registroAtual}. Líder = $lider"); 
        }
        else if ($tamanhoFisicoDoRegistro != $tamanhoLogicoDoRegistro)
        { 
            $this->addError( _M( "O registro @1 possui tamanho imcompatível. Líder = @2",'gnuteca', $this->registroAtual, $lider) );
        }
        else
        {
            $n++;
    
            //Adiciona o lider
            $this->geraSaida('000', ' ', ' ', 'a', $lider );
                    
            foreach ($etiqueta as $PreCodigoDaEtiqueta=>$CadaEtiqueta)
            {
                $codigoDaEtiqueta = substr($PreCodigoDaEtiqueta,0,3);
                $sufixoDaEtiqueta = substr($PreCodigoDaEtiqueta,4);
    
                $conteudo = substr($registro, $CadaEtiqueta[1] + $n, $CadaEtiqueta[2] -1);
                //Muda Campo do Número de Controle,
                //conforme formato MARC.
                if (substr($codigoDaEtiqueta,0,2) == '00')
                {
                    //Para etiquetas 00X inclui dois espaços,
                    //para acerto dos indicadores.
                    $conteudo = '  ' . $conteudo;
                    
                    if ($codigoDaEtiqueta == '001')
                    {
                        $codigoDaEtiqueta = '035';
                    }
                }
                
                $this->trataCampo($codigoDaEtiqueta, $conteudo, $numeroDeIndicadores);
            }
        }
    }
            
    function trataCampo($codigoDaEtiqueta, $conteudo, $numeroDeIndicadores)
    {
        $i = 0;
        
        $indicador1 = ($numeroDeIndicadores==2) ? substr($conteudo,0,1) : ' ';
        $indicador2 = ($numeroDeIndicadores==2) ? substr($conteudo,1,1) : ' ';
        $conteudo = substr($conteudo, $numeroDeIndicadores);
        
        if ( substr($conteudo,0,1)!=$this->delimitadorDeSubCampo )
        {
            $conteudo = $this->delimitadorDeSubCampo . 'a' . $conteudo; // Corrigidos Registros Sem início SubCampo
        }
        
        for($n=0; $n<=strlen($conteudo); $n++)
        {
            $letrinha = substr($conteudo,$n,1);
            
            if ($letrinha==$this->delimitadorDeSubCampo)
            {  
                $i ++; $subcampo[$i] =""; 
            }
            else
            {  
                $subcampos[$i] .= $letrinha; 
            }
        }
                
        $ind = false;
                
        foreach($subcampos as $subcampo)
        {
            $codigoDoSubCampo   = substr($subcampo,0,1);
            $conteudoDoSubCampo = substr($subcampo,1);

            $this->geraSaida($codigoDaEtiqueta, $indicador1, $indicador2, $codigoDoSubCampo, $conteudoDoSubCampo);
        }
    }

    

    /**
     * Função utilizada dentro de um while para proceder com a leitura dos registros
     *
     * @return boolean
     * @example while ( ($registro = $i->leRegistro()) != null)
     *
     */
    function leRegistro()
    {
        if ( $this->registroAtual < $this->registrosLidos )
        {
            $registro = $this->registros[$this->registroAtual];
            $registro .= $this->delimitadorDeRegistro;
            //verifica se o delimitador existe
            if ( $this->checkDelimitador($registro, $this->delimitadorDeCampo) )
            {
                //trata os dados do registro
                $this->trataRegistro($registro);
                $this->registroAtual++;
                
                $retorno = $this->obterObjetoDeSaida();
                return count($retorno) != 0 ? $retorno : true ;
            }
            
            return true; // VER
        }
        else
        {
            return false;
        }
    }
}
?>
