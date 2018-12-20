<?php

class BusinessAdmin_ldapGroup extends Business  implements IGroup
{
    public $idGroup;
	var $group;
    public $access; // an array of Access objects indexed by idTransaction
    public $users;  // an array of User objects indexed by idUser
    public $auth;
    public $rights;
    public $base;
                                                                    
    public function __construct($data = NULL)
    {
        global $MIOLO;
        $this->manager = $MIOLO;
        parent::__construct('admin_ldap',$data);
        $MIOLO->import('classes::security::mauthldap');
        $this->auth = new mAuthLdap();
        $this->base = $this->manager->getConf('login.ldap.base');
    }

    public function __destruct()
    {
        //$this->auth->__destruct();
    }

    public function getData()
    {
        parent::getData();
        //$this->getAccess();
        return $this;
    }

	public function setData($data)
	{
		$this->idGroup = $data->idGroup;
		$this->group   = $data->group;

	}

    public function getById($id)
    {
        $search = "(&(objectClass=mioloGroup)(mioloGroup=$id))";
        
        $sr= ldap_search( $this->auth->conn, $this->base, $search, array('name', 'mioloGroup' ));
        $info = ldap_get_entries($this->auth->conn, $sr);

        $this->idGroup = $info[0]['miologroup'][0]; 
        $this->group   = $info[0]['name'][0];
        $this->key     = $info[0]['dn'];
        return $this;
    }

    public function getByGroup($id)
    {
        $search = "(&(objectClass=mioloGroup)(name=$id))";
        
        $sr= ldap_search( $this->auth->conn, $this->base, $search, array('name', 'mioloGroup' ));
        $info = ldap_get_entries($this->auth->conn, $sr);

        $this->idGroup = $info[0]['miologroup'][0]; 
        $this->group   = $info[0]['name'][0];
        $this->key     = $info[0]['dn'];
        return $this;

    }


    public function save( )
    {

        if($this->key)
        {
            $data = array('mioloGroup'=>$this->idGroup, 'name'=>$this->group);
        
            $sr= ldap_modify( $this->auth->conn, $this->key, $data);
            
            if($sr)
            {
                $this->setRights();
            }

            return ($sr);
        }

        $this->key = $dn   = 'mioloGroup='.$this->idGroup.', '.$this->base;

        $info = array('objectClass'=>array('mioloGroup'), 'mioloGroup'=>array($this->idGroup), 'name'=>array($this->group) );
        $sr   = ldap_add( $this->auth->conn, $dn, $info);

        if($sr)
        {
            $this->setRights();
        }

        return ($sr);
    }
    
    public function delete()
    {
        if($this->key)
        {
            $this->rights = array();
            $this->setRights();
            $sr= ldap_delete( $this->auth->conn, $this->key);
            return ($sr);
        }
    }

    public function listRange($range = NULL)
    {
        $criteria =  $this->getCriteria();
        $criteria->setRange($range);
        return $criteria->retrieveAsQuery();
    }

    public function listAll($array=true)
    {
        $search = "objectClass=mioloGroup";
        
        $sr= ldap_search( $this->auth->conn, $this->base, $search, array('name', 'mioloGroup' ));
        $info = ldap_get_entries($this->auth->conn, $sr);

        $return = array();
        for($i=0; $i < $info['count']; $i++)
        {
            if($array)
                $return[] = array($info[$i]['miologroup'][0], $info[$i]['name'][0]);
            else
                $return[$info[$i]['miologroup'][0]] = $info[$i]['name'][0];
        }
        return $return;
    }

    public function listUsersByIdGroup($idGroup)
    {
    }

    public function listAccessByIdGroup($idGroup)
    {
    }

    public function getAccess($idGroup)
    {
        $result = $db->query($s='SELECT miolo_access.idtransaction,miolo_access.rights FROM miolo_group INNER JOIN miolo_access ON (miolo_group.idgroup=miolo_access.idgroup) WHERE (miolo_group.idgroup = '.$idGroup.')');
        
        return $result;
    }

    private function setAccess($access)
    {
        $sql = new mSql('', 'miolo_access', 'idGroup = ?');
        $sql->setParameters(array($this->idGroup));
        $db->execute($sql->delete());
        $this->access = NULL;
        if (count($access))
        {
            foreach($access as $a)
            {
                $this->access[] = $obj = $this->_miolo->getBusiness('admin_ldap','access');
                $obj->idGroup = $this->idGroup;
                $obj->idTransaction = $a[0];
                $obj->rights = $a[1];
            }
        }
    }

    public function getRights()
    {
        $MIOLO  = $this->manager;
        $filter = "(&(objectClass=mioloGroupPermission)(mioloGroup=$this->idGroup))";
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

    public function setRights()
    {
        $rs = ldap_search($this->auth->conn, $this->base, '(&(objectClass=mioloGroupPermission)(mioloGroup='.$this->idGroup.'))', array('dn','mioloModuleName', 'mioloModuleAction'));
        $info = ldap_get_entries($this->auth->conn, $rs);

        for($i=0; $i<$info['count']; $i++)
        {
            ldap_delete($this->auth->conn, $info[$i]['dn']);
        }
        foreach($this->rights as $module=>$r)
        {
            $dn   = 'mioloModuleName='.$module. ','.$this->key;
            $info = array('objectClass'=>'mioloGroupPermission', 'mioloModuleName'=> $module, 'mioloModuleAction'=>$r, 'mioloGroup'=>$this->idGroup);
            ldap_add($this->auth->conn, $dn, $info);
            //$sr= ldap_modify( $this->auth->conn, $this->key, $info);
        }

        return $sr;
    }

    public function setArrayRights($rights)
    {
        $this->rights = array();
        foreach($rights as $r)
        {
            $this->rights[$r[0]][] = $r[1];
        }
    }


}
?>
