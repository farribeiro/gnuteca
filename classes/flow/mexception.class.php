<?
class EMioloException extends Exception
{
    public $goTo;
    protected $manager;

    public function __construct()
    {
        global $MIOLO;

        $this->manager = $MIOLO;
        $this->goTo = $this->manager->history->back('action'); 
    }

    public function log()
    {
        $this->manager->logError($this->message);
    }
}

class EInOutException extends EMioloException
{
}

class EDatabaseException extends EMioloException
{
    public function __construct($db, $msg)
    {
        parent::__construct();
        $this->message = _M('Error in Database [@1]: @2', 'miolo', $db, $msg);
        $this->log();
    }
}

class EDatabaseExecException extends EMioloException
{
    public function __construct($msg)
    {
        parent::__construct();
        $this->message = $msg;
    }
}

class EDatabaseQueryException extends EMioloException
{
    public function __construct($msg)
    {
        parent::__construct();
        $this->message = $msg;
    }
}

class EDataNotFoundException extends EMioloException
{
    public function __construct($msg)
    {
        parent::__construct();
        $this->message = _M('No Data Found!') . ($msg ? $msg : '');
    }
}

class EDatabaseTransactionException extends EMioloException
{
    public function __construct($msg)
    {
        parent::__construct();
        $this->message = $msg;
    }
}

class EControlException extends EMioloException
{
    public function __construct($msg)
    {
        parent::__construct();
        $this->message = $msg;
    }
}

class EUsesException extends EInOutException
{
    public function __construct($fileName)
    {
        parent::__construct();
        $this->message = _M("File [@1] not found by Uses!", 'miolo', $fileName);
        $this->log();
    }
}

class EFileNotFoundException extends EInOutException
{
    public function __construct($fileName, $msg = '')
    {
        parent::__construct();
        $this->message = _M('@1 File not found: @2','miolo',$msg, $fileName);
        $this->log();
    }
}

class ESessionException extends EMioloException
{
    public function __construct($op)
    {
        parent::__construct();
        $this->message = _M('Error in Session: ') . $op;
        $this->log();
    }
}

class EBusinessException extends EMioloException
{
     public function __construct($msg)
     {
         parent::__construct();
         $this->message = _M('Error in getBusiness: ') . $msg;
         $this->log();
     }
}

class ETimeOutException extends EMioloException
{
     public function __construct($msg='')
     {
         parent::__construct();
         $this->message = _M('Session finished by timeout.') . $msg;
         $this->log();
     }
}

class ELoginException extends EMioloException
{
     public function __construct($msg='')
     {
         parent::__construct();
         $this->message = _M($msg);
         $this->goTo = $this->manager->getActionURL($this->manager->getConf('login.module'),'login'); //$this->manager->getConf('home.url'); 
         $this->log();
     }
}

class ESecurityException extends EMioloException
{
    public function __construct($msg)
    {
        parent::__construct();
        $this->message = $msg;
    }
}

?>
