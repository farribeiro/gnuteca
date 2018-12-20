<?php
/**
 * <--- Copyright 2005-2011 de Solis - Cooperativa de Soluções Livres Ltda. e
 * Univates - Centro Universitário.
 * 
 * Este arquivo é parte do programa Gnuteca.
 * 
 * O Gnuteca é um software livre; você pode redistribuí-lo e/ou modificá-lo
 * dentro dos termos da Licença Pública Geral GNU como publicada pela Fundação
 * do Software Livre (FSF); na versão 2 da Licença.
 * 
 * Este programa é distribuído na esperança que possa ser útil, mas SEM
 * NENHUMA GARANTIA; sem uma garantia implícita de ADEQUAÇÃO a qualquer MERCADO
 * ou APLICAÇÃO EM PARTICULAR. Veja a Licença Pública Geral GNU/GPL em
 * português para maiores detalhes.
 * 
 * Você deve ter recebido uma cópia da Licença Pública Geral GNU, sob o título
 * "LICENCA.txt", junto com este programa, se não, acesse o Portal do Software
 * Público Brasileiro no endereço www.softwarepublico.gov.br ou escreva para a
 * Fundação do Software Livre (FSF) Inc., 51 Franklin St, Fifth Floor, Boston,
 * MA 02110-1301, USA --->
 * 
 * @author Moises Heberle [moises@solis.coop.br]
 *
 * @version $Id$
 *
 * \b Maintainers \n
 * Eduardo Bonfandini [eduardo@solis.coop.br]
 * Jamiel Spezia [jamiel@solis.coop.br]
 * Jader Osvino Fiegenbaum [jader@solis.coop.br]
 *
 * @since
 * Class created on 06/08/2008
 *
 **/
class BusinessGnuteca3BusPerson extends GBusiness
{
    public $colsNoId;
    public $fullColumns;
    public $MIOLO;
    public $module;
    public $busBond;
    public $busPenalty;
    public $busLibraryUnitConfig;
    public $bondOrderBy;
    public $busPersonOperationProcess;
    
    /**
     * @var BusinessGnuteca3BusPhone
     */
    public $busPhone;
    
    /**
     * @var BusinessGnuteca3BusDocument
     */
    public $busDocument;

    public $personId;
    public $personName;
    public $city;
    public $zipCode;
    public $location;
    public $number;
    public $complement;
    public $neighborhood;
    public $email;
    public $password;
    public $operationProcess;
    public $login;
    public $baseLdap;
    public $personGroup;
    public $sex;
    public $dateBirth;
    public $profession;
    public $school;
    public $workPlace;
    public $observation;
    public $observation_;

    public $personIdS;
    public $personNameS;
    public $cityS;
    public $zipCodeS;
    public $locationS;
    public $numberS;
    public $complementS;
    public $neighborhoodS;
    public $emailS;
    public $passwordS;
    public $loginS;
    public $baseLdapS;
    public $personGroupS;
    public $sexS;
    public $dateBirthS;
    public $professionS;
    public $schoolS;
    public $workPlaceS;
    public $observationS;
    
     /**
     * Filtra por link ativo da pessoa
     * @var array
     */
    public $activeBondS;

    public $bond;
    public $penalty;
    public $personLibraryUnit;
    public $phone;
    public $document;

    /**
     * Class constructor
     **/
    public function __construct()
    {
        parent::__construct();
        $this->MIOLO    = MIOLO::getInstance();
        $this->tables   = 'basPerson';
        $this->colsNoId = 'name as personName,
                           city,
                           zipCode,
                           location,
                           number,
                           complement,
                           neighborhood,
                           email,
                           password,
                           login,
                           baseLdap,
                           personGroup,
                           sex,
                           dateBirth,
                           profession,
                           school,
                           workPlace,
                           observation';                           

        $this->fullColumns = 'personId, ' . $this->colsNoId;
        $this->busBond              = $this->MIOLO->getBusiness($this->module, 'BusBond');
        $this->busPenalty           = $this->MIOLO->getBusiness($this->module, 'BusPenalty');
        $this->busPersonLibraryUnit = $this->MIOLO->getBusiness($this->module, 'BusPersonLibraryUnit');
        $this->busLibraryUnitConfig = $this->MIOLO->getBusiness($this->module, 'BusLibraryUnitConfig');
        $this->busPhone = $this->MIOLO->getBusiness($this->module, 'BusPhone');
        $this->busDocument = $this->MIOLO->getBusiness($this->module, 'BusDocument');
    }

