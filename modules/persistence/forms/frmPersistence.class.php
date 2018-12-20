<?
class frmPersistence extends MForm
{
    public $group;
    public $user; 
    public $sector;
    public $person;
    public $student;
 
    public function __construct()
    {   global $MIOLO;
		parent::__construct('Persistence Sample');
        $this->group = $MIOLO->getBusiness('example','group');
        $this->user = $MIOLO->getBusiness('example','user');
        $this->sector = $MIOLO->getBusiness('example','sector');
        $this->person = $MIOLO->getBusiness('example','person');
        $this->student = $MIOLO->getBusiness('example','student');
        $this->defaultButton = false;
        $this->eventHandler();
	}

	function CreateFields()
    {
        $action = $this->manager->getCurrentURL();
        $array = array(
                 new MLinkButton('btnPost1','[User id=1]',$action),
                 new MLinkButton('btnPost2','[User as Proxy]',$action),
                 new MLinkButton('btnPost3','[List User as proxyQuery]',$action),
                 new MLinkButton('btnPost4','[List User as proxyCursor]',$action),
                 new MLinkButton('btnPost5','[Sector]',$action),
                 new MLinkButton('btnPost6','[Group]',$action),
                 new MLinkButton('btnPost7','[ListAll Group]',$action),
                 new MLinkButton('btnPost8','[ListByName Group]',$action),
                 new MLinkButton('btnPost9','[ListByName-Parâmetros Group]',$action),
                 new MLinkButton('btnPost10','[CursorByName Group]',$action),
                 new MLinkButton('btnPost11','[Student - herança]',$action)
        );
        $group1 = new MBaseGroup('lbGrp1','Using Objects',$array,'vertical');
        $group1->setShowLabel(false);
        $array = array(
                 new MLinkButton('btnPost19','[List Group]',$action),
                 new MLinkButton('btnPost20','[List Group - order]',$action),
                 new MLinkButton('btnPost21','[List Group - filter]',$action),
                 new MLinkButton('btnPost22','[List User/Sector - join oneToOne]',$action),
                 new MLinkButton('btnPost23','[List User/Sector - join oneToOne - columns - filter]',$action),
                 new MLinkButton('btnPost24','[List User/Group - join manyToMany]',$action),
                 new MLinkButton('btnPost25','[List Group - join + groupby]',$action),
                 new MLinkButton('btnPost26','[List Group - join + groupby + having]',$action),
                 new MLinkButton('btnPost27','[List Group - in]',$action),
                 new MLinkButton('btnPost28','[List Group - alias]',$action),
                 new MLinkButton('btnPost29','[List Group - association join alias]',$action),
                 new MLinkButton('btnPost30','[List Sector - forced join alias]',$action),
                 new MLinkButton('btnPost31','[List Sector - auto-relation]',$action),
                 new MLinkButton('btnPost32','[List Group - subquery]',$action),
                 new MLinkButton('btnPost33','[List Group - subquery - reference]',$action),
                 new MLinkButton('btnPost34','[List Group - triple association join]',$action),
                 new MLinkButton('btnPost35','[List Group - outer join]',$action),
                 new MLinkButton('btnPost36','[List Student - inheritance]',$action),
                 new MLinkButton('btnPost37','[List Group - compound filter]',$action)
        ); 
        $group2 = new MBaseGroup('lbGrp2','Using Criteria',$array,'vertical');
        $group2->setShowLabel(false);
        $array = array(
                 new MLinkButton('btnPost12','[New Group - manyToMany]',$action),
                 new MLinkButton('btnPost13','[New User - oneToOne]',$action),
                 new MLinkButton('btnPost14','[New Student - herança]',$action),
        ); 
        $group3 = new MBaseGroup('lbGrp3','Insert',$array,'vertical');
        $group3->setShowLabel(false);
        $array = array(
                 new MLinkButton('btnPost15','[Delete Group]',$action),
                 new MLinkButton('btnPost16','[Delete Sector]',$action),
                 new MLinkButton('btnPost38','[User: Delete Association with Sector - 1:1]',$action),
                 new MLinkButton('btnPost39','[Sector: Delete Association with User - 1:N]',$action),
                 new MLinkButton('btnPost40','[Group: Delete Association with User  - N:N]',$action),
        ); 
        $group4 = new MBaseGroup('lbGrp4','Delete',$array,'vertical');
        $group4->setShowLabel(false);
        $array = array(
                 new MLinkButton('btnPost17','[Update Group]',$action),
        ); 
        $group5 = new MBaseGroup('lbGrp5','Update',$array,'vertical');
        $group5->setShowLabel(false);
        $array = array(
                 new MLinkButton('btnPost41','[Sector: Save Association with User]',$action),
        ); 
        $group6 = new MBaseGroup('lbGrp6','Save',$array,'vertical');
        $group6->setShowLabel(false);

        $groups = array($group1, $group2, $group3, $group4, $group5, $group6);

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
        $this->user->getById(1);
        $text = "Login: {$this->user->login}<br>";
        $text .= "Password: {$this->user->password}<br>";
        $text .= "Nick: {$this->user->nick}<br>";
        $text .= "Name: " . $this->user->person->name ."<br>";
        $text .= "IdSetor: ".$this->user->idsector."<br>"; 
        $text .= "Grupos:<br>";
        $this->user->retrieveAssociation('groups');
        for($i=0;$i<count($this->user->groups);$i++) 
          $text .= "&nbsp;&nbsp;&nbsp;Grupo: ". $this->user->groups[$i]->group . "<br>";
        $this->divRight->setControls(array(new MThemeBox('[User]', $text)));
    }

