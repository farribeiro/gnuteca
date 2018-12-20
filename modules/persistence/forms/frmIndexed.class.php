<?
class frmIndexed extends MForm
{
    public $test;
 
    public function __construct()
    {   
		parent::__construct('Persistence Sample - Indexed Attributes');
        $this->eventHandler();
	}

	function createFields()
    {
        $student = $this->manager->getBusiness('persistence','student');
        $query = $student->listAll();
        $answer = array('A'=>'A','B'=>'B','C'=>'C','D'=>'D','E'=>'E');
        $fields = array(
            new MLabel('Insert a new test:','blue',true),
            new MSelection('number','','Student',$query->chunkResult(0,4)),
            new MSelection('q[1]','','Question 1',$answer),
            new MSelection('q[2]','','Question 2',$answer),
            new MSelection('q[3]','','Question 3',$answer),
            new MSelection('q[4]','','Question 4',$answer),
            new MSelection('q[5]','','Question 5',$answer),
        );

        $this->setFields($fields);

        $buttons = array(
            new MButton('btnPost','Send Data')
        );

        $this->setButtons($buttons);

	}
    
    public function getData()
    {
        $data = new FormData();
        $data->number = $this->getFieldValue('number');
        $data->q = $this->getFormValue('q');
        return $data;
    }

    public function btnPost_click()
    {
        $data = $this->getData();
mdump($data);
    }

}
?>
