<?php
// +-----------------------------------------------------------------+
// | MIOLO - Miolo Development Team - UNIVATES Centro Universit�rio  |
// +-----------------------------------------------------------------+
// | Copyleft (l) 2001 UNIVATES, Lajeado/RS - Brasil                 |
// +-----------------------------------------------------------------+
// | Licensed under GPL: see COPYING.TXT or FSF at www.fsf.org for   |
// |                     further details                             |
// |                                                                 |
// | Site: http://miolo.codigoaberto.org.br                          |
// | E-mail: vgartner@univates.br                                    |
// |         ts@interact2000.com.br                                  |
// +-----------------------------------------------------------------+
// | Abstract: This file contains utils functions                    |
// |                                                                 |
// | Created: 2001/08/14 Thomas Spriestersbach                       |
// |                     Vilson Cristiano G�rtner,                   |
// |                                                                 |
// | History: Initial Revision                                       |
// +-----------------------------------------------------------------+

/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MUtil
{
    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $value1 (tipo) desc
     * @param $value2 (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function NVL($value1, $value2)
    {
        return ($value1 != NULL) ? $value1 : $value2;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $value1 (tipo) desc
     * @param $value2 (tipo) desc
     * @param $value3 (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function ifNull($value1, $value2, $value3)
    {
        return ($value1 == NULL) ? $value2 : $value3;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param &$value1 (tipo) desc
     * @param $value2 (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setIfNull(&$value1, $value2)
    {
        if ($value1 == NULL) $value1 = $value2;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param &$value1 (tipo) desc
     * @param $value2 (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setIfNotNull(&$value1, $value2)
    {
        if ($value2 != NULL) $value1 = $value2;
    }

    /**
     * @todo TRANSLATION
     * Retorna o valor booleano da vari�vel
     * Fun��o utilizada para testar se uma vari�vel tem um valor booleano, conforme defini��o: ser� verdadeiro de 
     *      for 1, t ou true... caso contr�rio ser� falso.
     *
     * @param $value (misc) valor a ser testado
     *
     * @returns (bool) value
     *
     */
    public static function getBooleanValue($value)
    {
        $trues = array('t','1','true','True');

        if( is_bool($value) )
        {
            return $value;
        }

        return in_array($value,$trues);
    }

    /**
     * @todo TRANSLATION
     * Retorna o valor da vari�vel sem os caracteres considerados vazios
     * Fun��o utilizada para remover os caracteres considerados vazios
     *
     * @param $value (misc) valor a ser substituido
     *
     * @returns (string) value
     *
     */
    public function removeSpaceChars($value)
    {
        $blanks = array("\r"=>'',"\t"=>'',"\n"=>'','&nbsp;'=>'',' '=>'');

        return strtr($value, $blanks);
    }

    /**
     * @todo TRANSLATION
     * Copia diretorio
     * Esta funcao copia o conteudo de um diretorio para outro
     *
     * @param $sourceDir (string) Diretorio de origem
     * @param $destinDir (string) Diretorio de destino
     *
     * @returns (string) value
     */
    public function copyDirectory($sourceDir, $destinDir)
    {
        if( file_exists($sourceDir) && file_exists($destinDir) )
        {
            $open_dir = opendir($sourceDir);
    
            while ( false !== ( $file = readdir($open_dir) ) )
            {
                if( $file != "." && $file != ".." )
                {
                    $aux = explode ('.',$file);
    
                    if ( $aux[0] != "" )
                    {
                        if( file_exists($destinDir."/".$file) && 
                            filetype($destinDir."/".$file) != "dir" )
                        {
                            unlink($destinDir."/".$file);
                        }
                        if( filetype($sourceDir."/".$file) == "dir" )
                        {
                            if( ! file_exists($destinDir."/".$file) )
                            {
                                mkdir($destinDir."/".$file."/");
                                self::copyDirectory($sourceDir."/".$file, $destinDir."/".$file);
                            }
                        }
                        else
                        {
                            copy($sourceDir."/".$file, $destinDir."/".$file);
                        }
                    }
                }
            }
        }
    }


    /**
     * @todo TRANSLATION
     * Remove diretorio
     * Esta funcao remove recursivamente o diretorio e todo o conteudo existente dentro dele
     *
     * @param $directory (string) Diretorio a ser removido
     * @param $empty (string) 
     *
     * @returns (string) value
     */
    public function removeDirectory($directory, $empty=FALSE)
    {
        if(substr($directory,-1) == '/')
        {
            $directory = substr($directory,0,-1);
        }
    
        if(!file_exists($directory) || !is_dir($directory))
        {
            return FALSE;
        }
        elseif( is_readable($directory) )
        {
            $handle = opendir($directory);
    
            while ( FALSE !== ( $item = readdir($handle) ) )
            {
                if( $item != '.' && $item != '..' )
                {
                    $path = $directory.'/'.$item;
    
                    if( is_dir($path) )
                    {
                        self::removeDirectory($path);
                    }
                    else
                    {
                        unlink($path);
                    }
                }
            }
    
            closedir($handle);
    
            if( $empty == FALSE )
            {
                if( ! rmdir($directory) )
                {
                    return FALSE;
                }
            }
        }
    
        return TRUE;
    }
    
    /**
     * @todo TRANSLATION
     * Retorna o diret�rio temporario
     * Esta funcao retorna o diret�rio tempor�rio do sistema operacional
     *
     * @returns (string) directory name
     */
    static public function getSystemTempDir()
    {
        $tempFile = tempnam( md5(uniqid(rand(), TRUE)), '' );
        if ( $tempFile )
        {
            $tempDir = realpath( dirname($tempFile) );
            unlink( $tempFile );

            return $tempDir;
        }
        else
        {
            return '/tmp';
        }

    }

    /**
     * Searches the array recursively for a given value and returns the corresponding key if successful.
     *
     * @param (string) $needle
     * @param (array) $haystack
     * @return (mixed) If found, returns the key, othreways FALSE.
     */
    public static function array_search_recursive($needle, $haystack)
    {    
        $found  = FALSE;
        $result = FALSE;
      
        foreach ($haystack as $k => $v)
        {
            if (is_array($v))
            {
                for ($i=0; $i<count($v); $i++)
                {
                    if ($v[$i] === $needle)
                    {
                      $result = $v[0];
                      $found  = TRUE;
                      break;
                    }            
                }
            }
            else
            {
                if ($found = ($v === $needle))
                {
                    $result = $k;
                }
            }
    
            if ( $found == TRUE )
            {
                break;
            }
        }

        return $result;    
  }    
    
    
}


/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MVarDump
{
    /**
     * Attribute Description.
    */
    public $var;

    
    /**
     * Brief Description.
     * Complete Description.
     *
     * @param &$var (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function varDump(&$var)
    {
        $this->var =& $var;
    }
    
    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function generate()
    {
        echo "<b>Variable Dump:</b><br><br>\n";
        echo "<blockquote>\n";
        echo "<pre>\n";
        var_dump($this->var);
        echo "</pre>\n";
        echo "</blockquote>\n";
    }
}

/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MInvertDate
{
    /**
     * Attribute Description.
     */
    public $separator='/';

    /**
     * Attribute Description.
     */
	var $date;


    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $date (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
	function __construct($date=null)
	{
		$date = strstr($date,'-') ? str_replace('-', $this->separator, $date) : str_replace('.', $this->separator, $date);
		$this->date = $date;
		$this->formatDate();
	}

	Function FormatDate()
	{
		list($obj1, $obj2, $obj3) = split($this->separator, $this->date, 3);
		$this->date = $obj3 . $this->separator . $obj2 . $this->separator . $obj1;
		if ( ( $this->date == ($this->separator . $this->separator) ) )
			$this->date = 'Invalid Date!';
		return $this->date;
	}
}

// formata o valor conforme n casas decimais
/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MFormatValue
{
    /**
     * Attribute Description.
     */
	var $value;


    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $value (tipo) desc
     * @param $precision2 (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
	function __construct($value,$precision=2)
	{
		//$this->value = sprintf("%." . $precision . "f",$value);
		$this->value = number_format($value,$precision,',','.');
		return $this->value;
	}
}

/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MQuotedPrintable
{
    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $str (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function encode($str)
    {
        define('CRLF', "\r\n");
        $lines = preg_split("/\r?\n/", $str);
        $out     = '';
    
        foreach ($lines as $line)
        {

            $newpara = '';
        
            for ($j = 0; $j <= strlen($line) - 1; $j++)
            {
                $char = substr ( $line, $j, 1 );
                $ascii = ord ( $char ); 
            
                if ( $ascii < 32 || $ascii == 61 || $ascii > 126 ) 
                {
                     $char = '=' . strtoupper ( dechex( $ascii ) );
                }
            
                if ( ( strlen ( $newpara ) + strlen ( $char ) ) >= 76 ) 
                {
                    $out .= $newpara . '=' . CRLF;   $newpara = '';
                }
                $newpara .= $char;
            }
            $out .= $newpara . $char;
        }
        return trim ( $out );   
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $str (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function decode( $str ) 
    {
        $out = preg_replace('/=\r?\n/', '', $str);
        $out = preg_replace('/=([A-F0-9]{2})/e', chr( hexdec ('\\1' ) ), $out);
    
        return trim($out);
    }

}

/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MTreeArray
{
    /**
     * Attribute Description.
     */
    public $tree;


    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $ (tipo) desc
     * @param $group (tipo) desc
     * @param $node (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function __construct($array, $group, $node)
    { 
        $this->tree = array();
        if ($rs = $array)
        {
            $node = explode(',',$node);
            $group = explode(',',$group);
            foreach($rs as $row)
            {
                $aNode = array();
                foreach($node as $n) $aNode[] = $row[$n];
                $s = '';
                foreach($group as $g) $s .= '[$row[' . $g . ']]';
                eval("\$this->tree$s"."[] = \$aNode;");
            }
        }
    }
}

class MDummy
{
}
?>