    public function btnPost2_click()
    {
        $this->user->getProxyById(1);
        $text = "Login: {$this->user->login}<br>";
        $text .= "Password: {$this->user->password}<br>";
        $text .= "Nick: {$this->user->nick}<br>";
        $text .= "Name: " . $this->user->person->name ."<br>";
        $text .= "Setor: ".$this->user->sector->nick."<br>"; 
        $this->divRight->setControls(array(new MThemeBox('[User as Proxy]', $text)));
    }

    public function btnPost3_click()
    {
        $query = $this->user->proxyByLogin('%a%');
        foreach($query->result as $row) 
        {
           $text .= "<br>IdUser: " . $row[0];
           $text .= "<br>Login: " . $row[1] . "<br>";
        }
        $this->divRight->setControls(array(new MThemeBox('[List User as proxyQuery]', $text)));
    }

    public function btnPost4_click()
    {
        $cursor = $this->user->proxyCursorByLogin('%a%');
        while ($obj = $cursor->getObject()) 
        {
           $text .= "<br>Idperson: " . $obj->idperson;
           $text .= "<br>Iduser: " . $obj->iduser;
           $text .= "<br>Login: " . $obj->login . "<br>";
        }
        $this->divRight->setControls(array(new MThemeBox('[List User as proxyCursor]', $text)));
    }

    public function btnPost5_click()
    {
        $this->sector->getById(2);
        $text = "IdSector: {$this->sector->id}<br>";
        $text .= "Nick: {$this->sector->nick}<br>";
        $text .= "Name: {$this->sector->name}<br>";
        $text .= "Usuarios:<br>";
        for($i=0;$i<count($this->sector->users);$i++) 
          $text .= "&nbsp;&nbsp;&nbsp;User login: ". $this->sector->users[$i]->login . "<br>";
        $this->divRight->setControls(array(new MThemeBox('[Sector]', $text)));
    }

    public function btnPost6_click()
    {
        $this->group->getById(1);
        $text = "IdGroup: {$this->group->idgroup}<br>";
        $text .= "Group: {$this->group->group}<br>";
        $text .= "Usuarios:<br>";
        $this->group->retrieveAssociation('users');
        for($i=0;$i<count($this->group->users);$i++) 
          $text .= "&nbsp;&nbsp;&nbsp;User login: ". $this->group->users[$i]->login . "<br>";
        $this->divRight->setControls(array(new MThemeBox('[Group]', $text)));
    }