    /**
     * Obtém o id da pessoa através do login e base Ldap
     * @param string/int $login login do usuário
     * @param int $base base Ldap
     * @return int código do usuário 
     */
    public function getPersonIdFormLoginAndBase($login, $base = null)
    {
        $this->clear();
        $this->setTables($this->tables);
        $this->setColumns('personId');
        $this->setWhere('login = ?');
        $args[] = $login;
        
        if ( $base )
        {
            $this->setWhere('baseLdap = ?');
            $args[] = $base;
        }
        
        $sql = $this->select($args);
        $result = $this->query($sql, true);
        
        return $result[0];
    }

    /**
     * Return a specific record from the database
     *
     * @param $personId (integer): Primary key of the record to be retrieved
     *
     * @return (object): Return an object of the type handled by the class
     *
     **/
    public function getPerson($personId, $return=FALSE, $onlyActive = false )
    {
    	if (!$personId || !is_numeric($personId))
    	{
    		return false;
    	}
    	else
    	{
	        $data = array($personId);

	        $this->clear();
	        $this->setColumns($this->fullColumns);
	        $this->setTables($this->tables);
	        $this->setWhere('personId = ?');
	        $sql = $this->select($data);
	        $rs  = $this->query($sql, TRUE);

	        if ($rs)
	        {
		        if ( !$return )
		        {
			        $this->setData( $rs[0] );
			        $this->email = $rs[0]->email; //o setData para o campo email por algum motivo nao esta funcionando corretamente

			        $this->busBond->personIdS = $personId;
			        $this->bond = $this->busBond->searchBond(TRUE, $this->bondOrderBy);

			        $this->busPenalty->personIdS = $personId;
			        $this->penalty = $this->busPenalty->searchPenalty(TRUE, NULL, FALSE);

			        $this->busPersonLibraryUnit->personIdS = $personId;
			        $this->personLibraryUnit = $this->busPersonLibraryUnit->searchPersonLibraryUnit(TRUE);
			        
			        $this->busPhone->personIdS = $personId;
			        $this->phone = $this->busPhone->searchPhone(true);
                    
                    $this->busDocument->personIdS = $personId;
			        $this->document = $this->busDocument->searchDocument(true);
			        
			        return $this;
		        }
		        else
		        {
		        	$result  = $rs[0];
			        $this->busBond->personIdS = $personId;

                    //mostra somente link ativo
                    if ( $onlyActive === 'ALL' )
                    {
                        $this->busBond->allActive = true;
                    }
                    else if ( $onlyActive == true )
			        {
                        $this->busBond->byActive = true;
			        }
			        
			        $result->bond  = $this->busBond->searchBond(TRUE);

			        $this->busPenalty->personIdS = $personId;
			        $result->penalty = $this->busPenalty->searchPenalty(TRUE, NULL, TRUE);

			        $this->busPersonLibraryUnit->personIdS = $personId;
			        $result->personLibraryUnit = $this->busPersonLibraryUnit->searchPersonLibraryUnit(TRUE);
                    
                    $this->busDocument->personIdS = $personId;
			        $result->document = $this->busDocument->searchDocument(true);
			        
			        return $result;
		        }
	        }
    	}
    }


