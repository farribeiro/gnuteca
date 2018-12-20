<?php

/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MSQL
{
    /**
     * Attribute Description.
     */
    public $db;

    /**
     * Attribute Description.
     */
    public $distinct;

    /**
     * Attribute Description.
     */
    public $columns;

    /**
     * Attribute Description.
     */
    public $tables;

    /**
     * Attribute Description.
     */
    public $where;

    /**
     * Attribute Description.
     */
    public $groupBy;

    /**
     * Attribute Description.
     */
    public $having;

    /**
     * Attribute Description.
     */
    public $orderBy;

    /**
     * Attribute Description.
     */
    public $forUpdate;

    /**
     * Attribute Description.
     */
    public $join;

    /**
     * Attribute Description.
     */
    public $parameters;

    /**
     * Attribute Description.
     */
    public $command;

    /**
     * Attribute Description.
     */
    public $range;

    /**
     * Attribute Description.
     */
    public $bind;

    /**
     * Attribute Description.
     */
    public $stmt;

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $columns' (tipo) desc
     * @param $tables='' (tipo) desc
     * @param $where='' (tipo) desc
     * @param $orderBy='' (tipo) desc
     * @param $groupBy='' (tipo) desc
     * @param $having='' (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function __construct($columns = '', $tables = '', $where = '', $orderBy = '', $groupBy = '', $having = '', $forUpdate = false)
    {
        $this->clear();
        $this->setColumns($columns);
        $this->setTables($tables);
        $this->setWhere($where);
        $this->setGroupBy($groupBy);
        $this->setHaving($having);
        $this->setOrderBy($orderBy);
        $this->setForUpdate($forUpdate);
        $this->join = null;
        $this->parameters = null;
        $this->range = null;
        $this->db = null;
        $this->bind = false;
        $this->stmt = NULL;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $string (tipo) desc
     * @param &$ (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    private function getTokens1($string, &$array)
    {
        $tok = strtok($string, ",");

        while ($tok)
        {
            $tok = trim($tok);
            $array[$tok] = $tok;
            $tok = strtok(",");
        }
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $string (tipo) desc
     * @param &$ (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    private function getTokens($string, &$array)
    {
        if ($string == '')
            return;

        $source = $string . ',';
        $tok = '';
        $l = strlen($source);
        $can = 0;

        for ($i = 0; $i < $l; $i++)
        {
            $c = $source{$i};

            if (!$can)
            {
                if ($c == ',')
                {
                    $tok = trim($tok);
                    $array[$tok] = $tok;
                    $tok = '';
                }
                else
                {
                    $tok .= $c;
                }
            }
            else
            {
                $tok .= $c;
            }

            if ($c == '(')
                $can++;

            if ($c == ')')
                $can--;
        }
    //       $array[$tok] = $tok;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    private function getJoin()
    {
        global $MIOLO;
        $MIOLO->uses('database/' . $this->db->system . '/msqljoin.class.php');
        $className = "{$this->db->system}SqlJoin";
        $join = new $className();
        $join->_sqlJoin($this);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $db (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setDb($db)
    {
        $this->db = $db;
    }

    /**
     * Set the columns
     * Use this method to set which columns should be .
     *
     * @param $string (string) Name of the columns
     * @param $distinct (boolean) If you want a distinct select, inform TRUE
     */
    public function setColumns($string, $distinct = false)
    {
        $this->getTokens($string, $this->columns);
        $this->distinct = $distinct;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $string (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setTables($string)
    {
        $this->getTokens($string, $this->tables);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $string (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setGroupBy($string)
    {
        $this->getTokens($string, $this->groupBy);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $string (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setOrderBy($string)
    {
        $this->getTokens($string, $this->orderBy);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $string (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setWhere($string)
    {
        $this->where .= (($this->where != '') && ($string != '') ? " and " : "") . $string;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $string (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setWhereAnd($string)
    {
        $this->where .= (($this->where != '') && ($string != '') ? " and " : "") . $string;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $string (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setWhereOr($string)
    {
        $this->where .= (($this->where != '') && ($string != '') ? " or " : "") . $string;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $string (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setHaving($string)
    {
        $this->having .= (($this->having != '') && ($string != '') ? " and " : "") . $string;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $string (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setHavingAnd($string)
    {
        $this->having .= (($this->having != '') && ($string != '') ? " and " : "") . $string;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $string (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setHavingOr($string)
    {
        $this->having .= (($this->having != '') && ($string != '') ? " or " : "") . $string;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $table1 (tipo) desc
     * @param $table2 (tipo) desc
     * @param $cond (tipo) desc
     * @param $typeINNER' (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setJoin($table1, $table2, $cond, $type = 'INNER')
    {
        $this->join[] = array
            (
            $table1,
            $table2,
            $cond,
            $type
            );
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $table1 (tipo) desc
     * @param $table2 (tipo) desc
     * @param $cond (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setLeftJoin($table1, $table2, $cond)
    {
        $this->setJoin($table1, $table2, $cond, 'LEFT');
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $table1 (tipo) desc
     * @param $table2 (tipo) desc
     * @param $cond (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setRightJoin($table1, $table2, $cond)
    {
        $this->setJoin($table1, $table2, $cond, 'RIGHT');
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $string (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function setForUpdate($forUpdate = false)
    {
        $this->forUpdate = $forUpdate;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $parameters (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function bind($parameters = null)
    {
        $this->bind = true;
        if (!is_array($parameters))
        {
            $parameters = array($parameters);
        }
        foreach($parameters as $i=>$p)
        {
            $parameters[$i] = ':' . $parameters[$i];
        }
        $this->setParameters($parameters);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $parameters (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function prepare($parameters = null)
    {
        global $MIOLO;

//        if ($this->bind)
//            return;

        if ($parameters === NULL)
            return;

        if (!is_array($parameters))
        {
            $parameters = array($parameters);
        }

        $i = 0;
        while (($pos=strpos($this->command,'?',$pos+1)) !== false) $pos_array[$i++] = $pos;

        $MIOLO->assert($i == count($parameters), "SQL PREPARE: Parâmetros inconsistentes! SQL: {$this->command}");

        if ($i > 0)
        {
            $sqlText = '';
            $p = 0;
            foreach ($pos_array as $i=>$pos)
            {
                $param = $parameters[$i];
                $param = ($param{0} == ':') ? substr($param,1) : (($param === '') || (is_null($param)) ? 'null' : "'".addslashes($param)."'");
                $sqlText .= substr( $this->command, $p, $pos-$p) . $param;
                $p = $pos + 1;
            }
            $sqlText .= substr( $this->command, $p);
            $this->command = $sqlText;
       }

/*
        while (true)
        {
            $pos = strpos($sqlText, '?');

            if ($pos == false)
            {
                $prepared .= $sqlText;
                break;
            }
            else
            {
                if ($pos > 0)
                {
                    $prepared .= substr($sqlText, 0, $pos);
                }

                if (substr($parameters[$i], 0, 1) == ':')
                {
                    $prepared .= substr($parameters[$i++], 1);
                }
                else
                {
                    $prepared .= "'" . addslashes($parameters[$i++]) . "'";
                }

                $sqlText = substr($sqlText, $pos + 1);
            }
        }
        $this->command = $prepared;
*/
        return $this->command;
    }

    /**
     * Returns insert command.
     * This method returns the sql insert command.
     *
     * @param $parameters (mixed) Array of values
     *
     * @returns (string) Sql insert command
     *
     */
    public function insert($parameters = null)
    {
        $sqlText = 'INSERT INTO ' . implode($this->tables, ',') . ' ( ' . implode($this->columns, ',') . ' ) VALUES ( ';

        for ($i = 0; $i < count($this->columns); $i++)
            $par[] = '?';

        $sqlText .= implode($par, ',') . ' )';
        $this->command = $sqlText;

        if (isset($parameters))
            $this->setParameters($parameters);

        $this->prepare($this->parameters);
        return $this->command;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $sql (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function insertFrom($sql)
    {
        $sqlText = 'INSERT INTO ' . implode($this->tables, ',') . ' ( ' . implode($this->columns, ',') . ' ) ';
        $sqlText .= $sql;
        $this->command = $sqlText;
        return $this->command;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $parameters (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function delete($parameters = null)
    {
        global $MIOLO;
        $sqlText = 'DELETE FROM ' . implode($this->tables, ',');
        $MIOLO->assert($this->where != '', "SQL DELETE: Condição não informada!");
        $sqlText .= strlen($this->where) ? ' WHERE ' . $this->where : "";
        $this->command = $sqlText;

        if (isset($parameters))
            $this->setParameters($parameters);

        $this->prepare($this->parameters);
        return $this->command;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $parameters (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function update($parameters = null)
    {
        global $MIOLO;
        $sqlText = 'UPDATE ' . implode($this->tables, ',') . ' SET ';

        foreach ($this->columns as $c)
            $par[] = $c . '= ?';

        $sqlText .= implode($par, ',');
        $MIOLO->assert($this->where != '', "SQL UPDATE: Condição não informada!");
        $sqlText .= ' WHERE ' . $this->where;
        $this->command = $sqlText;

        if (isset($parameters))
            $this->setParameters($parameters);

        $this->prepare($this->parameters);
        return $this->command;
    }

    /**
     * Returns SQL select command.
     * This method returns the SQL select command.
     *
     * @param $parameters (array) desc
     * @returns (string) SQL select command
     */
    public function select($parameters = null)
    {
        if ($this->join != NULL)
            $this->getJoin();

        $sqlText = 'SELECT ' . ($this->distinct ? 'DISTINCT ' : '') . implode($this->columns, ',');

        if ($this->tables != '')
        {
            $sqlText .= ' FROM   ' . implode($this->tables, ',');
        }

        if ($this->where != '')
        {
            $sqlText .= ' WHERE ' . $this->where;
        }

        if ($this->groupBy != '')
        {
            $sqlText .= ' GROUP BY ' . implode($this->groupBy, ',');
        }

        if ($this->having != '')
        {
            $sqlText .= ' HAVING ' . $this->having;
        }

        if ($this->orderBy != '')
        {
            $sqlText .= ' ORDER BY ' . implode($this->orderBy, ',');
        }

        if ($this->forUpdate)
        {
            $sqlText .= ' FOR UPDATE';
        }

        $this->command = $sqlText;

        if (isset($parameters))
            $this->setParameters($parameters);

        $this->prepare($this->parameters);
        return $this->command;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function clear()
    {
        $this->columns = '';
        $this->tables = '';
        $this->where = '';
        $this->groupBy = '';
        $this->having = '';
        $this->orderBy = '';
        $this->parameters = null;
        $this->command = '';
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function setParameters()
    {
        $numargs = func_num_args();

        if ($numargs == 1)
        {
            if (!is_array($parameters = func_get_arg(0)))
            {
                if ($parameters === null)
                    return;

                $parameters = array($parameters);
            }
        }
        else
        {
            $parameters = func_get_args();
        }

        $this->parameters = $parameters;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $value (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function addParameter($value)
    {
        $this->parameters[] = $value;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function setRange()
    {
        $numargs = func_num_args();

        if ($numargs == 1)
        {
            $this->range = func_get_arg(0);
        }
        elseif ($numargs == 2)
        {
            $page = func_get_arg(0);
            $rows = func_get_arg(1);
            $this->range = new MQueryRange($page, $rows);
        }
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function setOffset($offset, $rows)
    {
        if (!$this->range)
        {
            $this->range = new MQueryRange(0,0);
        }
        $this->range->offset = $offset;
        $this->range->rows = $rows;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $target (tipo) desc
     * @param $source (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function findStr($target, $source)
    {
        $l = strlen($target);
        $lsource = strlen($source);
        $pos = 0;

        while (($pos < $lsource) && (!$fim))
        {
            if ($source[$pos] == "(")
            {
                $p = $this->findStr(")", substr($source, $pos + 1));

                if ($p > 0)
                    $pos += $p + 3;
            }

            $fim = ($target == substr($source, $pos, $l));

            if (!$fim)
                $pos++;
        }

        return ($fim ? $pos : -1);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param &$cmd (tipo) desc
     * @param $clause (tipo) desc
     * @param $delimiters (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function parseSqlCommand(&$cmd, $clause, $delimiters)
    {
        if (substr($cmd, 0, strlen($clause)) != $clause)
            return false;

        $cmd = substr($cmd, strlen($clause));
        $n = count($delimiters);
        $i = 0;
        $pos = -1;

        while (($pos < 0) && ($i < $n))
            $pos = $this->findStr($delimiters[$i++], $cmd);

        if ($pos > 0)
        {
            $r = substr($cmd, 0, $pos);
            $cmd = substr($cmd, $pos);
        }

        return $r;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $sqltext (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function createFrom($sqltext)
    {
        $this->command = $sqltext;
        $sqltext = trim($sqltext) . " #";
        $sqltext = preg_replace("/(?i)select /", "select ", $sqltext);
        $sqltext = preg_replace("/(?i) from /", " from ", $sqltext);
        $sqltext = preg_replace("/(?i) where /", " where ", $sqltext);
        $sqltext = preg_replace("/(?i) order by /", " order by ", $sqltext);
        $sqltext = preg_replace("/(?i) group by /", " group by ", $sqltext);
        $sqltext = preg_replace("/(?i) having /", " having ", $sqltext);
        $this->setColumns($this->parseSqlCommand($sqltext, "select", array("from")));

        if ($this->findStr('JOIN', $sqltext) < 0)
        {
            $this->setTables($this->parseSqlCommand($sqltext, "from", array("where", "group by", "order by", "#")));
        }
        else
        {
            $this->join = $this->parseSqlCommand($sqltext, "from", array("where", "group by", "order by", "#"));
        }

        $this->setWhere($this->parseSqlCommand($sqltext, "where", array("group by", "order by", "#")));
        $this->setGroupBy($this->parseSqlCommand($sqltext, "group by", array("having", "order by", "#")));
        $this->setHaving($this->parseSqlCommand($sqltext, "having", array("order by", "#")));
        $this->setOrderBy($this->parseSqlCommand($sqltext, "order by", array("#")));
    }
}
?>