    public function btnPost7_click()
    {
        $query = $this->group->listAll();
        $this->divRight->setControls(array(new MTableRaw('[ListAll Group]', $query->result)));
    }

    public function btnPost8_click()
    {
        $query = $this->group->listByName('p%');
        $this->divRight->setControls(array(new MTableRaw('[ListByName Group]', $query->result)));
    }

    public function btnPost9_click()
    {
        $query = $this->group->listByNamePar('E');
        $this->divRight->setControls(array(new MTableRaw('[ListByName-Parâmetros Group]', $query->result)));
    }

    public function btnPost10_click()
    {
        $cursor = $this->group->cursorByName('P');
        while ($obj = $cursor->getObject()) 
        {
           $text .= "<br>Group: " . $obj->group . "<br>";
           $obj->retrieveAssociation('users');
           for($i=0;$i<count($obj->users);$i++) 
              $text .= "&nbsp;&nbsp;-&nbsp;User Login: " . $obj->users[$i]->login . "<br>";
        }
        $this->divRight->setControls(array(new MThemeBox('[CursorByName Group]', $text)));
    }

    public function btnPost11_click()
    {
        $this->student->getById('20051256');
        $text = "Number: {$this->student->number}<br>";
        $text .= "Situation: {$this->student->situation}<br>";
        $text .= "Idperson: {$this->student->idperson}<br>";
        $text .= "Name: " . $this->student->name ."<br>";
        $this->divRight->setControls(array(new MThemeBox('[Student - herança]', $text)));
    }

    public function btnPost12_click()
    {   global $MIOLO;
        $this->group->group = 'PERSISTENCE';
        $user1 = $MIOLO->getBusiness('example','user');
        $user1->getById(1);
        $user2 = $MIOLO->getBusiness('example','user');
        $user2->getById(3);
        $user3 = $MIOLO->getBusiness('example','user');
        $user3->getById(7);
        $this->group->addUser($user1);
        $this->group->addUser($user2);
        $this->group->addUser($user3);
        $this->group->save();
        $text = "IdGroup: {$this->group->idgroup}<br>";
        $text .= "Group: {$this->group->group}<br>";
        $text .= "Usuarios:<br>";
        $this->group->retrieveAssociation('users');
        for($i=0;$i<count($this->group->users);$i++) 
          $text .= "&nbsp;&nbsp;&nbsp;User login: ". $this->group->users[$i]->login . "<br>";
        $this->divRight->setControls(array(new MThemeBox('[New Group]', $text)));
    }

    public function btnPost13_click()
    {   global $MIOLO;
        $this->user->person = $this->person->getById(1);
        $this->user->idsector = 1;
        $this->user->login = 'PERSISTENCE';
        $this->user->nick = 'PTC';
        $this->user->password = 'PERSISTENCE';
        $this->user->save();
        $text = "IdUser: {$this->user->iduser}<br>";
        $text .= "Login: {$this->user->login}<br>";
        $text .= "Password: {$this->user->password}<br>";
        $text .= "Nick: {$this->user->nick}<br>";
        $text .= "Name: " . $this->user->person->name ."<br>";
        $text .= "IdSetor: ".$this->user->idsector."<br>"; 
        $this->divRight->setControls(array(new MThemeBox('[New User]', $text)));
    }

    public function btnPost14_click()
    {   global $MIOLO;
        $this->student = $MIOLO->getBusiness('example','student');
        $this->student->number = '199924005';
        $this->student->situation = 'Matriculado';
        $this->student->name = 'Persistence Silva';
        $this->student->save(); 
        $this->student->getById('199924005');
        $text = "Number: {$this->student->number}<br>";
        $text .= "Situation: {$this->student->situation}<br>";
        $text .= "Idperson: {$this->student->idperson}<br>";
        $text .= "Name: " . $this->student->name ."<br>";
        $this->divRight->setControls(array(new MThemeBox('[New Student]', $text)));
    }

    public function btnPost15_click()
    {   global $MIOLO;
        $this->group->getById(52);
        $this->group->delete();
        $this->divRight->setControls(array(new MThemeBox('[Delete Group]', $text)));
    }

