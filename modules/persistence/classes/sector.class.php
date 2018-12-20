<?php
class BusinessPersistenceSector extends MBusiness
{
    public $id;
    public $nick;
    public $name;
    public $type;
    public $idParent;
    public $parent;
    public $users;

    public function __construct($data=NULL)
    {
       parent::__construct('persistence',$data);
    }

    public function getById($id)
    {
       $this->id = $id;
       $this->retrieve();
       return $this;
    }

    public function addUser($user)
    {
       $this->users[] = $user;
    }

}
?>