    /**
     * Do a search on the database table handled by the class
     *
     * @param $filters (object): Search filters
     *
     * @return (array): An array containing the search results
     **/
    public function searchPerson($returnAsObject)
    {
        $this->clear();

        if ( $v = $this->personIdS )
        {
            $this->setWhere('personId = ?');
            $data[] = $v;
        }
        
        if ( $v = $this->personNameS )
        {
            $this->setWhere('lower(name) LIKE lower(?)');
            $data[] = $v . '%';
        }
        
        if ( $v = $this->cityS )
        {
            $this->setWhere('lower(city) LIKE lower(?)');
            $data[] = $v . '%';
        }
        
        if ( $v = $this->zipCodeS )
        {
            $this->setWhere('zipCode = ?');
            $data[] = $v;
        }
        
        if ( $v = $this->locationS )
        {
            $this->setWhere('lower(location) LIKE lower(?)');
            $data[] = $v . '%';
        }
        
        if ( $v = $this->numberS )
        {
            $this->setWhere('number = ?');
            $data[] = $v;
        }
        
        if ( $v = $this->complementS )
        {
            $this->setWhere('lower(complement) LIKE lower(?)');
            $data[] = $v . '%';
        }
        
        if ( $v = $this->neighborhoodS )
        {
            $this->setWhere('lower(neighborhood) LIKE lower(?)');
            $data[] = $v . '%';
        }
        
        if ( $v = $this->emailS )
        {
            $this->setWhere('lower(email) LIKE lower(?)');
            $data[] = $v . '%';
        }
        
        if ( $v = $this->loginS )
        {
            $this->setWhere('login = ? ');
            $data[] = $v;
        }
      
        if ( $v = $this->baseLdapS )
        {
            $this->setWhere('baseLdap = ?');
            $data[] = $v;
        }
        
        if ( $v = $this->personGroupS )
        {
            $this->setWhere('lower(persongroup) LIKE lower(?)');
            $data[] = $v . '%';
        }
        
         if ( $v = $this->sexS )
        {
            $this->setWhere('sex = ?');
            $data[] = $v;
        }
        
        if ( $v = $this->dateBirth )
        {
            $this->setWhere('lower(dateBirth) = ?');
            $data[] = $v;
        }
        
        if ( $v = $this->professionS )
        {
            $this->setWhere('lower(profession) ILIKE lower(?)');
            $data[] = $v . '%';
        }

        if ( $v = $this->workPlaceS )
        {
            $this->setWhere('lower(workPlace) ILIKE lower(?)');
            $data[] = $v . '%';
        }
        
        if ( $v = $this->schoolS )
        {
            $this->setWhere('lower(school) ILIKE lower(?)');
            $data[] = $v . '%';
        }
        
        if ( $v = $this->observationS )
        {
            $this->setWhere('lower(observation) ILIKE lower(?)');
            $data[] = $v . '%';
        }

        if ( $this->activeBondS )
        {
            if (!is_array($this->activeBondS))
            {
                $this->activeBondS = array($this->activeBondS);
            }

            $fullColumns = $this->fullColumns.',( SELECT PL.linkid FROM basPersonLink PL LEFT JOIN basLink L ON ( L.linkId = PL.LINKID ) WHERE  PL.personID = basPerson.personId and PL.datevalidate >= now()::date ORDER BY level LIMIT 1 ) as activeLinkId';
        }
        else
        {
            $fullColumns = $this->fullColumns;
        }

        $this->setColumns($fullColumns);
        $this->setTables($this->tables);
        $this->setOrderBy('personId');
        $sql = $this->select($data);

        if ( $this->activeBondS )
        {
            $sql = "SELECT * FROM ( $sql ) as foo WHERE activeLinkId in (". implode(',', $this->activeBondS ).')';
        }

        return $this->query($sql,$returnAsObject);
    }

