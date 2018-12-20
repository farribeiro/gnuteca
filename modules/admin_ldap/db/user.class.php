<?php
class BusinessAdmin_ldapUser extends Business //implements IUser
{
    public $idUser;
    public $login;
    public $nome;
    public $email;
    public $nick;
    public $password;
    public $hash;
    public $groups;  // a indexed array of Group objects
    public $auth;
    public $perms;
    public $rights;
    public $base;
                                                                    
    public function __construct($data = NULL)
    {
        global $MIOLO;
        $this->manager = $MIOLO;
        parent::__construct('admin_ldap',$data);
        
        $MIOLO->import('classes::security::mauthldap');
        $this->auth = new mAuthLdap();
        
        $MIOLO->import('classes::security::mpermsldap');
        $this->schema = $MIOLO->getConf('login.ldap.schema');
        $this->base   = $this->manager->getConf('login.ldap.base');
    }

    public function __destruct()
    {
        //$this->auth->__destruct();
    }

    public function setData($data)
    {
        $this->groups = $data->grupos;
        $this->nome   = $data->nome;
        $this->login  = $data->login;
    }
    
    public function getName()
    {
        return $this->nome;
    }

    public function getId()
    {
        return $this->idUser;
    }

    public function getById($id)
    {
        if($this->schema == 'system')
            $search = '(&(objectClass=person)(|(uid='.$id.')(codAluno='.$id.')))';
        else
            $search = "(&(objectClass=mioloUser)(login=$id))";

        $name = $this->manager->getConf('login.ldap.userName');
        $mail = $this->manager->getConf('login.ldap.userEmail');
        
        $sr= ldap_search( $this->auth->conn, $this->base, $search, array('uid', 'login', 'name', 'mioloGroup', $name , $mail, 'codAluno' ));
        $info = ldap_get_entries($this->auth->conn, $sr);

        $this->login   = $info[0]['uid'][0] ? $info[0]['uid'][0] : $info[0]['login'][0]; 
        $this->idUser  = $this->login;
        
        if($this->schema == 'system')
        {
            $this->nome  = $info[0][strtolower($name)][0];
            $this->email = $info[0][strtolower($mail)][0];
        }
        else
        {
            $this->nome  = $info[0]['name'][0];
            $this->email = $info[0]['email'][0];
        }
            
        $this->key     = $info[0]['dn'];
        $this->codAluno= $info[0]['codaluno'][0];
        $this->groups  = array();

        for($i=0; $i < $info[0]['miologroup']['count']; $i++)
        {
            $this->groups[] = $info[0]['miologroup'][$i];
        }
        return $this;

    }

    public function getByLogin($login)
    {
        return $this->getById($login);
    }

    public function getByLoginPass($login,$pass)
    {
    }

    public function save()
    {
        if($this->schema == 'system')
            $search = '(&(objectClass=person)(uid='.$this->login.'))';
        else
            $search = "(&(objectClass=mioloUser)(login=$this->login))";
        
        $sr= ldap_search( $this->auth->conn, $this->base, $search, array('uid', 'objectClass' ));
        $info = ldap_get_entries($this->auth->conn, $sr);
        
        $objClass = $info[0]['objectclass'];
        unset($objClass['count']);
        if(! in_array( 'mioloUser', $objClass))
        {
            $objClass[] = 'mioloUser';
        }

        $info = array('mioloGroup'=> $this->groups ? $this->groups : array( ), 'objectClass'=>$objClass);
        $sr= ldap_modify( $this->auth->conn, $this->key, $info);

        $this->setRights();

        return $sr;
    }
    
    public function updatePassword($password)
    {
    }

    public function updateHash($hash)
    {
    }

    public function delete()
    {
    }