    public function btnPost16_click()
    {   global $MIOLO;
        $this->sector->getById(1);
        $this->sector->delete();
        $this->divRight->setControls(array(new MThemeBox('[Delete Sector]', $text)));
    }

    public function btnPost17_click()
    {   global $MIOLO;
        $this->group->getById(60);
        $this->group->group = 'PERSISTENCE59';
        $this->group->retrieveAssociation('users');
        $this->group->users[1] = NULL;
        $this->group->save();
        $text = "IdGroup: {$this->group->idgroup}<br>";
        $text .= "Group: {$this->group->group}<br>";
        $text .= "Usuarios:<br>";
        $this->group->retrieveAssociation('users');
        for($i=0;$i<count($this->group->users);$i++) 
          $text .= "&nbsp;&nbsp;&nbsp;User login: ". $this->group->users[$i]->login . "<br>";
        $this->divRight->setControls(array(new MThemeBox('[Update Group]', $text)));
    }

    public function btnPost19_click()
    {
        $criteria = $this->group->getCriteria();
        $criteria->setDistinct(true);
        $criteria->addCriteria('group','LIKE',"'P%'");
        $query = $criteria->retrieveAsQuery();
        $this->divRight->setControls(array(new MThemeBox('SQL', '<br>'. $query->sql . '<br>')));
        $this->divRight->setControls(array(new MTableRaw('[List Group]', $query->result)));
    }

    public function btnPost20_click()
    {
        $criteria = $this->group->getCriteria();
        $criteria->addOrderAttribute('group');
        $query = $criteria->retrieveAsQuery();
        $this->divRight->setControls(array(new MThemeBox('SQL', '<br>'. $query->sql . '<br>')));
        $this->divRight->setControls(array(new MTableRaw('[List Group - Order]', $query->result)));
    }

    public function btnPost21_click()
    {
        $criteria = $this->group->getCriteria();
        $cc = new CriteriaCondition;
        $cc->addCriteria($criteria->getCriteria('group','LIKE',"?"));
        $cc->addOrCriteria($criteria->getCriteria('group','LIKE',"'C%'"));
        $criteria->addCriteria('group','LIKE',"'F%'");
        $criteria->addOrCriteria($cc);
        $query = $criteria->retrieveAsQuery("A%");
        $this->divRight->setControls(array(new MThemeBox('SQL', '<br>'. $query->sql . '<br>')));
        $this->divRight->setControls(array(new MTableRaw('[List Group - Filter]', $query->result)));
    }

    public function btnPost22_click()
    {
        $criteria = $this->user->getCriteria();
        $criteria->addCriteria('sector.nick','LIKE',"'A%'");
        $query = $criteria->retrieveAsProxyQuery();
        $this->divRight->setControls(array(new MThemeBox('SQL', '<br>'. $query->sql . '<br>')));
        $this->divRight->setControls(array(new MTableRaw('[List User/Sector - join oneToOne]', $query->result)));
    }

    public function btnPost23_click()
    {
        $criteria = $this->user->getCriteria();
        $criteria->addCriteria('sector.nick','LIKE',"'A%'");
        $criteria->addColumnAttribute('login');
        $criteria->addColumnAttribute('sector.nick','Sigla');
        $query = $criteria->retrieveAsProxyQuery();
        $this->divRight->setControls(array(new MThemeBox('SQL', '<br>'. $query->sql . '<br>')));
        $this->divRight->setControls(array(new MTableRaw('[List User/Sector - join oneToOne - columns]', $query->result, $query->getColumnNames())));
    }

    public function btnPost24_click()
    {
        $criteria = $this->user->getCriteria();
        $criteria->addCriteria('groups.group','LIKE',"'P%'");
        $query = $criteria->retrieveAsProxyQuery();
        $this->divRight->setControls(array(new MThemeBox('SQL', '<br>'. $query->sql . '<br>')));
        $this->divRight->setControls(array(new MTableRaw('[List User/Group - join manyToMany]', $query->result, $query->getColumnNames())));
    }