    /**
     * Insert a new record
     *
     * @param $data (object): An object of the type handled by the class
     *
     * @return True if succed, otherwise False
     *
     **/
    public function insertPerson()
    {
        $manual = false;
        //se no for informado código no formulário, pega o nextval
        if ( !$this->personId )
        {
            $this->personId = $this->getNextId();
        }
        else
        {
            $manual = true;
        }
        
        $columns = 'personId,
                    name,
                    city,
                    zipCode,
                    location,
                    number,
                    complement,
                    neighborhood,
                    email,
                    password,
                    login,
                    baseLdap,
                    personGroup,
                    sex,
                    dateBirth,
                    profession,
                    school,
                    workPlace,
                    observation';
        
        $this->clear();
        $this->setColumns($columns);
        $this->setTables($this->tables);

        $sql = $this->insert( $this->associateData($this->fullColumns) );
        $rs  = $this->execute($sql);
        
        if ( $rs )
        {
            if ($this->bond)
            {
                foreach ($this->bond as $value)
                {
                    $this->busBond->setData($value);
                    $this->busBond->personId = $this->personId;
                    $this->busBond->insertBond();
                }
            }

            if ($this->penalty)
            {
                foreach ($this->penalty as $value)
                {
                    $this->busPenalty->setData($value);
                    $this->busPenalty->personId = $this->personId;
                    $this->busPenalty->insertPenalty();
                }
            }

            if ( $this->phone )
            {
                foreach ( $this->phone as $key=>$value )
                {
                    $this->busPhone->setData($value);
                    $this->busPhone->personId = $this->personId;
                    $this->busPhone->insertPhone();
                }
            }

            if ($this->personLibraryUnit)
            {
                foreach ($this->personLibraryUnit as $value)
                {
                    $this->busPersonLibraryUnit->setData($value);
                    $this->busPersonLibraryUnit->personId = $this->personId;
                    $this->busPersonLibraryUnit->insertPersonLibraryUnit();
                }
            }
            
            if ( $this->document )
            {
                foreach ( $this->document as $value )
                {
                    $this->busDocument->setData($value);
                    $this->busDocument->personId = $this->personId;
                    $this->busDocument->insertDocument();
                }
            }
        }
        
        //se foi especificado codigo manual, atualiza a tabela de sequência da pessoa
        if ( $manual )
        {
            $this->updateSequenceId();
        }
        
        return $rs;
    }


