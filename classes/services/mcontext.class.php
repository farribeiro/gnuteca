<?php
class MContext extends MService
{
    const   DISPATCH = 1;
    const   MODULE = 3;
    const   ACTION = 5;
    const   DELIMITER = 6;
    const   TYPE = 7;

    public  $startup;
    public  $module;
    public  $action;
    public  $item;
    private $actionTokens;
    private $currentToken;
    private $path;
    private $queryString;
    private $vars;
    private $host;
    private $dispatch = 'index.php';
    public  $style; // 0 - old; 1 = new without rewrite; 2 = new with rewrite
    public  $isFile;
    public  $isRoot;
    public  $fileName;
    public  $fileArea;
    public  $fileType;
    public  $scramble;
    public  $url;
    public  $forceStartup;
    

    public function __construct($url = '', $style = 0, $scramble = false)
    {
        parent::__construct();
        if (empty($url))
        {
            $httpHost    = $_SERVER['HTTP_HOST'];
            $scriptName  = $_SERVER['SCRIPT_NAME'];
            $pathInfo    = $_SERVER['PATH_INFO'];
	    $queryString = $_SERVER['QUERY_STRING'];
	    $protocol    = $_SERVER['HTTPS'] == 'on' ? 'https' : 'http';
            $url = "$protocol://$httpHost$scriptName$pathInfo";
            if ($queryString != '')
            {
                $url .= "?{$queryString}";
            }
	}
	// adicionado para caso da consulta externa feita pelo Alfa, o qual usa gnutecaConsulta.php para entrada
        $MIOLO = MIOLO::getInstance();
	$this->dispatch = $MIOLO->getConf('options.dispatch');

        $this->style    = (int)$style;
        $this->scramble = (bool)$scramble;
        if (strpos($url,'MIOLO_URI'))
        {
             $url = $this->parseScramble($url);
        }
        $this->parseUrl($url);
    }

    private function parseScramble($url)
    {
        global $MIOLO;
        $urlParts = parse_url($url);
        parse_str($urlParts['query'], $this->vars);
        $url = preg_replace('/\?MIOLO_URI=.*/',$MIOLO->unScramble($this->vars['MIOLO_URI']), $url);
        return $url;
    }

    public function parseUrl($url)
    {
        $this->url = $url;
        $url = str_replace('&amp;', '&', $url);
        $urlParts = parse_url($url);
        $this->path = $urlParts['path'];
        $this->host = 'http://' . $urlParts['host'] . ($urlParts['port'] != '' ? ':' . $urlParts['port'] : '');
        if (($this->queryString = $urlParts['query']) != '')
        {
             parse_str($this->queryString, $this->vars);
        }
        if (($this->path != "/{$this->dispatch}") || ($this->queryString != ''))
        {
            $this->style = (strpos($url, 'module') ? 0 : 1);
            $this->parseURI();
        }
    }

    private function parseURI()
    {
        $uri = trim($this->path) . (($this->queryString != '') ?  '?' . $this->queryString : '');
        $regexp = ($this->style == 0) ? 
"\/({$this->dispatch})(\?)module=([^&]*)(&?action=([^&.]*)(&|\.|$)(.*)|$)" :
"\/({$this->dispatch})(/?)([^\/]*)(/([^&.]*)(&|\.|$)(.*)|$)";
        $this->isFile = false;
        if (ereg($regexp, $uri, $parts))
        {
            $this->dispatch = $parts[self::DISPATCH];
            $this->module = $parts[self::MODULE];
            $this->startup = $parts[self::MODULE];
            $this->action = str_replace('/',':', $parts[self::ACTION]);
            $this->delimiter = $parts[self::DELIMITER];
            $this->fileType = $parts[self::TYPE];
            $this->getTokens();
            $this->item = $this->vars['item'];
            $this->forceStartup = $this->vars['_startup'];
        }
        else
        {
            die ("Context: Invalid URL (regexp) : $uri");
        }
    }

    private function getTokens()
    {
            $this->actionTokens = explode(':', $this->action);
            $this->currentToken = 0;

            if ($this->delimiter == '.')
            {
                $this->fileArea = array_shift($this->actionTokens);
                $fileName = array_pop($this->actionTokens);

                if ($fileName != NULL)
                {
                    $this->isRoot = ($this->module == 'miolo');
                    $this->isFile = true;
                    $path = implode('/', $this->actionTokens);
                    $this->fileName = ($path != '' ? '/' . $path . '/' : '/') . $fileName . '.' . $this->fileType;
                }
                else
                {
                    die ("Context: Invalid FileName : {$this->action}");
                }
            }
    }

    public function setStartup($value)
    {
        $this->startup = $value;
    }

    public function setStyle($value = 0)
    {
        $this->style = $value;
    }

    public function getStyle()
    {
        return $this->style;
    }

    public function getModule()
    {
        return $this->module;
    }

    public function getAction($index = 0)
    {
        $action = ($index >= 0) && ($index < count($this->actionTokens)) ? $this->actionTokens[$index] : NULL;

        return $action;
    }

    public function getVar($name)
    {
        return $this->vars[$name];
    }

    public function getVars()
    {
        return $this->vars;
    }

    public function shiftAction()
    {
        do {
           $action = $this->currentToken < count($this->actionTokens) ? $this->actionTokens[$this->currentToken++] : NULL;
        } while (($action == 'main') && ($this->module == $this->startup)); // 'main' is always duplicated actions...
        return $action;
    }

    public function pushAction($a)
    {
        if ($this->action)
            $this->action .= '/';

        $this->action .= $a;

        $this->actionTokens = explode('/', $this->action);
        $this->currentToken = 0;
    }

    public function composeURL($dispatch = '', $module = '', $action = '', $args = '', $scramble = false)
    {
        global $MIOLO;

        $dispatch = ($dispatch == '') ? $this->dispatch : $dispatch;
        $module = ($module == '') ? $this->module : $module;
        $action = ($action == '') ? (($this->action == '') ? 'main' : $this->action) : $action;

        $amp = '&amp;';
        if ($this->style)
        {
            $action = str_replace(':', '/', $action);
            $url = "/$module/$action" . ($args ? '?' . $args : '');
        }
        else
        {
            $url = "?module=$module" . $amp . "action=$action" . $args;
        }

        if ($this->scramble || $scramble)
        {
            $url = "$dispatch?MIOLO_URI=" . $MIOLO->scramble($url);
        }
        else
        {
            $url = "$dispatch" . $url;
        }
        return $url;
    }
    
    public function getPreviousAction()
    {
        $tokens = explode(':',$this->action);
        unset($tokens[sizeof($tokens)-1]);
        return implode(':',$tokens);
    }

    public function inDomain()
    {
        $url = $this->manager->getConf('home.url');
        return ($url == $this->host); 
    }
                                
}
?>