    public function btnPost25_click()
    {
        $criteria = $this->group->getCriteria();
        $criteria->addColumnAttribute('group');
        $criteria->addColumnAttribute('count(users.iduser)');
        $criteria->addGroupAttribute('group');
        $query = $criteria->retrieveAsQuery();
        $this->divRight->setControls(array(new MThemeBox('SQL', '<br>'. $query->sql . '<br>')));
        $this->divRight->setControls(array(new MTableRaw('[List Group - join + groupby]', $query->result)));
    }

    public function btnPost26_click()
    {
        $criteria = $this->group->getCriteria();
        $criteria->addColumnAttribute('group');
        $criteria->addColumnAttribute('count(users.iduser)');
        $criteria->addGroupAttribute('group');
        $criteria->addHavingCriteria('count(users.iduser)','>','2');
        $query = $criteria->retrieveAsQuery();
        $this->divRight->setControls(array(new MThemeBox('SQL', '<br>'. $query->sql . '<br>')));
        $this->divRight->setControls(array(new MTableRaw('[List Group - join + groupby + having]', $query->result)));
    }

    public function btnPost27_click()
    {
        $criteria = $this->group->getCriteria();
        $values = array('OO','PHP');
        $criteria->addCriteria('group','IN', $values);
        $query = $criteria->retrieveAsQuery();
        $this->divRight->setControls(array(new MThemeBox('SQL', '<br>'. $query->sql . '<br>')));
        $this->divRight->setControls(array(new MTableRaw('[List Group - in]', $query->result)));
    }

    public function btnPost28_click()
    {
        $criteria = $this->group->getCriteria();
        $criteria->setAlias('G');
        $criteria->addColumnAttribute('G.idgroup');
        $criteria->addColumnAttribute('G.group');
        $criteria->addCriteria('group','LIKE', "'P%'");
        $query = $criteria->retrieveAsQuery();
        $this->divRight->setControls(array(new MThemeBox('SQL', '<br>'. $query->sql . '<br>')));
        $this->divRight->setControls(array(new MTableRaw('[List Group - alias]', $query->result)));
    }

    public function btnPost29_click()
    {
        $criteria = $this->group->getCriteria();
        $criteria->setAlias('G');
        $criteria->setAssociationAlias('users','U');
        $criteria->addColumnAttribute('G.idgroup');
        $criteria->addColumnAttribute('G.group');
        $criteria->addColumnAttribute('U.iduser');
        $criteria->addCriteria('group','=', "'PHP'");
        $query = $criteria->retrieveAsQuery();
        $this->divRight->setControls(array(new MThemeBox('SQL', '<br>'. $query->sql . '<br>')));
        $this->divRight->setControls(array(new MTableRaw('[List Group - association join alias]', $query->result)));
    }