    /**
     * Update data from a specific record
     *
     * @param $data (object): Data which will replace the old record data
     *
     * @return (boolean): True if succeed, otherwise False
     *
     **/
    public function updatePerson()
    {
        $this->clear();
        //Quando parâmetro CHANGE_WRITE_PERSON estiver configurado para não gravar dados do usuário. Não deve atualizar view de Pessoas.
        if (MUtil::getBooleanValue(CHANGE_WRITE_PERSON) == FALSE)
        {
            $rs = '1';
        }
        else
        {
            $this->setColumns('
                name,
                city,
                zipCode,
                location,
                number,
                complement,
                neighborhood,
                email,
                password,
                login,
                baseLdap,
                personGroup,
                sex,
                dateBirth,
                profession,
                school,
                workPlace,
                observation');
            
            $this->setTables($this->tables);
            $this->setWhere('personId = ?');
            $sql = $this->update( $this->associateData( $this->colsNoId . ', personId' ) );
            $rs  = $this->execute($sql);
        }

        if ( $this->phone )
        {
            foreach ( $this->phone as $key=>$value )
            {
                $this->busPhone->setData($value);
                $this->busPhone->personId = $this->personId;
                $this->busPhone->updatePhone();
            }
        }
        
        if ($this->bond)
        {
            foreach ($this->bond as $value)
            {
                $this->busBond->setData($value);
                $this->busBond->personId = $this->personId;
                $this->busBond->updateBond();
            }
        }

        if ($this->penalty)
        {
            foreach ($this->penalty as $value)
            {
                $this->busPenalty->setData($value);
                $this->busPenalty->personId = $this->personId;
                $this->busPenalty->updatePenalty();
            }
        }

        if ($this->personLibraryUnit)
        {
            $this->busPersonLibraryUnit->personIdS = $this->personId;
            $search = $this->busPersonLibraryUnit->searchPersonLibraryUnit(TRUE);
            if ($search)
            {
                foreach ($search as $value)
                {
                    $this->busPersonLibraryUnit->deletePersonLibraryUnit($value->libraryUnitId, $value->personId);
                }
            }
            foreach ($this->personLibraryUnit as $value)
            {
                if (!$value->removeData)
                {
                    $this->busPersonLibraryUnit->setData($value);
                    $this->busPersonLibraryUnit->personId = $this->personId;
                    $this->busPersonLibraryUnit->insertPersonLibraryUnit();
                }
            }
        }
        
        if ($this->document)
        {
            foreach ($this->document as $value)
            {
                $this->busDocument->setData($value);
                $this->busDocument->personId = $this->personId;
                $this->busDocument->updateDocument();
            }
        }
        
        return $rs;
    }


    /**
     * Delete a record
     *
     * @param $moduleConfig (string): Primary key for deletion
     * @param $parameter (string): Primary key for deletion
     *
     * @return (boolean): True if succeed, otherwise False
     *
     **/
    public function deletePerson($personId)
    {
        if ( MUtil::getBooleanValue(CHANGE_WRITE_PERSON) == FALSE )
        {
            throw new Exception( _M('As pessoas devem ser removidas no software relacionado.','gnuteca3') ); 
        }
        
        //delete telegone e documentos
        $this->busPhone->deletePhone($personId);
        $this->busDocument->deleteDocument($personId);
                
        $this->clear();
        $this->setTables($this->tables);
        $this->setWhere('personId = ?');
        $rs  = $this->execute( $this->delete(array($personId)) );
        
        if ( $rs )
        {
            //TODO incluir funcionalidade de remoção da foto
        }
        
        return $rs;
    }


    /**
     * Get constants for a specified module
     *
     * @param $moduleConfig (string): Name of the module to load values from
     *
     * @return (array): An array of key pair values
     *
     **/
    public function getPersonValues($personId)
    {
        $data = array($personId);

        $this->clear();
        $this->setColumns('personId');
        $this->setTables($this->tables);
        $this->setWhere('personId = ?');
        $sql = $this->select($data);
        $rs  = $this->query($sql);
        return $rs;
    }

    /**
     * Obtem informações básicas sobre a pessoa, código, nome, email e login
     *
     * @param integer $personId
     * @return string
     */
    public function getBasicPersonInformations($personId)
    {
        $this->clear();
        $this->setColumns('personId, name, email,login');
        $this->setTables($this->tables);
        $this->setWhere('personId = ?');
        $sql = $this->select(array($personId));
        $rs  = $this->query($sql, true);
        return $rs[0];
    }


    public function getEmail($personId)
    {
        $data = array($personId);

        $this->clear();
        $this->setColumns('email');
        $this->setTables($this->tables);
        $this->setWhere('personId = ?');
        $sql = $this->select($data);
        $rs  = $this->query($sql);

        return $rs ? $rs[0][0] : false;
    }



    public function getPassword($personId)
    {
        $data = array($personId);

        $this->clear();
        $this->setColumns('password');
        $this->setTables($this->tables);
        $this->setWhere('personId = ?');
        $sql = $this->select($data);
        $rs  = $this->query($sql);

        return $rs;
    }


    public function getNextId()
    {
        $query = $this->query("SELECT NEXTVAL('seq_personId')");
        return $query[0][0];
    }

    /**
     * Método que atualiza o id da sequência com o maior código de aluno
     *
     * @param $id
     */
    public function updateSequenceId()
    {
        return $this->execute("SELECT setval('seq_personid', (SELECT max(personId) FROM basPerson))");
    }


    /**
     * Make user login (authentication)
     *
     * @param int $user the user id (personId)
     * @param string $password the password of user
     * @return true if success
     */
    public function authenticate($user, $password)
    {
        $data = array($user, $password);

        $this->clear();
        $this->setColumns('name');
        $this->setTables($this->tables);
        $this->setWhere('personId = ?');
        $this->setWhere('password = ?');
        $sql = $this->select($data);

        $rs  = $this->query($sql);

        return $rs;
    }


    /**
     * Change the user password
     *
     * @param int $user the user code (personId)
     * @param string $password the user password
     * @param string $retype the retype of password to verify
     * @return true if change
     */
    public function changePassword($user, $password, $retype)
    {
    	if ( $password != $retype || !$password || !$retype)
    	{
    		return false;
    	}
    	else
    	{
    		if ( !$user )
    		{
    			return false;
    		}
    		else
    		{
	    		$this->getPerson($user);
	    		if ($this->personId)
	    		{
			        $this->clear();
			        $this->setColumns('password');
			        $this->setTables($this->tables);
			        $this->setWhere('personId = ?');
			        $this->password = $password;
			        $sql = $this->update( $this->associateData('password, personId' ) );
			        $rs  = $this->execute($sql);
			        return $rs;
	    		}
    		}
    	}
    }

    /**
     * Verify if user is in operation process (is making a process)
     *
     * @param integer $personId the user code
     * @return true if is in operation
     */
    public function isOperationProcess($personId)
    {
        if (!$personId)
        {
            return false;
        }
        
        $busPersonOperationProcess = $this->MIOLO->getBusiness($this->module, 'BusPersonOperationProcess');
        //testa se tem registro, caso não, retorna false
        $personOperationProcess = $busPersonOperationProcess->getPersonOperationProcess($personId, true);
        
        $diff = 0;
        if ( $personOperationProcess )
        {
	        $operationProcess = new GDate($personOperationProcess->operationProcess);
	        $now = GDate::now();
	        $diff = $now->diffDates($operationProcess, GDate::ROUND_DOWN);

            if ( ($diff->seconds / 60) < OPERATION_PROCESS_TIME )
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        else
        {
            return false;
        }
    }

    /**
     * Remove o processo de operação para uma pessoa
     *
     * @param unknown_type $personId
     * @return unknown
     */
    public function removeOperationProcess($personId)
    {
        $busPersonOperationProcess = $this->MIOLO->getBusiness($this->module, 'BusPersonOperationProcess');
        
    	if (!$personId || !is_numeric($personId) ) //se não existir ou se não for número
    	{
    		return false;
    	}
    	else
    	{
    		return $busPersonOperationProcess->deletePersonOperationProcess($personId);
    	}
    }

    /**
     * Define o processo de operação para uma pessoa
     *
     * @param unknown_type $personId
     * @return unknown
     */
    public function setOperationProcess($personId)
    {
        $busPersonOperationProcess = $this->MIOLO->getBusiness($this->module, 'BusPersonOperationProcess');
        
        if (!$personId)
        {
            return FALSE;
        }
        
        $data = array();
        $data[] = $personId;
        
        //pega hora e data atual em timestamp
        $this->clear();
        $this->setColumns('now()');
        $resultData = $this->query($this->select());
        $dateTime = $resultData[0][0];
        
        $busPersonOperationProcess->personId = $personId;
        $busPersonOperationProcess->operationProcess = $dateTime;
        
        $operationProcess = $busPersonOperationProcess->getPersonOperationProcess($personId, true);
        //atualiza se já existe processo, senão insere
        if ( strlen($operationProcess->operationProcess) > 0 )
        {
        	$busPersonOperationProcess->updatePersonOperationProcess();
        }
        else 
        {
        	$busPersonOperationProcess->insertPersonOperationProcess();
        }
    }


    public function checkAccessLibraryUnit($personId, $libraryUnitId)
    {
        $className = $this->busLibraryUnitConfig->getValueLibraryUnitConfig($libraryUnitId, 'CLASS_USER_ACCESS_IN_THE_LIBRARY');
        if (empty($className))
        {
            return true;
        }
        else
        {
            $bus = MIOLO::getInstance()->getBusiness($this->module, $className);
            return $bus->checkAccess($personId, $libraryUnitId);
        }
    }
    
    /**
     * Método que verifica se usuário existe no ldap e insere a pessoa no ldap
     *
     * @param (String) $login
     * @param (int) $baseId
     * @param (String) $password
     * @param (boolean) $verifyPersonInLdap
     * @return personId ou booleano 
     */
    public function insertLdapPerson($login, $baseId, $password = null, $verifyPersonInLdap = false)
    {
        //obtém a classe de autenticação configurada
        $class = strtolower($this->MIOLO->getConf('login.classUser'));

        if ( $class && $baseId )
        {
            if ( ! ( $this->MIOLO->import('classes::security::' . $class, $class ) ) )
            {
                $this->MIOLO->import('modules::' . $this->MIOLO->getConf('login.module') . '::classes::'. $class, $class, $this->MIOLO->php);
            }

            $authLdap = new $class($baseId);
        }
        else
        {
            return false;
        }
        
        //busca os dados no ldap
        $ldapData = $authLdap->searchData($login);

       
        //verifica se usuário existe no ldap
        if ( $password )
        {
              $exists = $authLdap->authenticate($login, $password) && ( $ldapData['count'] > 0);
        }
        else
        {
            $exists = ($ldapData['count'] > 0);
        }
        
        //caso esse parametro seja passado como true, retorna a verficação se pessoa existe no ldap
        if ( $verifyPersonInLdap )
        {
            return $exists;
        }
        
        //trata os dados da prerência MY_LIBRARY_LDAP_INSERT_USER
        $data = new stdClass();

        if ( $exists )
        {
            //faz o parse da configuração, ja busca da base passada por parâmetro
            $lines = explode("\n", MY_LIBRARY_LDAP_INSERT_USER);
            $break = false;

            if ( is_array($lines) )
            {
                foreach ( $lines as $i=> $line )
                {
                    $conf = explode(';', $line);

                    if ( is_array($conf) )
                    {
                        $first = true;

                        foreach ( $conf as $k => $val )
                        {
                            $values = explode('=', $val);

                            if ( $first )
                            {
                                if ( $values[0] == $baseId )
                                {
                                    $break = true;
                                }
                                    $data->base = $values[0];
                            }
                            else
                            {
                                $data->$values[0] = $values[1];
                            }
                            $first = false;
                        }
                    }
                    
                    if ( $break )
                    {
                        break;
                    }
                }
            }
            
            $ldapData = $ldapData[0]; //obtém o primeiro registro
          
            //se não achar configuração para base, retorna false
            if ( strlen($data->base) == 0 )
            {
                return false;
            }
            
            $this->personName = $ldapData[strtolower($data->nome)][0]; //obtém o nome da pessoa do ldap

            if ( strlen( $this->personName) > 0 )
            {
                $this->email = $ldapData[strtolower($data->email)][0]; //obtém o e-mail do ldap
                $this->login = $ldapData[strtolower($data->login)][0]; //obtém o login do ldap
                $this->baseLdap = $baseId;

                //seta o vínculo da pessoa
                $bond = new stdClass();
                $bond->linkId = $data->vinculo;
                $bond->dateValidate = $data->validade;
                $this->bond = array($bond);

                //insere a pessoa
                $ok = $this->insertPerson(); //insere a pessoa no Gnuteca

               return $ok ? $this->personId : false;
            }
            else
            {
                return false;
            }
        }
        else
        {
            return false;
        }
        
    }
    
    /**
     * Retorna se a pessoa tem restrições no gnuteca.
     * Verifica multas, penalidades e empréstimos em aberto.
     * 
     * @return boolean
     */
    public function nothingInclude($personId)
    {
        if ( ! $personId )
        {
            throw new Exception( _M("É necessário um código de pessoa para obter suas restrições.",'gnuteca3') );
        }
        
        $result = $this->query("SELECT * FROM gtcNadaConsta($personId);");
        
        return  $result[0][0] == DB_TRUE;
    }
    
    /**
     * Obtem uma listagem com as restrições da pessoa com o Gnuteca
     * 
     * @param integer $personId
     * @return array
     */
    public function getRestrictions( $personId )
    {
        if ( ! $personId )
        {
            throw new Exception( _M("É necessário um código de pessoa para obter suas restrições.",'gnuteca3') );
        }
        
        return $this->query("SELECT * FROM gtcObterRestricoes($personId);");
    }
}
?>
