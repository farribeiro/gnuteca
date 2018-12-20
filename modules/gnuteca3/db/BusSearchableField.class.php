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
 * This file handles the connection and actions for gtcSearchableField table
 *
 * @author Moises Heberle [moises@solis.coop.br]
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
 * Class created on 01/12/2008
 *
 **/


/**
 * Class to manipulate the basConfig table
 **/
class BusinessGnuteca3BusSearchableField extends GBusiness
{
    public $busSearchableFieldAccess;
    public $group;
    public $libraryUnitId;
    public $searchableFieldId;
    public $description;
    public $field;
    public $identifier;
    public $observation;
    public $isRestricted;
    public $level;
    public $fieldType;
    public $helps;

    public $searchableFieldIdS;
    public $descriptionS;
    public $fieldS;
    public $identifierS;
    public $observationS;
    public $isRestrictedS;
    public $levelS;


    public function __construct()
    {
        $this->MIOLO  = MIOLO::getInstance();
        $this->module = MIOLO::getCurrentModule();
        $this->table = 'gtcSearchableField';
        $this->pkeys = 'searchableFieldId';
        $this->cols  = 'description,
                        field,
                        identifier,
                        observation,
                        isRestricted,
                        level,
                        fieldType,
                        helps';
        parent::__construct($this->table , $this->pkeys, $this->cols);
        $this->busSearchableFieldAccess   = $this->MIOLO->getBusiness($this->module, 'BusSearchableFieldAccess');
    }


    public function insertSearchableField()
    {
        $data = $this->associateData( $this->cols );
        parent::clear();
        parent::setColumns($this->cols);
        parent::setTables($this->table);
        $sql=parent::insert($data);
        $ok = parent::execute();

        if ($this->group && $ok)
        {
            foreach ($this->group as $value)
            {
                $this->busSearchableFieldAccess->setData($value);
                $this->busSearchableFieldAccess->searchableFieldId = $this->getNextSearchableFieldId();
                $this->busSearchableFieldAccess->insertSearchableFieldAccess();
            }
        }
        return $ok;
    }


    public function updateSearchableField()
    {
       // return $this->autoUpdate();
        $data = $this->associateData( $this->cols . ', searchableFieldId' );
        $this->clear();
        $this->setWhere('searchableFieldId = ?');
        $this->setColumns($this->cols);
        $this->setTables($this->tables);
        $sql = $this->update($data);
        $rs  = $this->execute($sql);

        if ($this->group && $rs)
        {
            $this->busSearchableFieldAccess->deleteByGroup($this->searchableFieldId);
            foreach ($this->group as $value)
            {
                $this->busSearchableFieldAccess->setData($value);
                $this->busSearchableFieldAccess->insertSearchableFieldAccess();
            }
        }
        return $rs;
    }


    public function deleteSearchableField($searchableFieldId)
    {
        if ($searchableFieldId)
        {
            $this->busSearchableFieldAccess->searchableFieldS = $searchableField;
            $search = $this->busSearchableFieldAccess->searchSearchableFieldAccess(TRUE);
            if ($search)
            {
                foreach ($search as $value)
                {
                    $this->busSearchableFieldAccess->deleteSearchableFieldAccess($searchableFieldId, $value->linkId);
                }
            }
        }

        return $this->autoDelete($searchableFieldId);
    }


    public function getSearchableField($searchableFieldId)
    {
        $this->clear();

        $this->busSearchableFieldAccess->searchableFieldIdS = $searchableFieldId;
        $this->group = $this->busSearchableFieldAccess->searchSearchableFieldAccess(TRUE);

        return $this->autoGet($searchableFieldId);
    }


    public function searchSearchableField($object = false)
    {
        $this->clear();
        $this->setColumns($this->pkeys . ',' . $this->cols);
        $this->setTables('gtcSearchableField');
        if ( $this->searchableFieldIdS )
        {
            $this->setWhere('searchableFieldId = ?');
            $data[] = $this->searchableFieldIdS;
        }
        if ($this->descriptionS)
        {
            $this->descriptionS = str_replace(' ','%', $this->descriptionS);
            $this->setWhere('lower(description) LIKE lower(?)');
            $data[] = '%' . strtolower($this->descriptionS) . '%';
        }
        if ($this->fieldS)
        {
            $this->fieldS = str_replace(' ','%', $this->fieldS);
            $this->setWhere('lower(field) LIKE lower(?)');
            $data[] = '%' . strtolower($this->fieldS) . '%';
        }
        if ($this->identifierS)
        {
            $this->identifierS = str_replace(' ','%', $this->identifierS);
            $this->setWhere('lower(identifier) LIKE lower(?)');
            $data[] = '%' . strtolower($this->identifierS) . '%';
        }
        if ($this->observationS)
        {
            $this->observationS = str_replace(' ','%', $this->observationS);
            $this->setWhere('lower(observation) LIKE lower(?)');
            $data[] = '%' . strtolower($this->observationS) . '%';
        }
        if ( $this->levelS )
        {
            $this->setWhere('level = ?');
            $data[] = $this->levelS;
        }
        if ( $this->isRestrictedS )
        {
            $this->setWhere('isRestricted = ?');
            $data[] = $this->isRestrictedS;
        }
        if ( $this->fieldTypeS )
        {
            $this->setWhere('fieldType = ?');
            $data[] = $this->fieldTypeS;
        }
        if ($this->helpsS)
        {
            $this->helpsS = str_replace(' ','%', $this->helpsS);
            $this->setWhere('lower(helps) LIKE lower(?)');
            $data[] = '%' . strtolower($this->helpsS) . '%';
        }
        $sql = $this->select($data);
        $rs  = $this->query($sql);
        return $rs;
    }



