<?php

class BusinessPersistenceGroup extends MBusiness
{
    public $idGroup;
    public $group;
    public $users = array();

    public function __construct($data=NULL)
    {
       parent::__construct('persistence',$data);
    }

    public function getById($idGroup)
    {
       $this->idGroup = $idGroup;
       $this->retrieve();
       return $this;
    }

    public function listAll()
    {
        $criteria = $this->getCriteria();
        $query = $criteria->retrieveAsQuery();
        return $query;
    }

    public function listByName($name)
    {
        $criteria = $this->getCriteria();
        $criteria->addCriteria('group','LIKE',"{$name}%");
        $query = $criteria->retrieveAsQuery();
        return $query;
    }

    public function listByNamePar($name)
    {
        $criteria = $this->getCriteria();
        $criteria->addCriteria('group','LIKE',"?");
        $criteria->addOrCriteria('group','LIKE',"P%");
        $query = $criteria->retrieveAsQuery("$name%");
        return $query;
    }

    public function cursorByName($name)
    {
        $criteria = $this->getCriteria();
        $criteria->addCriteria('group','LIKE',"{$name}%");
        $cursor = $criteria->retrieveAsCursor();
        return $cursor;
    }

    public function addUser($user)
    {
       $this->users[] = $user;
    }
}
?>