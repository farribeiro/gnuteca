<?php

global $MIOLO;
$MIOLO->usesBusiness('persistence','person');

class BusinessPersistenceStudent extends BusinessPersistencePerson
{
    public $number;
    public $situation;

    public function __construct($data=NULL)
    {
       parent::__construct('persistence',$data);
    }

    public function getById($number)
    {
       $this->number = $number;
       $this->retrieve();
       return $this;
    }

    public function listAll()
    {
        $criteria = $this->getCriteria();
        $query = $criteria->retrieveAsQuery();
        return $query;
    }

}
?>