    /**
     * retorna detalhes necessarios para filtro de pesquisa
     *
     * @param integer $searchableFieldId
     * @return object
     */
    public function getDetaisForOrder($searchableFieldId)
    {
        parent::clear();
        parent::setColumns("field, fieldType");
        parent::setTables($this->table);
        parent::setWhere("searchableFieldId = ?");
        parent::select(array($searchableFieldId));
        $result = parent::query(null, true);
        return $result[0];
    }


    /**
     * retorna os campos que tem uniï¿½o na consulta
     */
    public function getUnionFields()
    {
        parent::clear();
        parent::setColumns("field");
        parent::setTables($this->table);
        parent::setWhere("field like '%+%'");
        parent::select();
        $result = parent::query(null, true);
        return $result;
    }


    /**
     * Return a list of searchable field,
     *
     * @param boolean $field_title if is to return the array in field => title form.
     * @return array
     */
    public function listSearchableField($field_title = false)
    {
        $busAuth            = $this->MIOLO->getBusiness($this->module, 'BusAuthenticate');
        $busSearchableAcess = $this->MIOLO->getBusiness($this->module, 'BusSearchableFieldAccess');
        $busBond            = $this->MIOLO->getBusiness($this->module, 'BusBond');

        $admin  = GOperator::isLogged();
        $personId    = $busAuth->getUserCode();

        $where = '';

        // SE ESTIVER LOGADO COMO USUARIO PEGA AS PERMISSOES
        if($personId && !$admin)
    	{

    	    if($userLink = $busBond->getAllPersonLink($personId))
            {
                foreach ($userLink as $links)
                {
                    $linkId[] = $links->linkId;
                }
                $linkId = ($linkId) ? implode(',', $linkId) : 'null';

                if($idsPermitidos = $busSearchableAcess->getSearchableFieldAccessByLinkId($linkId))
                {
                    foreach ($idsPermitidos as $content)
                    {
                        $where.= "{$content->searchableFieldId}, ";
                    }
                    $where = substr($where, 0, strlen($where)-2);
                    $where = "isRestricted = false OR searchableFieldId IN ($where)";
                }
    	    }
        }

        // SE NAO TIVER WHERE E NAO FOI ADMIN... PEGA SOMENTE OS NAO RESTRITOS
        if(!strlen($where) && !$admin)
        {
            $where = 'isRestricted = false';
        }

        if(strlen($where))
        {
            $this->setWhere($where);
        }

    	$this->setOrderBy('level');

    	if (!$field_title)
    	{
            return $this->autoList();
    	}

		$data = $this->autoList(true);
		if (is_array($data))
		{
			foreach ($data as $line => $info)
			{
				$temp[$info->field] = $info->description;
			}
		}

		return $temp;
    }


    /**
     * Esta funï¿½ï¿½o recebe um expressï¿½o de busca usada no BusGenericSearch, e retorna a mesma exp.
     * O detalhe ï¿½ que ela troca campos nominais por tags, por exemplo: troca "autor", por "100.a".
     * De acordo com o que estiver na base.
     *
     * @param string $exp a expressï¿½o original
     * @return string $exp a espressï¿½o tratada
     */
    public function parseExpression($exp)
    {
        $exp    = ' '.$exp; //adiciona um espaï¿½o extra para funcionar o replace com ' '.$info
        $fields = $this->listSearchableField();
        if ( is_array($fields) && $fields)
        {
            foreach ($fields as $line => $info)
            {
            	$identifier    = ' '.$info[3].':';
            	$field         = ' '.$info[2].':';
            	$exp           = str_replace($identifier, $field, $exp); //faz replace com espaï¿½o na frente para resolver problema com palavras tipo 'titulo' e 'subtï¿½tulo'
            }
        }
        $exp = trim($exp);
        return $exp;
    }

    public function listFieldType()
    {
        $listType = array(
            1 => _M('Numérico', $this->module),
            2 => _M('String', $this->module)
        );
        return $listType;
    }
    public function getNextSearchableFieldId()
    {
        $query = $this->query("SELECT currval('seq_searchablefieldid')");
        return $query[0][0];
    }

}
?>
