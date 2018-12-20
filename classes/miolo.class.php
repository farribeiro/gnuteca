<?php
define('MIOLO_VERSION','Miolo 2.5');
define('MIOLO_AUTHOR','Miolo Team');

define('OP_INS', 'INS');
define('OP_UPD', 'UPD');
define('OP_DEL', 'DEL');

require_once 'utils/msimplexml.class.php';
require_once 'utils/mconfigloader.class.php';
require_once 'services/mservice.class.php';
require_once 'services/mcontext.class.php';
require_once 'services/mrequest.class.php';
require_once 'services/mresponse.class.php';

//require_once 'utils/mrc4crypt.class.php';

/**
 * Brief Class Description.
 * Complete Class Description.
 */

class MIOLO
{
    public $_version;
    public $_author;

    /**
     * Attribute Description.
     */
    static private $instance = NULL;

    /**
     * remote tracing log message support
     */
    public            $trace_socket;

    /**
     * BD descriptor members
     */
    public            $db;

    /**
     * Attribute Description.
     */
    public            $user;

    /**
     * Attribute Description.
     */
    public            $pass;

    /**
     * Attribute Description.
     */
    public            $sqllog;

    /**
     * Attribute Description.
     */
    public            $errlog;

    /**
     * Other members
     */
    public            $theme;

    /**
     * Attribute Description.
     */
    public            $themepainter;

    /**
     * Attribute Description.
     */
    public            $themelayout;

    /**
     * Attribute Description.
     */
    public            $controlpainter;

    /**
     * Attribute Description.
     */
    public            $pagepainter;

    /**
     * Attribute Description.
     */
    public            $profile;

    /**
     * Attribute Description.
     */
    public            $uses;

    /**
     * Attribute Description.
     */
    public            $trace;

    /**
     * Attribute Description.
     */
    public            $error;

    /**
     * Attribute Description.
     */
    public            $page;

    /**
     * Attribute Description.
     */
    public            $context;
    public            $response;
    public            $request;

    /**
     * Attribute Description.
     */
    public            $auth;

    /**
     * Attribute Description.
     */
    public            $perms;

    /**
     * Attribute Description.
     */
    public            $session;

    /**
     * Attribute Description.
     */
    public            $state;

    /**
     * Attribute Description.
     */
    public            $logdb;

    /**
     * Attribute Description.
     */
    public            $dbconf = array();

    /**
     * Attribute Description.
     */
    public            $halted = false;

    public            $painter;

    public            $mad;

    public            $forward;

    public            $php;

    public            $ajax;
    public            $isAjaxCall = false;
    public            $isAjaxEvent = false;
    public          $formSubmit;

    /**
     * Constructor.
     * Miolo Class Constructor.
     */
    public function __construct()
    {
    }

	/* @var $MIOLO MIOLO */    
    /**
     * Returns Miolo instance.
     * This method returns an instance of the Miolo Class.
     *
     * @returns (object) Instance of Miolo class
     *
     */
    public static function getInstance()
    {
        if (self::$instance == NULL)
        {
            self::$instance = new MIOLO();
        }

        return self::$instance;
    }

    private function getObject($class, $param=NULL)
    {
        if ( is_null($this->$class) )
        {
            $className = 'M' . $class;
            $this->$class = new $className($param);
        }

        return $this->$class;
    }

    /**
     * Returns information about the king of the request.
     *
     * @return (bool) True if is is an Ajax call, otherwise False.
     */
    public function getIsAjaxCall()
    {
        return $this->isAjaxCall;
    }
    
    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function handlerRequest($forceInit = true)
    {
        // verificacao criada para que seja possivel carregar e alterar a configuracao antes desse metodo
        // isso foi necessario para a consulta externa do alfa ao gnuteca
        if ( $forceInit )
        {
            // Initialize some object's variable
            $this->initialize();
        }
        
        $this->context  = $this->getContext();
        
        if ($this->context->isFile)
        {
            $path = ($this->context->fileArea == 'reports') ? $this->GetConf('home.reports') : $this->getConf('home.modules') . '/' . $this->context->module . '/html/' . $this->context->fileArea;
            $fileName = $path . $this->context->fileName;
            $pathinfo = pathinfo($fileName);
            $ext = $pathinfo['extension'];
            if ($ext == 'tpl')
            {
                include ('utils/template.class.php');
                $tpl = new MTemplate($fileName);
                $this->sendText($tpl->text, $tpl->mimeType, $fileName);
            }
            elseif ($ext == 'php')
            {
                echo include($fileName);
            }
            else
            {
                $this->response->sendFile($fileName);
            }
        }
        else
        {
            require_once 'support.inc.php';

            try
            {
                ob_start();
                $this->init();
                do
                {
                    $this->prepare();
                    if (true)
                    {
                        $this->handler();
                    }
                    else
                    {
                        $this->page->onError('Invalid Token; Duplicated Submission');
                    }
                } while ($this->forward != '');
                $this->page->stdout = ob_get_contents();
                ob_end_clean(); 
                $this->terminate();
            }
            catch( EMioloException $e )
            {
                $msg = $e->getMessage();
                echo _M('Fatal error') . ": [$msg]";
            }
        }
    }
    
