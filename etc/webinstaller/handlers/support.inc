<?php

if (function_exists('_'))
{
    $TEXTDOMAIN = 'miolo';
    //setlocale(LC_ALL, $MIOLOCONF['i18n']['language']);
    //bindtextdomain($TEXTDOMAIN, $MIOLOCONF['i18n']['locale']);
    
    //global $MIOLO;

    // user session to control language
    $language = 'en';

    setlocale(LC_ALL, $language);
    bindtextdomain($TEXTDOMAIN, $language);
    textdomain($TEXTDOMAIN);
}


function _M($msg, $dom = 'miolo', $p1 = null, $p2 = null, $p3 = null)
{
    global $TEXTDOMAIN, $MIOLO;

    if ($msg == '')
    {
        return $msg;
    }

    if (function_exists('_'))
    {
        if ($dom != $TEXTDOMAIN)
        {
            $TEXTDOMAIN = $dom;
            bindtextdomain($TEXTDOMAIN, $MIOLO->getConf('i18n.locale'));
            textdomain($TEXTDOMAIN);
        }

        $msg = _($msg);
    }

    if ($p1 !== null)
    {
        $msg = str_replace('@1', $p1, $msg);
    }

    if ($p2 !== null)
    {
        $msg = str_replace('@2', $p2, $msg);
    }

    if ($p3 !== null)
    {
        $msg = str_replace('@3', $p3, $msg);
    }

    return $msg;
}

function __autoload($className)
{
    global $autoload, $mioloClassesPath;

//    echo "<br/>autoload: $className";
    $className = strtolower($className);
    $file = $mioloClassesPath . '/' . $autoload->getFile($className);

    if ($file == '')
    {
        echo "className: $className not found!<br/>";
    }
    
    if ( file_exists($file) && is_file($file) )
    {
        include_once($file);
    }
    else
    {
        echo "<br/>File not found: $file";
    }
}

?>