    public function listByLogin($login, $name, $cod)
    {
        $search = '(objectClass='.($this->schema == 'system' ? 'person' : 'mioloUser' ).')';

        $nameAttr = 'name';
        
        if($this->schema == 'system') 
            $nameAttr = $this->manager->getConf('login.ldap.userName');
        
        if ($login != '')
        {
            $login = str_replace('%', '*', $login);
            $filter = $login = '('.($this->schema == 'system' ? 'uid' : 'login')."=$login)";
        }
        if($name != '')
        {
            $name  = str_replace('%', '*', $name);
            $filter = $name  = "($nameAttr=$name)";
        }
        if($cod  != '')
        {
            $filter = $login = "(codAluno=$cod)";
        }

        if($login != '' && $name != '')
        {
            $filter = "(|$name$login)";
        }
        $search = '(&(objectClass='.($this->schema == 'system' ? 'person' : 'mioloUser').")$filter)";
        
        $sr= ldap_search( $this->auth->conn, $this->base, $search, array('uid', 'login', 'password', $nameAttr ));
        ldap_sort($this->auth->conn, $sr, $nameAttr);
        $info = ldap_get_entries($this->auth->conn, $sr);

        $result = array();

        for($c=0; $c < $info['count']; $c++)
        {
            $login = $info[$c]['uid'][0] ? $info[$c]['uid'][0] : $info[$c]['login'][0];
            $result[$c] = array( $login, $login, $info[$c][strtolower($nameAttr)][0]);
        }
        return $result;
    }

    public function listRange($range = NULL)
    {
    }

    public function listAll()
    {
    }

    public function listGroupsByIdUser($idUser)
    {
    }

    public function getTransactionRights($transaction, $login = NULL)
    {
    }

    public function setRights()
    {
        $rs = ldap_search($this->auth->conn, $this->base, '(&(objectClass=mioloUserPermission)(login='.$this->login.'))', array('dn','mioloModuleName', 'mioloModuleAction'));
        $info = ldap_get_entries($this->auth->conn, $rs);

        for($i=0; $i<$info['count']; $i++)
        {
            ldap_delete($this->auth->conn, $info[$i]['dn']);
        }
        foreach($this->rights as $module=>$r)
        {
            $dn   = 'mioloModuleName='.$module. ','.$this->key;
            $info = array('objectClass'=>'mioloUserPermission', 'mioloModuleName'=> $module, 'mioloModuleAction'=>$r, 'login'=>$this->login);
            ldap_add($this->auth->conn, $dn, $info);
            //$sr= ldap_modify( $this->auth->conn, $this->key, $info);
        }

        return $sr;
    }

    public function getRights($login)
    {
        $MIOLO  = $this->manager;
        $filter = "(&(objectClass=mioloUserPermission)(login=$login))";
        $sr     = ldap_search($this->auth->conn, $this->base, $filter, array('miolomodulename', 'miolomoduleaction') );
        $info   = ldap_get_entries($this->auth->conn, $sr);

        $rights = array();
        for($i=0; $i<$info['count']; $i++)
        {
            $module = $info[$i]['miolomodulename'][0];
            $rights[$module] = array();
            for($j=0; $j<$info[$i]['miolomoduleaction']['count']; $j++)
            {
                $rights[$module][] = $info[$i]['miolomoduleaction'][$j];
            }
        }
        return $rights;
    }


    public function getGroups()
    {
    }

    public function getArrayGroups()
    {
        $aGroups = array();
        $this->getGroups();

        if (count($this->groups))
        {
            foreach($this->groups as $group)
            {
                $aGroups[$group->group] = $group->group;
            }
        }
        return $aGroups; 
    }
    
    public function setArrayRights($rights)
    {
        $this->rights = array();
        foreach($rights as $r)
        {
            $this->rights[$r[0]][] = $r[1];
        }
    }

    public function setArrayGroups($aGroups)
    {
        $this->groups = $aGroups;
        return;
        $this->groups = NULL;
        if (count($aGrupos))
        {
            foreach($aGrupos as $g)
            {
                $grupo = $this->_miolo->getBusiness('admin','group', $g);
                $this->groups[$g] = $group;
            }
        }
    }

    public function validatePassword($password)
    {
       if ($this->password != $password)
       {
           throw new ESecurityException('Passwords dont matches');
       }
       return true;     
    }

    public function validatePasswordMD5($challenge,$response)
    {
       $hash_pass = md5(trim($this->login) . ':' . trim($this->hash) . ":" . $challenge);
       if ($hash_pass == $response)
       {
           throw new ESecurityException('Passwords dont matches');
       }
       return true;     
    }

    public function isMemberOf($group)
    {
        $ok = false;
        if (count($this->groups))
        {
            foreach($this->groups as $group)
            {
                $ok = $ok || ($group == $group->group);
            }
        }
        return $ok;
    }
}
?>