    public function btnPost30_click()
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
        $this->divRight->setControls(array(new MThemeBox('SQL', '<br>'. $query->sql . '<br>')));
        $this->divRight->setControls(array(new MTableRaw('[List Group - forced join alias]', $query->result)));
    }

    public function btnPost31_click()
    {
        $criteria = $this->sector->getCriteria();
        $criteria->setAutoAssociationAlias('S1','S2');
        $criteria->addColumnAttribute('S1.nick','parent');
        $criteria->addColumnAttribute('S2.nick','child');
        $criteria->addCriteria('S1.id', '=', 'S2.parent');
        $query = $criteria->retrieveAsQuery();
        $this->divRight->setControls(array(new MThemeBox('SQL', '<br>'. $query->sql . '<br>')));
        $this->divRight->setControls(array(new MTableRaw('[List Group - auto-relation]', $query->result, $query->getColumnNames())));
    }

    public function btnPost32_click()
    {
        $subCriteria = $this->user->getCriteria();
        $subCriteria->addCriteria('sector.nick','LIKE',"'A%'");
        $subCriteria->addColumnAttribute('iduser');
        $criteria = $this->user->getCriteria();
        $criteria->addCriteria('iduser','IN', $subCriteria);
        $query = $criteria->retrieveAsQuery();
        $this->divRight->setControls(array(new MThemeBox('SQL', '<br>'. $query->sql . '<br>')));
        $this->divRight->setControls(array(new MTableRaw('[List Group - subquery]', $query->result)));
    }

    public function btnPost33_click()
    {
        $subCriteria = $this->user->getCriteria();
        $subCriteria->setReferenceAlias('S');
        $subCriteria->addColumnAttribute('count(iduser)');
        $subCriteria->addCriteria('idsector','=',"S.idsector");
        $criteria = $this->sector->getCriteria();
        $criteria->setAlias('S');
        $criteria->addCriteria($subCriteria, '>', '150');
        $query = $criteria->retrieveAsQuery();
        $this->divRight->setControls(array(new MThemeBox('SQL', '<br>'. $query->sql . '<br>')));
        $this->divRight->setControls(array(new MTableRaw('[List Group - subquery - reference]', $query->result)));
    }

    public function btnPost34_click()
    {
        $criteria = $this->group->getCriteria();
        $criteria->addColumnAttribute('group');
        $criteria->addColumnAttribute('users.login');
        $criteria->addColumnAttribute('users.sector.nick');
        $criteria->addCriteria('users.sector.nick','=',"'ADM'");
        $query = $criteria->retrieveAsQuery();
        $this->divRight->setControls(array(new MThemeBox('SQL', '<br>'. $query->sql . '<br>')));
        $this->divRight->setControls(array(new MTableRaw('[List Group - triple association join]', $query->result)));
    }

    public function btnPost35_click()
    {
        $criteria = $this->sector->getCriteria();
        $criteria->addColumnAttribute('nick');
        $criteria->addColumnAttribute('users.person.name');
        $criteria->addColumnAttribute('count(users.iduser)');
        $criteria->addCriteria('nick','LIKE',"'PRO%'");
        $criteria->addGroupAttribute('nick');
        $criteria->addGroupAttribute('users.person.name');
        $criteria->addHavingCriteria('count(users.iduser)','=','0');
        $criteria->setAssociationType('users','right');
//        $criteria->setAssociationType('person','right');
        $query = $criteria->retrieveAsQuery();
        $this->divRight->setControls(array(new MThemeBox('SQL', '<br>'. $query->sql . '<br>')));
        $this->divRight->setControls(array(new MTableRaw('[List Group - outer join]', $query->result)));
    }

    public function btnPost36_click()
    {
        $criteria = $this->student->getCriteria();
        $criteria->addColumnAttribute('number');
        $criteria->addColumnAttribute('name');
        $criteria->addCriteria('name','LIKE',"'ZEEV%'");
        $query = $criteria->retrieveAsQuery();
        $this->divRight->setControls(array(new MThemeBox('SQL', '<br>'. $query->sql . '<br>')));
        $this->divRight->setControls(array(new MTableRaw('[List Student - inheritance]', $query->result)));
    }

    public function btnPost37_click()
    {
        $criteria = $this->group->getCriteria();
        $cc = new CriteriaCondition;
        $cc->addCriteria($criteria->getCriteria('group','LIKE',"'%A%'"));
        $cc->addOrCriteria($criteria->getCriteria('group','LIKE',"'%E%'"));
        $criteria->addCriteria('group','LIKE',"'C%'");
        $criteria->addCriteria($cc);
        $query = $criteria->retrieveAsQuery();
        $this->divRight->setControls(array(new MThemeBox('SQL', '<br>'. $query->sql . '<br>')));
        $this->divRight->setControls(array(new MTableRaw('[List Group - Compound Filter]', $query->result)));
    }

    public function btnPost38_click()
    {   global $MIOLO;
 
        try 
        {
// criando/recuperando setor 9999
            $sector = $MIOLO->getBusiness('example','sector');
            $sector->getById(9999);
            if ($sector->name == '')
            { 
               $sector->nick = 'A definir';
               $sector->name = 'Setor para Teste';
               $sector->save();
            }
// criando 3 usuarios no setor $sector->id
            $user1 = $MIOLO->getBusiness('example','user');
            $user1->person = $this->person->getById(1);
            $user1->idsector = $sector->id;
            $user1->login = uniqid();
            $user1->password = 'TESTE';
            $user1->save();
            $user2 = $MIOLO->getBusiness('example','user');
            $user2->person = $this->person->getById(1);
            $user2->idsector = $sector->id;
            $user2->login = uniqid();
            $user2->password = 'TESTE';
            $user2->save();
            $user3 = $MIOLO->getBusiness('example','user');
            $user3->person = $this->person->getById(1);
            $user3->idsector = $sector->id;
            $user3->login = uniqid();
            $user3->password = 'TESTE';
            $user3->save();
// listando usuários do setor $sector->id
            $text .= "Lista de usuarios do setor {$sector->id}:<br>";
            $sector->retrieve();
            foreach($sector->users as $user)
            {
                if (strlen($user->login) > 7) $text .= $user->login . '<br>';
            }
// removendo a associaçao com o usuario $user2
            $text .= "Removendo a associaçao com o usuario " . $user2->login . ":<br>";
            $user2->deleteAssociation('sector', $sector);
// listando usuários do setor $sector->id
            $text .= "<br>Listando novamente os usuarios do setor {$sector->id}:<br>";
            $sector->retrieve();
            foreach($sector->users as $user)
            {
                if (strlen($user->login) > 7) $text .= $user->login . '<br>';
            }
        }
        catch (Exception $e)
        {
            $text = $e->getMessage();
echo $text;
        }
        $this->divRight->setControls(array(new MThemeBox('[User: Delete Association with Sector - 1:1]', $text)));
    }

    public function btnPost39_click()
    {   global $MIOLO;
 
        try 
        {
// criando/recuperando setor 9999
            $sector = $MIOLO->getBusiness('example','sector');
            $sector->getById(9999);
            if ($sector->name == '')
            { 
               $sector->nick = 'A definir';
               $sector->name = 'Setor para Teste';
               $sector->save();
            }
// criando 3 usuarios no setor $sector->id
            $user1 = $MIOLO->getBusiness('example','user');
            $user1->person = $this->person->getById(1);
            $user1->idsector = $sector->id;
            $user1->login = uniqid();
            $user1->password = 'TESTE';
            $user1->save();
            $user2 = $MIOLO->getBusiness('example','user');
            $user2->person = $this->person->getById(1);
            $user2->idsector = $sector->id;
            $user2->login = uniqid();
            $user2->password = 'TESTE';
            $user2->save();
            $user3 = $MIOLO->getBusiness('example','user');
            $user3->person = $this->person->getById(1);
            $user3->idsector = $sector->id;
            $user3->login = uniqid();
            $user3->password = 'TESTE';
            $user3->save();
// listando usuários do setor $sector->id
            $text .= "Lista de usuarios do setor {$sector->id}:<br>";
            $sector->retrieve();
            foreach($sector->users as $user)
            {
                if (strlen($user->login) > 7) $text .= $user->login . '<br>';
            }
// removendo a associaçao com o usuario $user2
            $text .= "Removendo a associaçao do setor {$sector->id} com os usuarios:<br> {$user1->login} and {$user3->login}";
            $sector->deleteAssociation('users', $user1);
            $sector->deleteAssociation('users', $user3);
// listando usuários do setor $sector->id
            $text .= "<br>Listando novamente os usuarios do setor {$sector->id}:<br>";
            $sector->retrieve();
            foreach($sector->users as $user)
            {
                if (strlen($user->login) > 7) $text .= $user->login . '<br>';
            }
        }
        catch (Exception $e)
        {
            $text = $e->getMessage();
        }
        $this->divRight->setControls(array(new MThemeBox('[Sector: Delete Association with User - 1:N]', $text)));
    }

    public function btnPost40_click()
    {   global $MIOLO;
 
        try 
        {
// criando novo grupo
            $group = $MIOLO->getBusiness('example','group');
            $group->group = 'Grupo para Teste';
            $group->save();
// criando 3 usuarios 
            $user1 = $MIOLO->getBusiness('example','user');
            $user1->person = $this->person->getById(1);
            $user1->idsector = 1;
            $user1->login = uniqid();
            $user1->password = 'TESTE';
            $user1->save();
            $user2 = $MIOLO->getBusiness('example','user');
            $user2->person = $this->person->getById(1);
            $user2->idsector = 1;
            $user2->login = uniqid();
            $user2->password = 'TESTE';
            $user2->save();
            $user3 = $MIOLO->getBusiness('example','user');
            $user3->person = $this->person->getById(1);
            $user3->idsector = 1;
            $user3->login = uniqid();
            $user3->password = 'TESTE';
            $user3->save();
// colocando os 3 usuários no $group
            $group->addUser($user1);
            $group->addUser($user2);
            $group->addUser($user3);
            $group->save();
// listando usuários do $group
            $text .= "Lista de usuarios do grupo {$group->group}:<br>";
            $group->retrieveAssociation('users');
            for($i=0; $i<count($group->users);$i++) 
               $text .= "&nbsp;&nbsp;&nbsp;User login: ". $group->users[$i]->login . "<br>";
// removendo a associaçao com os usuarios 
            $text .= "Removendo a associaçao do grupo {$group->group} com os usuarios:<br> {$user1->login} and {$user3->login}";
            $group->deleteAssociation('users', $user1);
            $group->deleteAssociation('users', $user3);
// listando novamente usuários do $group
            $text .= "Listando novamente usuarios do grupo {$group->group}:<br>";
            $group->retrieveAssociation('users');
            for($i=0; $i<count($group->users);$i++) 
               $text .= "&nbsp;&nbsp;&nbsp;User login: ". $group->users[$i]->login . "<br>";
        }
        catch (Exception $e)
        {
            $text = $e->getMessage();
        }
        $this->divRight->setControls(array(new MThemeBox('[Group: Delete Association with User  - N:N]', $text)));
    }

    public function btnPost41_click()
    {   global $MIOLO;
 
        try 
        {
// criando/recuperando setor 9999
            $sector = $MIOLO->getBusiness('example','sector');
            $sector->getById(9999);
            if ($sector->name == '')
            { 
               $sector->nick = 'A definir';
               $sector->name = 'Setor para Teste';
               $sector->save();
            }
// criando 3 usuarios 
            $user1 = $MIOLO->getBusiness('example','user');
            $user1->person = $this->person->getById(1);
            $user1->login = uniqid();
            $user1->password = 'TESTE';
            $user1->save();
            $user2 = $MIOLO->getBusiness('example','user');
            $user2->person = $this->person->getById(1);
            $user2->login = uniqid();
            $user2->password = 'TESTE';
            $user2->save();
            $user3 = $MIOLO->getBusiness('example','user');
            $user3->person = $this->person->getById(1);
            $user3->login = uniqid();
            $user3->password = 'TESTE';
            $user3->save();
// listando usuários do setor $sector->id
            $text .= "Lista de usuarios do setor {$sector->id}:<br>";
            $sector->retrieve();
            if (is_array($sector->users))
                foreach($sector->users as $user)
                {
                    if (strlen($user->login) > 7) $text .= $user->login . '<br>';
                }
// colocando os usuario no setor $sector->id
            $text .= "Adicionando usuarios ao setor {$sector->id} e salvando ...<br>";
            $sector->addUser($user1);
            $sector->addUser($user2);
            $sector->addUser($user3);
            $text .= "Salvando a associação...<br>";
            $sector->saveAssociation('users');
            $text .= "Lista de usuarios do setor {$sector->id}, após salvar a associação:<br>";
            $sector->retrieve();
            if (is_array($sector->users))
                foreach($sector->users as $user)
                {
                    if (strlen($user->login) > 7) $text .= $user->login . '<br>';
                }
        }
        catch (Exception $e)
        {
            $text = $e->getMessage();
        }
        $this->divRight->setControls(array(new MThemeBox('[Sector: Save Association with User]', $text)));
    }

}
?>
