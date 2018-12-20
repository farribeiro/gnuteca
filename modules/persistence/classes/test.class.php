<?php

class BusinessPersistenceTest extends MBusiness
{
    public $idTest;
    public $questions;
    public $date;
	public $number;
    public $student;

    public function __construct($data=NULL)
    {
        parent::__construct('persistence',$data);
    }

    public function getById($idTest)
    {
        $this->idTest = $idTest;
        $this->retrieve();
        return $this;
    }
}
?>