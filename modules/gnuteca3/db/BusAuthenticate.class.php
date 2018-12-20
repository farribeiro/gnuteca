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
 * This file handles the connection and actions My Library Authenticate
 *
 * @author Eduardo Bonfandini [eduardo@solis.coop.br]
 *
 * @version $Id$
 *
 * \b Maintainers \n
 * Eduardo Bonfandini [eduardo@solis.coop.br]
 * Jamiel Spezia [jamiel@solis.coop.br]
 * Luiz Gregory Filho [luiz@solis.coop.br]
 * Moises Heberle [moises@solis.coop.br]
 *
 * @since
 * Class created on 01/08/2008
 *
 **/
class BusinessGnuteca3BusAuthenticate extends GBusiness
{
    public  $session;
    private $busPerson;
    private $busBond;
    
    const TYPE_AUTHENTICATE_ID         = 1;
    const TYPE_AUTHENTICATE_LOGIN      = 2;
    const TYPE_AUTHENTICATE_LOGIN_BASE = 3;


    /**
     * Class constructor
     **/
    function __construct()
    {
        parent::__construct();
        $this->MIOLO        = MIOLO::getInstance();
        $this->busPerson    = $this->MIOLO->getBusiness($this->module, 'BusPerson');
        $this->busBond      = $this->MIOLO->getBusiness($this->module, 'BusBond');
        $this->session      = new MSession();
    }


    /**
     * M�todo de autentica��o de usu�rio
     * @param (int) $user, sempre ir� receber o personId
     * @param (String) $password
     * @param (boolean) $createSession
     * @return boolean 
     */
    public function authenticate($user, $password, $createSession = true)
    {
        if ( !is_numeric($user) ) 
        {
            return false;
        }
        
        if ($user && $password)
        {
        	
		    if ( MUtil::getBooleanValue( MY_LIBRARY_AUTHENTICATE_LDAP ) )
		    {
                $name = $this->authenticateLdap($user, $password);
		    }
		    else
		    {
	            $name = $this->busPerson->authenticate($user, $password);
	            $name = $name[0][0];
		    }

            if ($name)
	        {
                if ($createSession)
                {
                    // save data on session
                    $this->createSession($user, $name);
                }
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
     * Make user login (authentication) using LDAP
     *
     * @param int $user the user id (personId)
     * @param string $password the password of user
     * @return $name ou false if no successfull
     */
    public function authenticateLdap($user, $pass)
    {
        $MIOLO  = MIOLO::getInstance();
        $module = MIOLO::getCurrentModule();
        
        //se o tipo de autenticação for login ou login/base, troca o personId da pessoa pelo login
        if ( ($base = MY_LIBRARY_AUTHENTICATE_TYPE == BusinessGnuteca3BusAuthenticate::TYPE_AUTHENTICATE_LOGIN_BASE) || (MY_LIBRARY_AUTHENTICATE_TYPE == BusinessGnuteca3BusAuthenticate::TYPE_AUTHENTICATE_LOGIN) )
        {
            $person = $this->busPerson->getPerson($user); //obtém a pessoa
            $login = $person->login;
            
            if ( $base )
            {
                $baseId = $person->baseLdap;
            }
        }

        try
        {
            //verifica se existe uma classe de autenticação ldap setada no module.conf, se existe, cria um objeto com a classe
            $class = strtolower($MIOLO->getConf('login.classUser'));

            if ( $class )
            {
                if ( ! ( $MIOLO->import('classes::security::' . $class, $class ) ) )
                {
                    $MIOLO->import('modules::' . $MIOLO->getConf('login.module') . '::classes::'. $class, $class, $MIOLO->php);
                }
                $authLdap = new $class($baseId);
            }
            else
            { 
                //deixado para manter compatibilidade
                $MIOLO->uses('security/mauthldap.class.php');
                $authLdap = new MAuthLdap();
            }
        }
        catch ( Exception $e )
        {
            return false;
        }
        
        //autentica usuário, sem gravar na sessao (3o parametro)
        if ( $authLdap->authenticate($login ? $login : $user, $pass, false) )
        {
            $data = $this->busPerson->getBasicPersonInformations($user);
            return $data->name;
        }
        else
        {
            return false;
        }
    }
    
    /**
     * Método que lista as bases ldap configuradas no miolo.conf
     * @return (array) de bases 
     */
    public static function listMultipleLdap()
    {
        $MIOLO = MIOLO::getInstance();
        $xml = new MSimpleXML($MIOLO->getConf('home.etc') . '/miolo.conf'); //obtém o miolo.conf em xml
        $conf = $xml->toSimpleArray($conf); //converte xml em array
        
        $values = array();
        if ( is_array($conf) )
        {
            //percorre o array para obter as bases
            foreach( $conf as $key => $value )
            {
                
                if ( strpos($key, 'login.ldap.base_') === 0 )
                {
                    $baseE = explode('.', $key);
                    
                    if ($baseE[3] == 'name' )
                    {
                        $values[$baseE[2]][] = $baseE[2];
                        $values[$baseE[2]][] = $value;
                    }
                }
            }
        }

        return $values;
    }
    

    /**
     * Save login in SESSION
     **/
    public function createSession($user, $name)
    {
        $this->session->setValue('MyLibraryLogged',true);
        $this->session->setValue('MyLibraryUserCode',$user);
        $this->session->setValue('MyLibraryUserName',$name);
    }

    /**
     * Change the password of an user
     *
     * @param integer $user code
     * @param string $password the password
     * @param string $retype of password
     * @return boolean
     */
    public function changePassword($user, $password, $retype)
    {
		$ok = $this->busPerson->changePassword($user, $password, $retype);
		return $ok;
    }


    /**
    * Make logoff of current logged user
    *
    */
    public static function logoff()
    {
        $MIOLO   = MIOLO::getInstance();
        $session = $MIOLO->getSession();

        $session->setValue('MyLibraryLogged',null);
        $session->setValue('MyLibraryUserCode',null);
        $session->setValue('MyLibraryUserName',null);
    }


    /**
    * Verify if some user is logged
    */
    public static function checkAcces()
    {
        $MIOLO   = MIOLO::getInstance();
        $session = $MIOLO->getSession();
        return $session->getValue('MyLibraryLogged');
    }


    /**
    * Get the code of logged user
    */
    public static function getUserCode()
    {
    	$MIOLO   = MIOLO::getInstance();
        $session = $MIOLO->getSession();
        return $session->getValue('MyLibraryUserCode');
    }


    /**
    * Get the name of logged user
    */
    public static function getUserName()
    {
        $MIOLO   = MIOLO::getInstance();
        $session = $MIOLO->getSession();
        return $session->getValue('MyLibraryUserName');
    }



    /**
     * retorna o link da pessoa
     *
     * @return int
     */
    public function getPersonLink()
    {
        if(!$this->getUserCode())
        {
            return false;
        }

        if($bond = $this->busBond->getPersonLink($this->getUserCode()))
        {
            return $bond->linkId;
        }

        return false;
    }

}
?>
