<?
class frmObjects extends MForm
{
    public $group;
    public $user; 
    public $sector;
    public $person;
    public $student;
    public $test;
 
    public function __construct()
    {   
		parent::__construct('Persistence Sample - Persistent Objects');
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
        $action = $this->manager->getCurrentURL();
        $array = array(
                 new MLinkButton('btnPost1','[User with given Id]',$action),
                 new MLinkButton('btnPost2','[User as Proxy]',$action),
                 new MLinkButton('btnPost3','[Sector]',$action),
                 new MLinkButton('btnPost4','[Group]',$action),
                 new MLinkButton('btnPost5','[Student - inheritance]',$action),
                 new MLinkButton('btnPost6','[Save Sector]',$action),
                 new MLinkButton('btnPost7','[Delete Person]',$action),
                 new MLinkButton('btnPost38','[User: Delete Association with Sector - 1:1]',$action),
                 new MLinkButton('btnPost39','[Sector: Delete Association with User - 1:N]',$action),
                 new MLinkButton('btnPost40','[Group: Delete Association with User  - N:N]',$action),
                 new MLinkButton('btnPost41','[Sector: Save Association with User]',$action),

        );
        $group1 = new MBaseGroup('lbGrp1','Using Objects',$array,'vertical');
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
        $this->user->getById(3);
        $text = "Login: {$this->user->login}<br>";
        $text .= "Password: {$this->user->password}<br>";
        $text .= "Nick: {$this->user->nick}<br>";
        $text .= "Name: " . $this->user->person->name ."<br>";
        $text .= "IdSetor: ".$this->user->idSector."<br>"; 
        $text .= "<br>retrieving association groups:<br>";
        $text .= "Groups:<br>";
        $this->user->retrieveAssociation('groups');
        for($i=0;$i<count($this->user->groups);$i++) 
          $text .= "&nbsp;&nbsp;&nbsp;Group: ". $this->user->groups[$i]->group . "<br>";
        $text .= "<br>retrieving association sector:<br>";
        $this->user->retrieveAssociation('sector');
          $text .= "&nbsp;&nbsp;&nbsp;Sector Name: ". $this->user->sector->name . "<br>";

        $this->divRight->setControls(array(new MThemeBox('[User]', $text)));
    }

    public function btnPost2_click()
    {
        $this->user->getProxyById(4);
        $text .= "password and nick are empty -> it is not a proxy attribute<br><br>";
        $text .= "Login: {$this->user->login}<br>";
        $text .= "Password: {$this->user->password}<br>";
        $text .= "Nick: {$this->user->nick}<br>";
        $text .= "Name: " . $this->user->person->name ."<br>";
        $this->user->retrieveAssociation('sector');
        $text .= "Setor: ".$this->user->sector->nick."<br>"; 
        $this->divRight->setControls(array(new MThemeBox('[User as Proxy]', $text)));
    }

    public function btnPost3_click()
    {
        $this->sector->getById(12);
        $text = "IdSector: {$this->sector->id}<br>";
        $text .= "Nick: {$this->sector->nick}<br>";
        $text .= "Name: {$this->sector->name}<br>";
        $text .= "<br>retrieving association users, using inverse=true<br>:<br>";
        $this->sector->retrieveAssociation('users');
        $text .= "Usuarios:<br>";
        for($i=0;$i<count($this->sector->users);$i++) 
          $text .= "&nbsp;&nbsp;&nbsp;User login: ". $this->sector->users[$i]->login . "<br>";
        $text .= "<br>retrieving association parent:<br>";
        $this->sector->retrieveAssociation('parent');
        $text .= "Parent Sector:<br>";
        $text .= "    IdSector: {$this->sector->parent->id}<br>";
        $text .= "    Nick: {$this->sector->parent->nick}<br>";
        $text .= "    Name: {$this->sector->parent->name}<br>";
        $this->divRight->setControls(array(new MThemeBox('[Sector]', $text)));
    }

    public function btnPost4_click()
    {
        $this->group->getById(7);
        $text = "IdGroup: {$this->group->idgroup}<br>";
        $text .= "Group: {$this->group->group}<br>";
        $text .= "<br>retrieving association users:<br>";
        $this->group->retrieveAssociation('users');
        $text .= "Usuarios:<br>";
        for($i=0;$i<count($this->group->users);$i++) 
          $text .= "&nbsp;&nbsp;&nbsp;User login: ". $this->group->users[$i]->login . "<br>";
        $this->divRight->setControls(array(new MThemeBox('[Group]', $text)));
    }

    public function btnPost5_click()
    {
        $this->student->getById(4);
        $text .= "get name automatically by inheritance<br><br>";
        $text .= "Number: {$this->student->number}<br>";
        $text .= "Situation: {$this->student->situation}<br>";
        $text .= "Idperson: {$this->student->idPerson}<br>";
        $text .= "Name: " . $this->student->name ."<br>";
        $this->divRight->setControls(array(new MThemeBox('[Student - inheritance]', $text)));
    }

