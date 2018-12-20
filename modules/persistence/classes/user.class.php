<?php

class BusinessPersistenceUser extends MBusiness
{
    public $idUser;
    public $idPerson;
    public $login;
    public $password;
    public $nick;
    public $groups;
    public $idSector;
    public $sector;
	public $person;

    public function __construct($data=NULL)
    {
       parent::__construct('persistence',$data);
    }

    public function getById($id)
    {
       $this->idUser = $id;
       $this->retrieve();
       return $this;
    }

    public function getProxyById($id)
    {
       $this->idUser = $id;
       $this->retrieveAsProxy();
    }

    public function proxyByLogin($login)
    {
        $criteria = $this->getCriteria();
        $criteria->addCriteria('login','LIKE',"{$login}%");
        $query = $criteria->retrieveAsProxyQuery();
        return $query;
    }

    public function proxyCursorByLogin($login)
    {
        $criteria = $this->getCriteria();
        $criteria->addCriteria('login','LIKE',"{$login}%");
        $cursor = $criteria->retrieveAsProxyCursor();
        return $cursor;
    }

    public function save_ok()
    {
        $this->save();
    }

    public function save_error()
    {
        // force an error
        throw new EDatabaseTransactionException('Transaction Error  Sample');
    }

}
?>