<?
class frmConverters extends MForm
{
    public function __construct()
    {   
		parent::__construct('Persistence Sample - Converters');
        $this->defaultButton = false;
        $this->eventHandler();
	}

	function createFields()
    {
        $action = $this->manager->getCurrentURL();
        $array = array(
                 new MLinkButton('btnPost1','[UpperCase converter with Person]',$action),
                 new MLinkButton('btnPost2','[Date converter with Test]',$action),
        );
        $group1 = new MBaseGroup('lbGrp1','Using Converters',$array,'vertical');
        $group1->setShowLabel(false);

        $groups = array($group1);

        $divLeft  = new MDiv('divLeft',$groups);
            $divLeft->width = '35%';

        $divRight = new MContainer('divRight',array());
            $divRight->width = '60%';
            $divRight->float = 'left';

        $fields[] = array(
            $divLeft,
            $divRight
        );

        $this->setFields($fields);
	}

    public function btnPost1_click()
    {
        $name = "name for sample";
        $text .= "Name with lowercase: " . $name ."<br>";
        $person  = $this->manager->getBusiness('persistence','person');
        // $person is a empty new object
        $person->name = "name for sample";
        $person->save();
        $id = $person->idPerson;

        // getting the object
        $person  = $this->manager->getBusiness('persistence','person',$id);

        $text .= "Name at object: " . $person->name ."<br>";

        $this->divRight->setControls(array(new MThemeBox('[UpperCase converter with Person]', $text)));
    }

    public function btnPost2_click()
    {
        // getting the object
        $test  = $this->manager->getBusiness('persistence','test',1);

        $text .= "Date at object Test #1: " . $test->date ."<br>";

        $this->divRight->setControls(array(new MThemeBox('[Date converter with Test]', $text)));
    }
}
?>