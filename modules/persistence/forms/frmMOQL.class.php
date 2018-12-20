<?
class frmMOQL extends MForm
{
    public $group;
    public $user; 
    public $sector;
    public $person;
    public $student;
    public $test;
    public $options;
 
    public function __construct()
    {   
		parent::__construct('Persistence Sample - MOQL Samples');
        $this->group   = $this->manager->getBusiness('persistence','group');
        $this->user    = $this->manager->getBusiness('persistence','user');
        $this->sector  = $this->manager->getBusiness('persistence','sector');
        $this->person  = $this->manager->getBusiness('persistence','person');
        $this->student = $this->manager->getBusiness('persistence','student');
        $this->test    = $this->manager->getBusiness('persistence','test');
        $this->defaultButton = false;
        $this->eventHandler();
	}

	function createFields()
    {
        $this->options = array(
             '1'=>'[List All Groups]',
             '2'=>'[List Person By Name]',
             '3'=>'[List Person By Name - Using Parameters]',
             '4'=>'[List Person - distinct]',
             '5'=>'[List Person - order]',
             '6'=>'[List Person - multiple filters]',
             '7'=>'[List User/Sector - join oneToOne]',
             '8'=>'[List User/Sector - join oneToOne - columns - filter]',
             '9'=>'[List User/Group - join manyToMany]',
             '10'=>'[List Group - join + groupby]',
             '11'=>'[List Group - join + groupby + having]',
             '12'=>'[List Group - in]',
             '13'=>'[List Group - alias]',
             '14'=>'[List Group - association join alias]',
             '16'=>'[List Sector - forced join alias]',
             '17'=>'[List Sector - auto-relation]',
             '18'=>'[List Group - subquery]',
             '19'=>'[List Group - subquery - reference]',
             '20'=>'[List Group - triple association join]',
             '21'=>'[List Group - outer join]',
             '22'=>'[List Student - inheritance]',
             '23'=>'[List Group - compound filter]',
             '24'=>'[New Group - manyToMany]',
             '25'=>'[New User - oneToOne]',
             '26'=>'[New Student - herança]'
        );

        $action = $this->manager->getCurrentURL();
        foreach($this->options as $i=>$option)
        {
            $array[] = new MLinkButton("btnPost$i",$option,$action);
        }
        $group1 = new MBaseGroup('lbGrp1','Using MOQL - Criterias',$array,'vertical');
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

    public function showResult($option, $sql, $result)
    {
        $container = new MVContainer('mv',array(
            new MLabel($this->options[$option],'black',true),
            new MThemeBox('SQL', $sql),
            new MTableRaw('', $result)
        ));

        $this->divRight->setControls(array($container));
    }

    public function btnPost1_click()
    {
        // list all groups
        $criteria = $this->group->getCriteria();
        $query = $criteria->retrieveAsQuery();

        $this->showResult(1,$query->sql, $query->result);
    }

    public function btnPost2_click()
    {
        // list person by name 
        $criteria = $this->person->getCriteria();
        $criteria->addCriteria('name','LIKE',"P%");
        $query = $criteria->retrieveAsQuery();

        $this->showResult(2,$query->sql, $query->result);
    }

    public function btnPost3_click()
    {
        // using parameters
        $name = 'P';
        $criteria = $this->person->getCriteria();
        $criteria->addCriteria('name','LIKE',"?");
        $query = $criteria->retrieveAsQuery("{$name}%");

        $this->showResult(3,$query->sql, $query->result);
    }

    public function btnPost4_click()
    {
        // list person by name - distinct 
        $criteria = $this->person->getCriteria();
        $criteria->setDistinct(true);
        $criteria->addColumnAttribute('name');
        $query = $criteria->retrieveAsQuery();

        $this->showResult(4,$query->sql, $query->result);
    }

    public function btnPost5_click()
    {
        // list person by name - order
        $criteria = $this->person->getCriteria();
        $criteria->addColumnAttribute('name');
        $criteria->addOrderAttribute('name');
        $query = $criteria->retrieveAsQuery();

        $this->showResult(5,$query->sql, $query->result);
    }

    public function btnPost6_click()
    {
        // list person by name - using multiple filters and parameters
        $criteria = $this->person->getCriteria();
        $condition = array(
            array('','name','LIKE',"N%"),
            array('OR', array(
                array('','name','LIKE',"C%"),
                array('OR','name','LIKE',"?")
              )
            )
        );
        $criteria->addMultiCriteria($condition);
        $query = $criteria->retrieveAsQuery("A%");

        $this->showResult(6,$query->sql, $query->result);
    }

    public function btnPost7_click()
    {
        // List User/Sector - join oneToOne
        $criteria = $this->user->getCriteria();
        // 'sector' is the association
        $criteria->addCriteria('sector.nick','LIKE',"S%");
        $query = $criteria->retrieveAsQuery();

        $this->showResult(7,$query->sql, $query->result);
    }

    public function btnPost8_click()
    {
        // List User/Sector - join oneToOne - columns - filter
        $criteria = $this->user->getCriteria();
        // 'sector' is the association
        $criteria->addCriteria('sector.nick','LIKE',"S%");
        $criteria->addColumnAttribute('login');
        $criteria->addColumnAttribute('sector.nick','Sector');
        $query = $criteria->retrieveAsQuery();

        $this->showResult(8,$query->sql, $query->result);
    }

    public function btnPost9_click()
    {
        // List User/Group - join manyToMany
        $criteria = $this->user->getCriteria();
        // 'groups' is the association
        $criteria->addCriteria('groups.group','LIKE',"G%");
        //getting all columns of user + group name
        $criteria->addColumnAttribute('*');
        $criteria->addColumnAttribute('groups.group');
        $query = $criteria->retrieveAsQuery();

        $this->showResult(9,$query->sql, $query->result);
    }

    public function btnPost10_click()
    {
        // List Group - join + groupby
        $criteria = $this->group->getCriteria();
        $criteria->addColumnAttribute('group');
        $criteria->addColumnAttribute('count(users.idUser)');
        $criteria->addGroupAttribute('group');
        $query = $criteria->retrieveAsQuery();

        $this->showResult(10,$query->sql, $query->result);
    }

    public function btnPost11_click()
    {
        //  List Group - join + groupby + having
        $criteria = $this->group->getCriteria();
        $criteria->addColumnAttribute('group');
        $criteria->addColumnAttribute('count(users.idUser)');
        $criteria->addGroupAttribute('group');
        $criteria->addHavingCriteria('count(users.idUser)','>','2');
        $query = $criteria->retrieveAsQuery();

        $this->showResult(11,$query->sql, $query->result);
    }

    public function btnPost12_click()
    {
        //  List Group - in
        $criteria = $this->group->getCriteria();
        $values = array('Grupo Admin','PHP');
        $criteria->addCriteria('group','IN', $values);
        $query = $criteria->retrieveAsQuery();

        $this->showResult(12,$query->sql, $query->result);
    }

    public function btnPost13_click()
    {
        //  List Group - alias
        $criteria = $this->group->getCriteria();
        $criteria->setAlias('G');
        $criteria->addColumnAttribute('G.idGroup');
        $criteria->addColumnAttribute('G.group');
        $criteria->addCriteria('group','LIKE', "G%");
        $query = $criteria->retrieveAsQuery();

        $this->showResult(13,$query->sql, $query->result);
    }

    public function btnPost14_click()
    {
        //  List Group - association join alias
        $criteria = $this->group->getCriteria();
        $criteria->setAlias('G');
        $criteria->setAssociationAlias('users','U');
        $criteria->addColumnAttribute('G.idGroup');
        $criteria->addColumnAttribute('G.group');
        $criteria->addColumnAttribute('U.login');
        $query = $criteria->retrieveAsQuery();

        $this->showResult(14,$query->sql, $query->result);
    }

    function btnPost30_click()
    {
        $criteria = $this->sector->getCriteria();
        $criteria->setAlias('S');
        $criteria->addCriteria('S.nick','=', "'ADM'");
        $criteria2 = $this->person->getCriteria();
        $criteria2->setAlias('P');
        $criteria2->addColumnAttribute('S.nick');
        $criteria2->addColumnAttribute('P.name');
        $criteria2->addJoinCriteria($criteria);
        $criteria2->addCriteria('S.id', '=', 'P.idperson');
        $query = $criteria2->retrieveAsQuery();
        $this->AddField(new MThemeBox('SQL', '<br>'. $query->sql . '<br>'));
        $this->AddField(new TableRaw('[List Group - forced join alias]', $query->result));
    }

    function btnPost31_click()
    {
        $criteria = $this->sector->getCriteria();
        $criteria->setAutoAssociationAlias('S1','S2');
        $criteria->addColumnAttribute('S1.nick','parent');
        $criteria->addColumnAttribute('S2.nick','child');
        $criteria->addCriteria('S1.id', '=', 'S2.parent');
        $query = $criteria->retrieveAsQuery();
        $this->AddField(new MThemeBox('SQL', '<br>'. $query->sql . '<br>'));
        $this->AddField(new TableRaw('[List Group - auto-relation]', $query->result, $query->GetColumnNames()));
    }

    function btnPost32_click()
    {
        $subCriteria = $this->user->getCriteria();
        $subCriteria->addCriteria('sector.nick','LIKE',"'A%'");
        $subCriteria->addColumnAttribute('iduser');
        $criteria = $this->user->getCriteria();
        $criteria->addCriteria('iduser','IN', $subCriteria);
        $query = $criteria->retrieveAsQuery();
        $this->AddField(new MThemeBox('SQL', '<br>'. $query->sql . '<br>'));
        $this->AddField(new TableRaw('[List Group - subquery]', $query->result));
    }

    function btnPost33_click()
    {
        $subCriteria = $this->user->getCriteria();
        $subCriteria->setReferenceAlias('S');
        $subCriteria->addColumnAttribute('count(iduser)');
        $subCriteria->addCriteria('idsector','=',"S.idsector");
        $criteria = $this->sector->getCriteria();
        $criteria->setAlias('S');
        $criteria->addCriteria($subCriteria, '>', '150');
        $query = $criteria->retrieveAsQuery();
        $this->AddField(new MThemeBox('SQL', '<br>'. $query->sql . '<br>'));
        $this->AddField(new TableRaw('[List Group - subquery - reference]', $query->result));
    }

    function btnPost34_click()
    {
        $criteria = $this->group->getCriteria();
        $criteria->addColumnAttribute('group');
        $criteria->addColumnAttribute('users.login');
        $criteria->addColumnAttribute('users.sector.nick');
        $criteria->addCriteria('users.sector.nick','=',"'ADM'");
        $query = $criteria->retrieveAsQuery();
        $this->AddField(new MThemeBox('SQL', '<br>'. $query->sql . '<br>'));
        $this->AddField(new TableRaw('[List Group - triple association join]', $query->result));
    }

    function btnPost35_click()
    {
        $criteria = $this->sector->getCriteria();
        $criteria->addColumnAttribute('nick');
        $criteria->addColumnAttribute('count(users.iduser)');
        $criteria->addCriteria('nick','LIKE',"'PRO%'");
        $criteria->addGroupAttribute('nick');
        $criteria->addHavingCriteria('count(users.iduser)','=','0');
        $criteria->setAssociationType('users','right');
        $query = $criteria->retrieveAsQuery();
        $this->AddField(new MThemeBox('SQL', '<br>'. $query->sql . '<br>'));
        $this->AddField(new TableRaw('[List Group - outer join]', $query->result));
    }

    function btnPost36_click()
    {
        $criteria = $this->student->getCriteria();
        $criteria->addColumnAttribute('number');
        $criteria->addColumnAttribute('name');
        $criteria->addCriteria('name','LIKE',"'ZEEV%'");
        $query = $criteria->retrieveAsQuery();
        $this->AddField(new MThemeBox('SQL', '<br>'. $query->sql . '<br>'));
        $this->AddField(new TableRaw('[List Student - inheritance]', $query->result));
    }

    function btnPost37_click()
    {
        $criteria = $this->group->getCriteria();
        $cc = new CriteriaCondition;
        $cc->addCriteria($criteria->getCriteria('group','LIKE',"'%A%'"));
        $cc->addOrCriteria($criteria->getCriteria('group','LIKE',"'%E%'"));
        $criteria->addCriteria('group','LIKE',"'C%'");
        $criteria->addCriteria($cc);
        $query = $criteria->retrieveAsQuery();
        $this->AddField(new MThemeBox('SQL', '<br>'. $query->sql . '<br>'));
        $this->AddField(new TableRaw('[List Group - Compound Filter]', $query->result));
    }



}
?>
