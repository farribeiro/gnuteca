<?
class MAuthLdap extends MAuth
{
    public $login;  // objeto Login
    public $iduser; // iduser do usuario corrente
    public $module; // authentication module;
    public $conn; //the ldap connection

    public function connect()
    {
        $host = $this->manager->getConf('login.ldap.host');
        $port = $this->manager->getConf('login.ldap.port');
        $user = $this->manager->getConf('login.ldap.user');
        $pass = $this->manager->getConf('login.ldap.password');
        $tls  = $this->manager->getConf('login.ldap.tls');
        $this->conn = ldap_connect($host, $port);

        if ($tls == true)
        {
            ldap_start_tls($this->conn);
        }

        ldap_set_option($this->conn, LDAP_OPT_PROTOCOL_VERSION, 3);
        $r    = ldap_bind($this->conn, $user, $pass);

        if( ! $r )
        {
            $prompt = _M('Error on ldap connection!',$module);
            print($prompt);
            exit;
        }
        return true;
    }

    public function __destruct()
    {
        ldap_close($this->conn);
    }

    public function __construct()
    {
        parent::__construct();
        $this->connect();
    }


    public function authenticate($user, $pass, $log=true)
    {

        $MIOLO     = $this->manager;
        $base      = $MIOLO->getConf('login.ldap.base');
        $custom    = $MIOLO->getConf('login.ldap.custom');
        $schema    = $MIOLO->getConf('login.ldap.schema');
        $attr      = $MIOLO->getConf('login.ldap.userName');
        $l         = $MIOLO->getConf('login.ldap.login');
        $idPerson  = $MIOLO->getConf('login.ldap.idperson');
        $vars   = array(
                        '%domain%'  =>$_SERVER['HOST_NAME'], 
                        '%login%'   =>$user, 
                        '%password%'=>md5($pass),
                        'AND('      =>'&(',
                        'OR('       =>'|(',
                    );
        switch($schema)
        {
            case 'miolo':
                $search = '(&(login='.$user.')(password='.md5($pass).'))';
                $login  = false;
                break;
            case 'system':
                $search = 'uid='.$user;
                $login  = true;
                break;
            default:
                if($custom)
                {
                    $search = strtr($custom, $vars);
                }
                else
                {
                    $search = strtr('(&(|(uid=%login%)(login=%login%))(objectClass=mioloUser))', $vars);
                }
                $login = null;
        }
        $sr= ldap_search( $this->conn, $base, $search, array('dn', $attr, 'password', 'mioloGroup', $l, $idPerson ));
        
        $info = ldap_get_entries($this->conn, $sr);

        for($i=0; $i < $info['count']; $i++)
        {
            $bind = $exists = false;
            if( $info[$i]['dn'] )
            {
                if( ! $login )
                {
                    $exists = $info[$i]['password'][0] == md5($pass);
                }
                if( !$exists && (($login) || is_null($login)) )
                {
                    $bind   = ldap_bind($this->conn, $info[$i]['dn'], $pass);
                }
                if( $bind || $exists )
                {
                    $r = true;
                    break;
                }
            }
        }
        if($l) $user = $info[$i][$l][0];

        $groups = array();
        if($info[$i]['miologroup']['count'] > 0)
        {
            unset($info[$i]['miologroup']['count']);
            $groups = $info[$i]['miologroup'];
        }
        
        if($log && $r)
        {
            $login = new MLogin($user,
                                $pass,
                                $info[$i][$attr][0],
                                0);
            $login->setIdPerson( $info[$i][$idPerson][0] );
            $login->setGroups($groups);
            $this->setLogin($login);
        }
        return $r;
    }
}
?>