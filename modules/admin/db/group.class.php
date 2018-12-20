<?php

class BusinessAdminGroup extends MBusiness  implements IGroup
{
    public $idGroup;
	var $group;
    public $access; // an array of Access objects indexed by idTransaction
    public $users;  // an array of User objects indexed by idUser

    public function __construct($data = NULL)
    {
       parent::__construct('admin',$data);
    }

	public function setData($data)
	{
		$this->idGroup = $data->idGroup;
		$this->group = $data->group;
        // $data->access: an array of array(idTransaction, rights)
        $this->setAccess($data->access);
	}
	
    public function getId()
    {
        return $this->idGroup;
    }

    public function getNewId()
    {
        global $MIOLO, $module;
        $db = $MIOLO->getDatabase($module);
        $sql = "select (value) from miolo_sequence where sequence = 'seq_miolo_group'";
        $rs = $db->query($sql)->result;
        $id = $rs[0][0] + 1;
/*        $sql = "update miolo_sequence set value = '".$id."' where sequence = 'seq_miolo_group'";
        $rs = $db->execute($sql);*/
        return $id;
    }


    public function getById($id)
    {
        $this->idGroup = $id; 
        $this->retrieve();
        return $this;
    }
/*    public function getByGroup($group)
    {
        global $MIOLO;
        $db   = $MIOLO->getDatabase('admin');
        $msql = new MSQL()
    }
*/
    public function save()
    {
        parent::save();
    }

    public function deleteGroup()
    {
        global $MIOLO;
        $db = $MIOLO->getDatabase('admin');
try{
        /* deleta access */
        if( $this->access )
            {
                foreach( $this->access as $access )
                {
                    $where = "idgroup = '".$access->idGroup."' and idtransaction = '".$access->idTransaction."'
                              and rights = '".$access->rights."'";
                    $sql = new MSQL('*', 'miolo_access', $where);
                    $db->execute($sql->delete());
                }
            }
        /* deleta relação group/user */
        $where = "idgroup = '".$this->idGroup."'";
        $sql   = new MSQL('*', 'miolo_groupuser', $where);
        $db->execute($sql->delete());

        /* deleta group */
        $where = "idgroup = '".$this->idGroup."'";
        $sql   = new MSQL('*', 'miolo_group', $where);
        $db->execute($sql->delete());
        return true;
}
catch( DatabaseException $e)
{
    return false;
}
    }

    public function delete()
    {
        parent::delete();
    }

    public function listRange($range = NULL)
    {
        $criteria =  $this->getCriteria();
        $criteria->setRange($range);
        return $criteria->retrieveAsQuery();
    }

    public function listAll()
    {
        $criteria =  $this->getCriteria();
        return $criteria->retrieveAsQuery();
    }
    
    public function listByGroup($group = '')
    {
        $criteria = $this->getCriteria();
        $criteria->addCriteria( 'group', 'LIKE', "'$group%'" );
        return $criteria->retrieveAsQuery();
    }

    public function listUsersByIdGroup($idGroup)
    {
        $criteria = $this->getCriteria();
        $criteria->setDistinct(true);
        $criteria->addColumnAttribute('users.login');
        $criteria->addColumnAttribute('group');
        $criteria->addCriteria('idGroup','=', "$idGroup");
        $criteria->addOrderAttribute('users.login');
        return $criteria->retrieveAsQuery();
    }

    public function listAccessByIdGroup($idGroup)
    {
        $criteria =  $this->getCriteria();
        $criteria->addColumnAttribute('access.idTransaction');
        $criteria->addColumnAttribute('access.rights');
        $criteria->addCriteria('idGroup','=', "$idGroup");
        return $criteria->retrieveAsQuery();
    }

    private function setAccess($access)
    {
        $this->access = NULL;
        if (count($access))
        {
            foreach($access as $a)
            {
                $this->access[] = $obj = $this->_miolo->getBusiness('admin','access');
                $obj->idGroup = $this->idGroup;
                $obj->idTransaction = $a[0];
                $obj->rights = $a[1];
            }
        }
    }
}
?>
