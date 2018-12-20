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
 * This file handles the connection and actions for basPersonOperationProcess table
 *
 * @author Jader Osvino Fiegenbaum [jader@solis.coop.br]
 *
 * @version $Id$
 *
 * \b Maintainers \n
 * Jader Osvino Fiegenbaum [jader@solis.coop.br]
 *
 * @since
 * Class created on 23/02/2010
 *
 **/
class BusinessGnuteca3BusPersonOperationProcess extends GBusiness
{
    public $colsNoId;
    public $fullColumns;
    public $MIOLO;
    public $module;

    public $personId;
    public $operationProcess;
    
    public $personIdS;
    public $operationProcessS;


    /**
     * Class constructor
     **/
    public function __construct()
    {
        parent::__construct();
        $this->MIOLO    = MIOLO::getInstance();
        $this->module   = MIOLO::getCurrentModule();
        $this->tables   = 'basPersonOperationProcess';
        $this->colsNoId = 'operationProcess';
        $this->fullColumns = 'personId, ' . $this->colsNoId;
    }


    /**
     * List all records from the table handled by the class
     *
     * @param: None
     *
     * @returns (array): Return an array with the entire table
     *
     **/
    public function listPersonOperationProcess()
    {
    	$this->clear();
    	$this->setColumns($this->fullColumns);
    	$this->setTables($this->tables);
    	$sql = $this->select();
    	$rs = $this->query($sql);
        
    	return $rs;
    }


    /**
     * Return a specific record from the database
     *
     * @param $personId (integer): Primary key of the record to be retrieved
     *
     * @return (object): Return an object of the type handled by the class
     *
     **/
    public function getPersonOperationProcess($personId, $return=FALSE)
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
			        return $this;
		        }
		        else
		        {
		        	$result  = $rs[0];
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
    public function searchPersonOperationProcess()
    {
        $this->clear();

        if ( $v = $this->personIdS )
        {
            $this->setWhere('personId = ?');
            $data[] = $v;
        }
        if ( $v = $this->operationProcessS )
        {
            $this->setWhere('operationprocess = ?');
            $data[] = $v;
        }

        $this->setColumns($this->fullColumns);
        $this->setTables($this->tables);
        $this->setOrderBy('personId');
        $sql = $this->select($data);
        $rs  = $this->query($sql);
        
        return $rs;
    }


    /**
     * Insert a new record
     *
     * @param $data (object): An object of the type handled by the class
     *
     * @return True if succed, otherwise False
     *
     **/
    public function insertPersonOperationProcess()
    {
        $columns = 'personId,
                    operationProcess';
        $this->clear();
        $this->setColumns($columns);
        $this->setTables($this->tables);
        $sql = $this->insert( $this->associateData($this->fullColumns) );
        $rs  = $this->execute($sql);

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
    public function updatePersonOperationProcess()
    {
        $this->clear();
        $this->setColumns('operationProcess');
        $this->setTables($this->tables);
        $this->setWhere('personId = ?');
        $sql = $this->update( $this->associateData( $this->colsNoId . ', personId' ) );
        $rs  = $this->execute($sql);

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
    public function deletePersonOperationProcess($personId)
    {
        $data = array($personId);

        $this->clear();
        $this->setTables($this->tables);
        $this->setWhere('personId = ?');
        $sql = $this->delete($data);
        $rs  = $this->execute($sql);
        return $rs;
    }
    
}
?>
