<?php

class BusinessPersistencePerson extends MBusiness
{
    public $idPerson;
    public $name;

    public function __construct($data=NULL)
    {
       parent::__construct('persistence',$data);
    }

    public function getById($id)
    {
       $this->idPerson = $id;
       $this->retrieve();
       return $this;
    }
}
?>