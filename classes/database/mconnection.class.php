<?php
class MConnection
{
    public $db; // database object
    public $id; // the connection identifier
    public $traceback = array(); // a list of connection errors
    public $affectedrows;
    public $_miolo;     // MIOLO object

    public function __construct($db)
    {
        $this->db = $db;
        $this->_miolo = $this->db->_miolo;
        $this->_miolo->uses('database/' . $db->system . '/mquery.class.php');
    }

    // Virtual methods - to be implemented by the specific drivers

    public function _connect($dbhost, $loginDB, $loginUID, $loginPWD, $persistent = true, $port ='')
    {
    }

    public function _close()
    {
    }

    public function _error()
    {
    }

    public function _escape($sql)
    {
        return $sql;
    }

    public function _execute($sql)
    {
    }

    public function _createquery()
    {
    }

    public function _createproc()
    {
    }

    public function _chartotimestamp($timestamp)
    {
    }

    public function _chartodate($date)
    {
    }

    public function _timestamptochar($timestamp)
    {
    }

    public function _datetochar($date)
    {
    }

    // opens a connection to the specified data source
    public function open($dbhost, $loginDB, $loginUID, $loginPWD, $persistent = true, $parameters = NULL, $port = NULL)
    {
        if ($this->id)
        {
            $this->close();
        }
        $this->_connect($dbhost, $loginDB, $loginUID, $loginPWD, $persistent, $parameters, $port);
        if (!$this->id)
        {
            $this->traceback[] = _M("Unable to estabilish database connection to host:") ." $dbhost, DB: $loginDB, Type: {$this->db->system}";
        }
        return $this->id;
    }

    public function close()
    {
        if ($this->id)
        {
            $this->_close($this->id);
            $this->id = 0;
        }
    }

    public function getError()
    {
        if (!$this->id)
        {
            $err = _M("No valid Database connection estabilished.");
        }
        elseif ($this->traceback)
        {
            $err .= "<br>" . implode("<br>", $this->traceback);
        }
        return $err;
    }

    public function getErrors()
    {
        return $this->traceback;
    }

    public function getErrorCount()
    {
        return count($this->traceback);
    }

    public function checkError()
    {
        if (empty($this->traceback))
        {
            return;
        }
        $n = count($this->traceback);
        if ($n > 0)
        {
            $msg = "";
            for ($i = 0; $i < $n; $i++)
            {
                $msg .= $this->traceback[$i] . "<br>";
            }
        }
        if ($msg != '')
        {
            throw new EDatabaseException($this->db->conf, $msg);
        }
    }

    public function execute($sql)
    {
        if ($sql == "") return;

        $this->_miolo->logSQL($sql, false, $this->db->conf);

        if (!($success = $this->_execute($sql)))
        {
            throw new EDatabaseExecException($this->getError());
        }

        return $success;
    }

    public function parse($sql)
    {
        $this->_miolo->logSQL(_M('Parse:') . $sql->command, false, $this->db->conf);
        $sql->stmt = $this->_parse($sql->command);
    }

    public function bind($sql, $parameters)
    {
        if ($parameters)
        {
            foreach ($parameters as $ph => $pv)
            {
                $this->_bind($sql->stmt, $ph, $pv);
            }
        }
    }

    public function getQuery($sql, $maxrows = null, $offset = null)
    {
        $this->_miolo->assert($this->id, $this->getErrors());
        try
        {
            $query = $this->_createquery();
            $query->setConnection($this);
            $query->setSQL($sql);
            if ($sql->bind)
            {
                if (!$sql->stmt)
                {
                    $this->parse($sql);
                }

                $this->bind($sql);
            }
            $query->open($maxrows, $offset, $sql->stmt);
        }
        catch( Exception $e )
        {
            throw $e;
        }

        return $query;
    }

    public function getQueryCommand($sqlCommand, $maxrows = null, $offset = null)
    {
        $this->_miolo->assert($this->id, $this->getErrors());
        $query = $this->_createquery();
        $query->setConnection($this);
        $query->setSQLCommand($sqlCommand);
        $query->open($maxrows, $offset);
        return $query;
    }

    public function execProc($sql, $aParams = null)
    {
        $this->_miolo->assert($this->id, $this->getErrors());
        $q = $this->_createproc();
        $q->conn = &$this;
        if ($sql != "")
        {
            $q->execProc($sql, $aParams);
        }
        return ($q->result ? $q->result : (!$q->error));
    }
}
?>