    /**
     * Initialize some variables.
     * Loads environment configuration, reads the resquest and get the context info. 
     */
    public function initialize()
    {
        $this->conf = new MConfigLoader();        
        $this->conf->loadConf();
        $this->request  = new MRequest();
        $this->response = new MResponse();
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $namespace (tipo) desc
     * @param $class' (tipo) desc
     *
     * @returns (tipo) desc
     *
     */

    public function getNamespacePath($namespace)
    {
        $m = MIOLO::getInstance();
        $path = $m->getConf('home.miolo');
        $ns = '';
        $tokens = explode('::', $namespace);

        foreach ($tokens as $token)
        {
            $ns .= (($ns != '') ? '.' : '') . $token;

            if ($ss = $m->getConf('namespace.' . $ns))
            {
                $path .= $ss;
            }
            elseif ($ss = $m->getConf('namespace.' . $token))
            {
                $path .= $ss;
            }
            else
            {
                $path .= '/' . $token;
            }
            $last = $token;
        }
        return $path;
    }

    public function import($namespace, $class = '', $extension = '.php')
    {
        $m = MIOLO::getInstance();
        $m->profileEnter('MIOLO::import');
//var_dump($namespace,$class,$extension);
//$this->getObject('trace')->tracestack();
        if ( array_key_exists($namespace, $m->import) )
        {
            $result = $m->import[$namespace];
        }
        else
        {
            $path = $m->getNamespacePath($namespace);
            $pathinfo = pathinfo($path);
            $path .= ($pathinfo['extension'] == '' ? '.class'.$extension : '');
            
            if ( $result = file_exists($path) )
            {
                $class = ($class != '') ? $class : $last;
                $m->autoload->setFile($class, $path);
                $m->import[$namespace] = $class;
                $result = $path;
            }
            else
            {
                $errmsg = _M('File not found: ').$path;
                $this->logMessage( $errmsg );
//                echo "MIOLO: $errmsg";
            }
        }
        $m->profileExit('MIOLO::import');
        return $result;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $home (tipo) desc
     * @param $logname=miolo' (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function init( $home = NULL, $logname = 'miolo')
    {
        global $autoload;

        include ( 'flow/mexception.class.php' );
        include ( 'utils/mxmltree.class.php' );
        include ( 'compatibility/mcompatibility.class.php' );
        include ( 'utils/mautoload.class.php' );

        $this->handlers = array();
        $this->uses     = array();
        $this->import   = array();
        $this->getObject('autoload');
        $autoload = $this->autoload;
        $this->setLog($logname);

        $this->logMessage('[RESET_LOG_MESSAGES]');
        $this->logMessage("URL: " . $this->getCurrentURL());

        $this->getObject('session');
        $this->session->start( $this->_REQUEST('sid') );

        if ($this->getConf('home.url') == NULL)
        {
            $this->SetConf('home.url', "http://{$_SERVER['HTTP_HOST']}");
        }
        
        $this->dispatch = $this->getConf('home.url') . '/' . $this->getConf('options.dispatch');
        
        if ($home)
        {
            $this->home = $home;
        }
        // wether to dump internal information or not
        $this->dumpping = $this->getConf('options.dump');

        // get the modules.inf
        require_once $this->getConf('home.modules') . '/modules.inc.php';

        // what is the MAD module?
        $this->mad = $this->getConf('mad.module');

        // what is the Miolo files extensions (.php or '')?
        $this->php = $this->getConf("options.fileextension") == '2' ? '' : '.php';

        // __FORMSUBMIT tells which form submited via ajax
        $this->formSubmit = self::_REQUEST('__FORMSUBMIT');

        // MAjax handlers Ajax 
        $this->ajax = new MAjax();
        // if it is a AJAX call, initialize mcpaint
        if (self::_REQUEST('__ISAJAXCALL') != '')
        {
            $this->trace("Ajax Call"); 
            $this->isAjaxCall = true;
            $this->isAjaxEvent = (self::_REQUEST('__ISAJAXEVENT') != '');
            $this->ajax->initialize('ISO-8859-1'); 
        }

        $this->getObject('history');
        $this->getObject('page');

        $this->loadExtensions();

        $this->persistence = new PersistentManagerFactory();
        $this->persistence->setConfigLoader('XML');
    }

    public function prepare()
    {

        $this->profileEnter('MIOLO::prepare');

        // getting the module.conf
        if (!is_null($this->context->module))
        {
            $this->conf->loadConf($this->context->module);
        }

/*
        if ($this->getConf('home.url') == NULL)
        {
            $this->getConf('home.url', "http://{$_SERVER['HTTP_HOST']}");
        }
*/

        // base module/handler
        $this->startup = $this->getConf('options.startup') != NULL ? $this->getConf('options.startup') : 'admin';

        if ($this->startup != $this->context->module)
        {
            if ($this->context->forceStartup)
            {
                $this->startup = $this->context->module;
            }
            $this->context->setStartup($this->startup);
            $this->conf->loadConf($this->startup);
        }

        if (($common = $this->getConf('options.common')) != NULL)
        {
            $this->conf->loadConf($common);
        }

        $this->forward = '';

        $this->getTheme();
        $this->getPainter();

        $this->profileExit('MIOLO::prepare');
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function handler()
    {
        $this->profileEnter('MIOLO::handler');
        try
        {
            $this->removeInputSlashes();
            $this->context->setStyle($this->getConf('options.url.style'));

            if ( $this->getConf('logs.handler') == 'screen' )
            {
                $this->page->addScript('m_error_handler.js');
            }

            $this->session->checkTimeout();
            if ($this->checkLogin())
			{
                if (!$this->isAjaxCall)
                {
                    $this->page->generateMethod = 'generateBase';
                }
                else
                {
                    $action = $this->context->getAction();
                    $handler = $action{0} == '_' ? substr($action,1) : 'main';
                    $this->invokeHandler($this->startup, $handler);
                }
			}

            if( $this->getConf('logs.handler') == 'screen' && $this->log->content )
            {
                echo "<script language=\"javascript\">".
                    $this->log->content.
                    "</script>";
            }
        }
        catch( EMioloException $e )
        {
            $msg = $e->getMessage();
//          $msg .= $e->getFile() . $e->getLine() . $e->getTraceAsString();
            $this->logMessage('[ERROR]' . $msg);
            $this->error($msg, $e->goTo, _M('Fatal error'));
        }
        $this->profileExit('MIOLO::handler');
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $module (tipo) desc
     * @param $action (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function invokeHandler($module, $action)
    {
        $this->trace("InvokeHandler: $module::$action");

        if ($return = ($action != NULL))
        {
            $handler = $this->getHandler($module);
            $return = $handler->dispatch($action);
        }
        return $return;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $module (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function getHandler( $module )
    {
        $this->trace( "getHandler: $module" );
        $this->profileEnter( 'MIOLO::getHandler' );
        $class = 'Handler' . ucfirst( strtolower( $module ) );

        if ( ( $handler = $this->handlers[$class] ) == NULL )
        {
            $file = 'handlers/handler.class' . $this->php;
            $this->uses( $file, $module );
            $handler = $this->handlers[$class] = new $class( $this, $module );
            $handler->init();
        }

        $this->profileExit('MIOLO::getHandler');

        return $handler;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function terminate()
    {
        $this->response->sendPage($this->page);
        $this->history->close();
        $this->session->freeze();
		$this->profileDump();
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $key (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function getConf($key)
    {
        return $this->conf->getConf($key);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $key (tipo) desc
     * @param $value (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setConf($key, $value)
    {
        $this->conf->setConf($key, $value);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $cond (tipo) desc
     * @param $msg' (tipo) desc
     * @param $goto='' (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function assert($cond, $msg = '', $goto = '')
    {
        if ($cond == false)
        {
            $this->logMessage('[ERROR]' . $msg);

            $this->error($msg, $goto, _M('Fatal error'));
        }
    }

    public function scramble($text)
    {
        $pwd = $this->getConf('options.scramble.password');
        $rc4 = new MRC4Crypt;
        $crypto = base64_encode($rc4->rc4($pwd,$text));
        $result = urlencode($crypto);
        return $result;
    }

    public function unScramble($text)
    {
        $pwd = $this->getConf('options.scramble.password');
        $rc4 = new MRC4Crypt;
        $crypto = urldecode($text);
        $result = $rc4->rc4($pwd,base64_decode($crypto));
        return $result;
    }

    public function removeInputSlashesValue($value)
    {
        if (is_array($value))
        {
            return array_map(array('MIOLO','removeInputSlashesValue'), $value);
        }
        return stripslashes($value);
    }

    public function removeInputSlashes()
    {
        if (get_magic_quotes_gpc()) // Yes? Strip the added slashes
        {
            $_REQUEST = array_map(array('MIOLO','removeInputSlashesValue'), $_REQUEST);
        }
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $url (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setDispatcher($url)
    {
        $this->dispatch = $url;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function getContext($url = '', $style = 0, $scramble = false)
    {
        if (is_null($this->context))
        {
            $this->context = new MContext($url,$style,$scramble);
        }
        return $this->context;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function getSession()
    {
        return $this->session;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function getAuth()
    {
        if (is_null($this->auth))
        {
            $class = strtolower($this->getConf('login.class'));
            if ($class == NULL)
            {
                $class = "mauthdb";
            }
            $this->import('classes::security::' . $class, $class);
            $this->auth = new $class();
        }
        return $this->auth;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function getPerms()
    {
        if ( is_null($this->perms) )
        {
            $class = $this->getConf('login.perms');

            if ( $class )
            {
                return $this->perms = new $class();
            }
        }

	return $this->getObject('perms');
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function getLogin()
    {
        return $this->getAuth()->getLogin();
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function getPage()
    {
        return $this->page;
    }

    public function loadExtensions()
    {
        $extensions = $this->getConf('extensions.extension');
        if ($extensions && (!is_array($extensions))) $extensions = array($extensions);
        $dir = $this->getConf('home.extensions');
        for($i = 0; $i < count($extensions); $i++)
        {
            $this->autoload->loadFile($dir . '/' . $extensions[$i] . '/autoload.xml');
        }
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $name (tipo) desc
     * @param $module (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function uses( $name, $module = NULL )
    {
        global $MIOLO;

        $this->profileEnter( 'MIOLO::uses' );

        // fazer nomes unicos por modulo
        $unique = ( $module != NULL ? $module : 'classes' ) . '::' . $name;

        if ( ! array_key_exists( $unique, $this->uses ) )
        {
            if ($module)
            {
                $path = $this->getModulePath( $module, $name );
            }
            else
            {
                $path = $this->getAbsolutePath( 'classes/' . $name );
            }

            if ( ! file_exists( $path ) )
            {
                throw new EUsesException( $path );
            }

            $this->uses[$unique] = array( $name, filesize($path) );

            include_once ( $path );

            $this->logMessage( '[USES] file:' . $path );
        }

        $this->profileExit( 'MIOLO::uses' );

        return true;
    }


    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $module (tipo) desc
     * @param $namemain' (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function usesBusiness($module, $name = 'main')
    {
        $this->profileEnter('MIOLO::usesBusiness');

        // compose the name of the class, wich must be defined in the file
        // ../modules/$module/db/$name.class.php
        $class = 'Business' .
                 strtoupper(substr($module,0,1)) . substr($module,1) .
                 strtoupper(substr($name,0,1)) . substr($name,1);
        if (!isset($this->usesBusiness[strtolower($class)]))
        {
        // try to open the file in the ../modules/$module/db dir (default) or
        // ../modules/$module/classes (only for compatibility purpose *don't use it*)
        // if the file doesn't exist raise exception, otherwise we'll
        // receive an eval error
           if ( ! ( $this->import('modules::' . $module . '::business::'. $name, $class, $this->php) ) )
           {
               throw new EUsesException($this->getConf('home.modules') . '/' . $module . "/db/$name.class.php ",  _M('Error in UsesBusiness: Class not Found! <BR>Class name: ') );
           }

           $class = strtolower($class);
           $this->usesBusiness[$class]['module'] = $module;
           $this->usesBusiness[$class]['name'] = $name;
        }
    }

    /**
     * @todo TRANSLATE
     *
     * Compõe um link (URL).
     * Este metodo compoe um link para uma URL no sistema.
     * <br>
     * @example
     * <code>
     * ...
     * $module = 'reports';
     * $main   = 'main:list_person';
     *
     * $handler = $MIOLO->getActionURL($module, $main);
     * ...
     * </code>
     * O exemplo acima retorna um link para o handler list_person.inc.php, no
     * modulo reports: http://nome_site/handler.php?module=reports&action=main:list_person
     *
     * @param $module (string) Nome do modulo que sera acessado
     * @param $action (string) Nome do handler (<code>.inc.php</code>) a ser acessado
     * @param $item   (string) Parametro adicional que pode ser utilizado
     *                         para passar dados para a nova pagina.
     * @param $args (string/array) Esse argumento pode ser utilizado para criar
     *        outras variaveis, alem das tres anteriores (que sao padrao do MIOLO).
     *        Quando for informado um array, o <code>key</code> sera o nome da variavel atraves
     *        do qual o conteudo podera ser acessado.
     * @param $dispatch (string) Indica qual arquivo devera ser utilizado
     *        ao inves daquele configurado no miolo.conf:
     *        <code>$MIOLOCONF['options']['dispatch']</code>
     * @param $scramble (boolean) Indica se o link deve ser
     *
     * @returns (string) o link para uma URL
     *
     */
    public function getActionURL($module = '', $action = 'NONE', $item = '', $args = NULL, $dispatch = NULL, $scramble = false)
    {
        if ( is_object( $module ) )
        {
            $obj = clone( $module );
            $action = $obj->action;
            $item   = $obj->item;
            $args   = $obj->args;
            $dispatch = $obj->dispatch;
            $scramble = $obj->scramble;

            $module = $obj->module;
        }

        if (is_null($dispatch))
        {
            $dispatch = $this->dispatch;
        }
        $amp = '&amp;';
        if ($item)
        {
            $qs = $amp . "item=$item";
        }
        if (is_array($args))
        {
            foreach ($args as $key => $value)
            {
                $qs .= $amp . "$key=".$value;
            }
        }
        $url = $this->context->composeURL($dispatch,$module,$action, $qs,$scramble);

        return $url;
    }

    /**
     * Gets physical filesystem path of $rel (relative filename)
     */
    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $rel (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function getAbsolutePath($rel = NULL, $module = NULL)
    {
        $path = $module ? $this->getConf('home.modules') . "/$module" : $this->getConf('home.miolo');

        if ($rel)
        {
            // prepend path separator if necessary
            if (substr($rel, 0, 1) != '/')
            {
                $path .= '/';
            }

            $path .= $rel;
        }

        return $path;
    }

    /**
     * Gets absolute virtual path of $rel (relative filename) from browser's address
     */
    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $rel (tipo) desc
     * @param $module (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function getAbsoluteURL($rel, $module = NULL)
    {
        global $MIOLOCONF;

        if ($module)
        {
            $url = $this->getConf('home.url') . '/modules/' . $module;
        }
        else
        {
            //            $url = $MIOLOCONF['home']['url'] . '/miolo';
            $url = $this->getConf('home.url');
        }

        // prepend path separator if necessary
        if (substr($rel, 0, 1) != '/')
        {
            $url .= '/';
        }

        $url .= $rel;

        return $url;
    }

    /**
     * Gets absolute virtual path of $rel for selected theme
     */
    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $rel (tipo) desc
     * @param $name (tipo) desc
     * @param $default=NULL (tipo) desc
     * @param $module=NULL (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function getThemeURL($rel, $name = NULL, $default = NULL, $module = NULL)
    {
        global $MIOLOCONF;

        if (substr($rel, 0, 1) == '/')
        {
            return $rel;
        }

        if (!$name)
        {
            $name = $this->theme->getId();
        }

        if (!$module)
        {
            if (($module = $this->theme->getModule()) == NULL)
                $module = 'miolo';
        }

        $url = $this->getAbsoluteURL('themes/' . $name . '/' . $rel);

        return $url;
    }

    /**
     * Gets the physical filesystem path of the module's file
     */
    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $module (tipo) desc
     * @param $file (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function getModulePath($module, $file)
    {
        $path = $this->getConf('home.modules') . '/' . $module;

        if (substr($file, 0, 1) != '/')
        {
            $path .= '/';
        }

        $path .= $file;
        return $path;
    }

    /**
     * Return current URL.
     * Returns the URL address of the current page.
     *
     * @returns (string) URL address
     *
     */
    public function getCurrentURL() //static
    {
        $m = MIOLO::getInstance();
        if ( ! ($url = $m->context->url) )
        {
            $url = $m->getConf('home.url') . '/' . $m->getConf('options.dispatch');
        }
        return $url;
    }

    /**
     * Return previos URL, based on previous action
     * Returns the URL address of the previous action page
     *
     * @returns (string) URL address
     *
     */
    public static function getPreviousURL()
    {
        $MIOLO = MIOLO::getInstance();
        $context = $MIOLO->getContext();
        $url = $context->composeUrl('','',$context->getPreviousAction());
        return $url;
    }


    /**
     * Return current module.
     * Return the name of the current module
     *
     * @returns (string) module name
     */
    public static function getCurrentModule()
    {
        $uri = $_SERVER['REQUEST_URI'];
        $pos1 = strpos($uri, 'module=') + 7;
        $pos2 = strpos($uri, '&', $pos1);

        return substr($uri, $pos1, $pos2 - $pos1);
    }

    /**
     * Return current action.
     * Return the name of the current action
     *
     * @returns (string) module name
     */
    public static function getCurrentAction()
    {
        $uri = $_SERVER['REQUEST_URI'];
        $pos1 = strpos($uri, 'action=') + 7;
        $pos2 = strpos($uri, '&', $pos1);

        if ( $pos2 == 0 )
        {
            $pos2 = strlen($uri);
        }

        return substr($uri, $pos1, $pos2 - $pos1);
    }

    /**
     * @todo TRANSLATION
     * Retorna
     * O metodo _REQUEST provê uma forma simples e rápida para se ter acesso às 
     * variáveis, além de garantir a compatibilidade com versões futuras do PHP.
     * Utilizando comandos PHP, seria necessário utilizar $_REQUEST, $_GET, $_POST 
     * ou global ao passo este método possibilita, além da busca num, a busca em
     * todas as informacoes.
     * Caso você queira obter apenas o valor da variáveis provenientes de
     * uma dessas opcoes, por exemplo GET, passe essa palavra como segundo
     * parâmetro.
     *
     * @param (mixed) $vars String ou array: variáveis das quais se deseja obter o valor
     * @param (string) $from De onde obter os dados. Pode ser 'GET', 'POST',
     *                       'SESSION', 'REQUEST' além do padrão 'ALL' que 
     *                       retorna todos os dados.
     * @param (string) $order Onde pesquisar primeiro POST ou GET. Por padrão a 
     *                        pesquisa é feita de acordo com a configuração do php.ini .
     *                        Para forçar a ordem, informe "PG" ou "GP" (P=post, G=get)
     *
     * @return (array) Os valores das variáveis solicitadas
     */
    public static function _REQUEST( $vars, $from = 'ALL', $order='' )
    {
        if ( is_array($vars) )
        {
            foreach ( $vars as $v )
            {
                $values[$v] = self::_REQUEST($v, $from);
            }

            return $values;
        }
        else
        {
            // Seek in all scope?
            if ( $from == 'ALL')
            {
                // search in REQUEST
                if ( ! isset($value) )
                {
                    $value = $_REQUEST["$vars"];
                }

                // Not found in REQUEST? try GET or POST
                // Order? Default is use the same order as defined in php.ini ("EGPCS")
                if ( ! isset($order) )
                { 
                    $order = ini_get('variables_order');
                }

                if ( ! $value && $value !== '0' )
                {
                    if ( strpos($order, 'G') < strpos($order, 'P') )
                    {
                        $value = $_GET["$vars"];
                        
                        // If not found, search in post
                        if ( ! $value && $value !== '0' )
                        {
                            $value = $_POST["$vars"];
                        }   
                    }
                    else
                    {
                        $value = $_POST["$vars"];
                        
                        // If not found, search in get
                        if ( ! $value && $value !== '0' )
                        {
                            $value = $_GET["$vars"];
                        }
                    }
                }
                
                // If we still didn't have the value
                // let's try in the global scope
                if ( ( ! $value && $value !== '0' ) && ( ( strpos($vars, '[') ) === false) )
                {
                    $value = $_GLOBALS["$vars"];
                }
    
                // If we still didn't has the value
                // let's try in the session scope
    
                if ( ! $value && $value !== '0' )
                {
                    $value = $_SESSION["$vars"];
                }                
            }
            else if ( $from == 'GET' )
            {
                $value = $_GET["$vars"];
            }
            elseif ( $from == 'POST' )
            {
                $value = $_POST["$vars"];
            }
            elseif ( $from == 'SESSION' )
            {
                $value = $_SESSION["$vars"];
            }
            elseif ( $from == 'REQUEST' )
            {
                $value = $_REQUEST["$vars"];
            }

            return $value;
        }
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function getSysTime($format = 'd/m/Y H:i:s')
    {
        return date($format);
    }

    public function getSysDate($format = 'd/m/Y')
    {
        return date($format);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function checkLogin()
    {
        return $this->getAuth()->checkLogin();
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $trans (tipo) desc
     * @param $access (tipo) desc
     * @param $deny (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function checkAccess($trans, $access, $deny = false)
    {
        return $this->getObject('perms')->checkAccess($trans, $access, $deny);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function isHostAllowed()
    {
        global $MIOLOCONF;

        $REMOTE_ADDR = $_SERVER['REMOTE_ADDR'];
        $returnValue = false;

        foreach ($MIOLOCONF['hosts']['allow'] as $h)
        {
            if ($REMOTE_ADDR == $h)
            {
                $returnValue = true;
            }

            // Is it a interval of IP's?
            if ((strpos($h,
                        '-') > 0) && (substr($h, 0,
                                             strrpos($h, '.')) == substr($REMOTE_ADDR, 0, strrpos($REMOTE_ADDR, '.'))))
            {
                list($firstIP, $lastIP) = explode('-', $h);
                $lastIP = substr($firstIP, 0, strrpos($firstIP, '.') + 1) . $lastIP;

                $remoteIP = substr($REMOTE_ADDR, strrpos($REMOTE_ADDR, '.') + 1, strlen($REMOTE_ADDR));
                $startIP = substr($firstIP, strrpos($firstIP, '.') + 1, strlen($firstIP));
                $endIP = substr($lastIP, strrpos($lastIP, '.') + 1, strlen($lastIP));

                if (($startIP < $remoteIP) && ($endIP > $remoteIP))
                {
                    $returnValue = true;
                }
            }
        }

        foreach ($MIOLOCONF['hosts']['deny'] as $h)
        {
            if ($REMOTE_ADDR == $h)
            {
                $returnValue = false;
            }
        }

        return $returnValue;
    }

    //
    // Factories Methods
    //     GetDatabase
    //     GetBusiness
    //     GetUI
    //     GetTheme
    //
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Este método é utilizado para criar uma conexão com a base de dados
    # especificada no parâmetro <code>$conf</code>.
    # A configuração da base deve ter sido previamente criada no arquivo
    # de configuração do MIOLO: miolo.conf
    #
    # @param $conf (string) Nome da configuração, definida no miolo.conf
    # @param $user (string) (optional) Nome do usuário para conectar à base
    #        de dados
    # @param $pass (string) (optional) Senha para acesso à base.
    #
    # @see #MIOLO::getBusiness, miolo/database.class.php
    #---------------------------------------------------------------------
    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $conf (tipo) desc
     * @param $user=NULL (tipo) desc
     * @param $pass=NULL (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function getDatabase($conf = NULL, $user = NULL, $pass = NULL)
    {
        global $MIOLOCONF;

        $this->profileEnter('MIOLO::getDatabase');

        if (isset($this->dbconf[$conf]))
        {
            $db = $this->dbconf[$conf];
            if ($db->status == 'close')
            {
                $db->open();
            }
        }
        else
        {
            try
            {
                if (!$conf)
                {
                    $conf = $this->db;
                }

                if (!$conf)
                {
                    $this->traceStack();
                    throw new EDatabaseException($conf,"Database configuration missing in miolo.conf!");
                }

                $db_host = $this->getConf("db.$conf.host");
                $db_name = $this->getConf("db.$conf.name");
                $db_system = $this->getConf("db.$conf.system");
                $db_persistent = (bool)$this->getConf("db.$conf.persistent");
                $db_jdbc_driver = $this->GetConf("db.$conf.jdbc_driver");
                $db_jdbc_db = $this->GetConf("db.$conf.jdbc_db");

                if ($this->getConf('login.shared'))
                {
                    $db_user = $this->getConf("db.$conf.user");

                    $this->conf->loadConf('','../etc/passwd.conf');

                    $db_pass = $this->getConf("db.$conf.password");

                    if (!(isset($db_user) && isset($db_pass)))
                    {
                        throw new EDatabaseException($conf,"Configuration in miolo.conf is missing login for this database!");
                    }
                }
                else
                {
                    $db_user = $user ? $user : $this->login->id;
                    $db_pass = $pass ? $pass : $this->login->password;
                }

                $db = new MDatabase($conf, $db_system, $db_host, $db_name, $db_user, $db_pass, $db_persistent,'','', $db_jdbc_driver, $db_jdbc_db);
                $this->dbconf[$conf] = $db;
            }
            catch( Exception $e )
            {
                throw $e;
            }
        }

        // $this->dump(array($db_host,$db_name,$db_user,$db_pass,$this->login),__FILE__,__LINE__);
        $this->profileExit('MIOLO::getDatabase');
        return $db;
    }

    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    #
    # @see miolo/miolo.class#MIOLO::getDatabase,
    #      miolo/ui/form.class#Form::getData
    #---------------------------------------------------------------------
    /**
     * Método para acessar funções do banco de dados
     * Como o MIOLO é capaz de abrigar módulos diferentes, era preciso
     * adotar um esquema para evitar possíveis colisões de nomes de classes.
     * Teoricamente dois modulos poderiam definir uma classe, por exemplo,
     * 'Guestbook' que, utilizada simultaneamente, causaria problemas.
     * <br><br>
     * O MIOLO espera que classes do tipo 'Business' tenham o seu nome composto
     * de 'Business' + 'nome do module' + 'nome da classe'. Mas para evitar
     * redundâncias adotou-se o padrão de somente usar o nome básico da classe
     * para definir o nome do arquivo, já que o mesmo se encontra dentro da estrutura
     * de diretórios do módulo em questão.
     *
     * @example
     * <i> in file: ../modules/foo/db/guestbook.class.php </i>
     * &lt;?
     *
     * class BusinessFooGuestbook extends Business
     * {
     *    function addVisitor($data)
     *    {
     *           ...
     * ?&gt;
     * <hr>
     * <i> in file: ../modules/foo/handlers/register.inc.php </i>
     * &lt;?
     *
     * $guestbook = $MIOLO->getBusiness( 'foo', 'guestbook' );
     * $data = $form->getData();
     * result = $guestbook->addVisitor( $data );
     *
     * ?&gt;
     *
     *
     * @param $module (string) nome do módulo
     * @param $namemain' (tipo) desc
     * @param $data= (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function getBusiness($module, $name = 'main', $data = NULL)
    {
        $this->profileEnter('MIOLO::getBusiness');

        $path = $this->getModulePath($module, 'types.class' . $this->php);

        if( file_exists($path) )
        {
            $this->uses('types.class' . $this->php, $module);
        }

        // compose the name of the class, wich must be defined in the file
        // ../modules/$module/db/$name.class.php
        $class = 'Business' .
                 strtoupper(substr($module,0,1)) . substr($module,1) .
                 strtoupper(substr($name,0,1)) . substr($name,1);

        // try to open the file in the ../modules/$module/db dir (default) or
        // ../modules/$module/classes (only for compatibility purpose *don't use it*)
        // if the file doesn't exist raise exception, otherwise we'll
        // receive an eval error
        if ( ! $this->import('modules::' . $module . '::business::'. $name, $class, $this->php) )
//        if ( ! ( $this->import('modules::' . $module . '::db::'. $name, $class, $this->php) ||
//                 $this->import('modules::' . $module . '::classes::'. $name, $class, $this->php) )
//           )
        {
            throw new EBusinessException( _M('Error in getBusiness: Class not Found! <BR>Class name: ') . $class . '<BR/><BR/>This class should exist in file ' . $this->getConf('home.modules') . '/' . $module . "/db/$name.class" . $this->php);
        }

        // instanciate a new class
        $business = new $class($data);
        $business->_bmodule = $module;
        $business->_bclass  = $name;
        $business->onCreate($data);
        $this->profileExit('MIOLO::getBusiness');

        return $business;
    }

    public function getBusinessMAD($name = 'main', $data = NULL)
    {
        $class = $this->getConf('mad.classes.' . $name);

        // get access to the mad module cnofiguration
        $this->loadMADConf();

        return $this->getBusiness($this->mad, $class, $data);
    }

    public function loadMADConf()
    {
        $this->conf->loadConf( $this->mad );
    }

    /**
     *
     */
    public function getClass($module,$name)
    {
        $this->uses("/classes/$name.class.php", $module);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function getUI()
    {
        return $this->getObject('ui');
    }

    public function getWebServices( $module, $name, $data = NULL, $dir = NULL )
    {
        $file = is_null($dir) ? "webservices/$name.class.php" : "webservices/$dir/$name.class.php";

        $path = $this->getModulePath( $module, $file );

        if ( file_exists( $path ) )
        {
            $this->uses( $file, $module );
            $className = $name;
            $webservice = new $className( $data );

            return $webservice;
        }
        else
        {
            throw new EFileNotFoundException( $file, "UI::getWebService() :" );
        }
    }
    
    
    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $themeId' (tipo) desc
     * @param $layout='default' (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function getTheme($themeId = '', $layout = 'default')
    {

        $this->profileEnter('MIOLO::getTheme');

        if ($themeId == '')
        {
            $themeId = $this->getConf('theme.main');
        }
        if (($tl = self::_REQUEST('themelayout')) != '')
        {
            $layout = $tl;
        }
        if (is_object($this->theme))
        {
            // $this->theme already exists... is the same id?
            if ( $this->theme->getId() == $themeId )
            {
                return $this->theme;
            }
        }
        $themeTitle = $this->getConf('theme.title');
        $class = 'Theme' . $themeId;
        $module = $this->getConf('theme.module');
        $namespace = ($module != '') && ($module != 'miolo')
                     ? 'modules::' . $module . '::themes::' . $themeId . '::theme'
                     : 'themes::' . $themeId . '::theme';
        $path = $this->import($namespace, $class);
        $this->theme = new $class($themeId,$module);
        $this->theme->setLayout($layout);
        $this->theme->setPath(dirname($path));
        $this->theme->init();
        $this->profileExit('MIOLO::getTheme');

        return $this->theme;
    }

    public function getPainter()
    {
        if ( is_null($this->painter) )
        {
            $this->painter = new MHtmlPainter();
        }

        return $this->painter;
    }

    //
    //

    /**
     * Dialogs and Error Handling
     * Dialogs and Error Handling
     *     Error
     *     Information
     *     Confirmation
     *     Question
     *     Prompt
     *
     * @param $msg' (tipo) desc
     * @param $goto='' (tipo) desc
     * @param $caption='' (tipo) desc
     * @param $event='' (tipo) desc
     * @param $halt= (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function error($msg = '', $goto = '', $caption = '', $event = '', $halt = true)
    {
        $this->prompt(MPrompt::error($msg, $goto, $caption, $event), $halt);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $msg (tipo) desc
     * @param $goto' (tipo) desc
     * @param $event='' (tipo) desc
     * @param $halt= (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function information($msg, $goto = '', $event = '', $halt = true)
    {
        $this->prompt(MPrompt::information($msg, $goto, $event), $halt);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $msg (tipo) desc
     * @param $gotoOK' (tipo) desc
     * @param $gotoCancel='' (tipo) desc
     * @param $eventOk='' (tipo) desc
     * @param $eventCancel='' (tipo) desc
     * @param $halt= (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function confirmation($msg, $gotoOK = '', $gotoCancel = '', $eventOk = '', $eventCancel = '', $halt = true)
    {
        $this->prompt(MPrompt::confirmation($msg, $gotoOK, $gotoCancel, $eventOk, $eventCancel), $halt);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $msg (tipo) desc
     * @param $gotoYes' (tipo) desc
     * @param $gotoNo='' (tipo) desc
     * @param $eventYes='' (tipo) desc
     * @param $eventNo='' (tipo) desc
     * @param $halt= (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function question($msg, $gotoYes = '', $gotoNo = '', $eventYes = '', $eventNo = '', $halt = true)
    {
        $this->prompt(MPrompt::question($msg, $gotoYes, $gotoNo, $eventYes, $eventNo), $halt);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $prompt (tipo) desc
     * @param $halt (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function prompt($prompt, $halt = true)
    {
        $spacer = new MSpacer();
        $this->theme->insertContent($spacer);
        $this->theme->insertContent($prompt);
        $this->theme->setHalted($halt);
    }

    public function dialogPrompt($dlgPrompt)
    {
        $link = $dlgPrompt->getLink();
        $this->page->onLoad($link);
    }

    //
    // Log, Trace, Dum, Profile
    //
    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $logname (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setLog($logname)
    {
        $this->getObject('log')->setLog($logname);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $sql (tipo) desc
     * @param $force (tipo) desc
     * @param $conf= (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function logSQL($sql, $force = false, $conf = '?')
    {
        $this->getObject('log')->logSQL($sql, $force, $conf);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $error (tipo) desc
     * @param $conf (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function logError($error, $conf = 'miolo')
    {
        $this->getObject('log')->logError($error, $conf);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function profileTime()
    {
        return $this->getObject('profile')->profileTime();
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $name (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function profileEnter($name)
    {
        return $this->getObject('profile')->profileEnter($name);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $name (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function profileExit($name)
    {
        return $this->getObject('profile')->profileExit($name);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function profileDump()
    {
        return $this->getObject('profile')->profileDump();
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function getProfileDump()
    {
        return $this->getObject('profile')->getProfileDump();
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function usesDump()
    {
        return $this->getObject('dump')->usesDump();
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $var (tipo) desc
     * @param $file (tipo) desc
     * @param $line=false (tipo) desc
     * @param $info=false (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function dump($var, $file = false, $line = false, $info = false)
    {
        return $this->getObject('dump')->dump($var, $file, $line, $info);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function isLogging()
    {
        return $this->getObject('log')->isLogging();
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $msg (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function logMessage($msg)
    {
        return $this->getObject('log')->logMessage($msg);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $msg (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function deprecate($msg)
    {
        $this->logMessage('[DEPRECATED]' . $msg);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $msg (tipo) desc
     * @param $file (tipo) desc
     * @param $line=0 (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function trace($msg, $file = false, $line = 0)
    {
        return $this->getObject('trace')->trace($msg, $file, $line);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function traceDump()
    {
        return $this->getObject('trace')->traceDump();
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function traceStack()
    {
        return $this->getObject('trace')->traceStack();
    }
    //
    // Files methods
    //     GetThemes
    //     ListFiles
    //
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Returns a array with the existing themes
    #---------------------------------------------------------------------
    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function getThemes()
    {
        global $MIOLOCONF;

        $themes = MIOLO::listFiles($MIOLOCONF['home']['themes'] . "/");

        ksort ($themes);
        reset ($themes);

        return ($themes);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $dir (tipo) desc
     * @param $typed' (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function listFiles($dir, $type = 'd')
    {
        $result = '';
        if (is_dir($dir))
        {
            $thisdir = dir($dir);

            while ($entry = $thisdir->read())
            {
                if (($entry != '.') && ($entry != '..') && (substr($entry, 0, 1) != '.'))
                {
                    if ($type == 'a')
                    {
                        $result[$entry] = $entry;
                        next;
                    }

                    $isFile = is_file("$dir$entry");
                    $isDir = is_dir("$dir$entry");

                    if (($type == 'f') && ($isFile))
                    {
                        $result[$entry] = $entry;
                        next;
                    }

                    if (($type == "d") && ($isDir))
                    {
                        $result[$entry] = $entry;
                        next;
                    }
                }
            }
        }

        return $result;
    }

    /**
     * Send a file to client
     * @param string $module Module
     * @param string $filename Complete filepath relative to directory "files" on module dir
     */
    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $module' (tipo) desc
     * @param $filename (tipo) desc
     * @param $dir='html (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function saveFile($module = '', $filename='', $dir = 'html/files/')
    {
        if (empty($filename))
        {
            return false;
        }

        $this->profileEnter('MIOLO::saveFile');
        $this->trace(">>ENTERING: MIOLO::saveFile($module,$filename)");
        $path = $this->getModulePath($module, $dir);
        $this->response->sendDownload($path . $filename);
        $this->profileExit('MIOLO::saveFile');
    }

     /**
     * Generates a formatted var_dump output.
     * This method uses Kwaku Otchere's dBug.class.php which dumps/displays the contents of a variable in a
     * colored tabular format based on the idea, javascript and css code of Macromedia's ColdFusion cfdump tag
     * <br>
     * @example
     * <code>
     * ...
     * MIOLO::vd( $varName );
     * MIOLO::vd( $myVariable, 'array');
     * ...
     * </code>
     *
     * $myVariable will be treated and dumped as an array type,
     * even though it might originally have been a string type, etc.
     * NOTE! $forceType is REQUIRED for dumping an xml string or xml file
     * <code>MIOLO::vd( $strXml, "xml" );</code>
     *
     * @param $variable (string) Variable to be shown
     * @param $forceType (string) Optional string, if is given, the variable supplied to the
     *        function is forced to have that forceType type.
     *
     * @returns (string) nothing
     *
     */
    public static function vd($variable, $forceType=null)
    {
        include_once('contrib/dbug.class.php');

        if ( $forceType != null )
        {
            new dBug($variable);
        }
        else
        {
            new dBug($variable, "$forceType");
        }

    }

    /**
     * Alias to MIOLO::vd.
     * This method calls MIOLO::vd
     *
     * @see vd
     */
    public static function var_dump($variable, $forceType=null)
    {
        self::vd($variable, $forceType);
    }

    public static function updateLoading($value)
    {
        // temporarily not available
        return;

        echo '<SCRIPT LANGUAGE="javascript">';
        echo 'document.getElementById("loading").innerHTML = "'.$value.'"';
        echo '</SCRIPT>';
        flush();
    }

    public function getRequiredJS4Ajax()
    {
        $this->page->addScript('x/x_core.js');
        $this->page->addScript('cpaint/cpaint.inc.js');
        $this->page->addScript('datepicker/calendar.js');
        $this->page->addScript('datepicker/lang/calendar-pt-br.js');
        $this->page->addScript('datepicker/calendar-setup.js');

        $styleURL = $this->getAbsoluteURL('scripts/datepicker/css/calendar-win2k-1.css');
        $this->page->addStyleURL($styleURL);
    }

    public function tokenOk()
    {
        $ok = true;
        $t1 = $this->_request('__MIOLOTOKENID','REQUEST');
        if ($t1 != '')
        {
            $t2 = $this->getSession()->get('__MIOLOTOKENID');
            $ok = ($t1 == $t2);
            $this->getSession()->set('__MIOLOTOKENID',md5(uniqid()));
        }
        return $ok;
    }

}
?>