    function btnPost38_click()
    {   global $MIOLO;
 
        try 
        {
// criando/recuperando setor 9999
            $sector = $MIOLO->GetBusiness('tutorial','sector');
            $sector->GetById(9999);
            if ($sector->name == '')
            { 
               $sector->nick = 'A definir';
               $sector->name = 'Setor para Teste';
               $sector->save();
            }
// criando 3 usuarios no setor $sector->id
            $user1 = $MIOLO->GetBusiness('tutorial','user');
            $user1->person = $this->person->GetById(1);
            $user1->idsector = $sector->id;
            $user1->login = uniqid();
            $user1->password = 'TESTE';
            $user1->save();
            $user2 = $MIOLO->GetBusiness('tutorial','user');
            $user2->person = $this->person->GetById(1);
            $user2->idsector = $sector->id;
            $user2->login = uniqid();
            $user2->password = 'TESTE';
            $user2->save();
            $user3 = $MIOLO->GetBusiness('tutorial','user');
            $user3->person = $this->person->GetById(1);
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
        $this->AddField(new MThemeBox('[User: Delete Association with Sector - 1:1]', $text));
    }

    function btnPost39_click()
    {   global $MIOLO;
 
        try 
        {
// criando/recuperando setor 9999
            $sector = $MIOLO->GetBusiness('tutorial','sector');
            $sector->GetById(9999);
            if ($sector->name == '')
            { 
               $sector->nick = 'A definir';
               $sector->name = 'Setor para Teste';
               $sector->save();
            }
// criando 3 usuarios no setor $sector->id
            $user1 = $MIOLO->GetBusiness('tutorial','user');
            $user1->person = $this->person->GetById(1);
            $user1->idsector = $sector->id;
            $user1->login = uniqid();
            $user1->password = 'TESTE';
            $user1->save();
            $user2 = $MIOLO->GetBusiness('tutorial','user');
            $user2->person = $this->person->GetById(1);
            $user2->idsector = $sector->id;
            $user2->login = uniqid();
            $user2->password = 'TESTE';
            $user2->save();
            $user3 = $MIOLO->GetBusiness('tutorial','user');
            $user3->person = $this->person->GetById(1);
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
            $text .= "Removendo a associaçao do setor {$sector->id} com os usuarios:<br>";
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
        $this->AddField(new MThemeBox('[Sector: Delete Association with User - 1:N]', $text));
    }

    function btnPost40_click()
    {   global $MIOLO;
 
        try 
        {
// criando novo grupo
            $group = $MIOLO->GetBusiness('tutorial','group');
            $group->group = 'Grupo para Teste';
            $group->save();
// criando 3 usuarios 
            $user1 = $MIOLO->GetBusiness('tutorial','user');
            $user1->person = $this->person->GetById(1);
            $user1->idsector = 1;
            $user1->login = uniqid();
            $user1->password = 'TESTE';
            $user1->save();
            $user2 = $MIOLO->GetBusiness('tutorial','user');
            $user2->person = $this->person->GetById(1);
            $user2->idsector = 1;
            $user2->login = uniqid();
            $user2->password = 'TESTE';
            $user2->save();
            $user3 = $MIOLO->GetBusiness('tutorial','user');
            $user3->person = $this->person->GetById(1);
            $user3->idsector = 1;
            $user3->login = uniqid();
            $user3->password = 'TESTE';
            $user3->save();
// colocando os 3 usuários no $group
            $group->AddUser($user1);
            $group->AddUser($user2);
            $group->AddUser($user3);
            $group->save();
// listando usuários do $group
            $text .= "Lista de usuarios do grupo {$group->group}:<br>";
            $group->retrieveAssociation('users');
            for($i=0; $i<count($group->users);$i++) 
               $text .= "&nbsp;&nbsp;&nbsp;User login: ". $group->users[$i]->login . "<br>";
// removendo a associaçao com os usuarios 
            $text .= "Removendo a associaçao do grupo {$group->group} com os usuarios:<br>";
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
        $this->AddField(new MThemeBox('[Group: Delete Association with User  - N:N]', $text));
    }

    function btnPost41_click()
    {   global $MIOLO;
 
        try 
        {
// criando/recuperando setor 9999
            $sector = $MIOLO->GetBusiness('tutorial','sector');
            $sector->GetById(9999);
            if ($sector->name == '')
            { 
               $sector->nick = 'A definir';
               $sector->name = 'Setor para Teste';
               $sector->save();
            }
// criando 3 usuarios 
            $user1 = $MIOLO->GetBusiness('tutorial','user');
            $user1->person = $this->person->GetById(1);
            $user1->login = uniqid();
            $user1->password = 'TESTE';
            $user1->save();
            $user2 = $MIOLO->GetBusiness('tutorial','user');
            $user2->person = $this->person->GetById(1);
            $user2->login = uniqid();
            $user2->password = 'TESTE';
            $user2->save();
            $user3 = $MIOLO->GetBusiness('tutorial','user');
            $user3->person = $this->person->GetById(1);
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
            $sector->AddUser($user1);
            $sector->AddUser($user2);
            $sector->AddUser($user3);
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
        $this->AddField(new MThemeBox('[Sector: Save Association with User]', $text));
    }

}
?>
