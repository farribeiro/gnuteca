<?php
/**
 * Brief Class Description.
 * Complete Class Description.
 */
class Oracle8Connection extends MConnection
{
    /**
     * Attribute Description.
     */
    public $executemode = OCI_COMMIT_ON_SUCCESS;

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $conf (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function __construct($conf)
    {
        parent::__construct($conf);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $dbhost (tipo) desc
     * @param $loginDB (tipo) desc
     * @param $loginUID (tipo) desc
     * @param $loginPWD (tipo) desc
     * @param $persistent (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function _connect($dbhost, $loginDB, $loginUID, $loginPWD, $persistent = true)
    {
        if ($persistent)
        {
            $this->id = OCIPLogon($loginUID, $loginPWD, $loginDB);
        }
        else
        {
            $this->id = OCILogon($loginUID, $loginPWD, $loginDB);
        }
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function _close()
    {
        OCILogOff ($this->id);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $resource (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function _error($resource = null)
    {
        $err = oci_error($resource ? $resource : $this->id);
        return ($err ? $err['message'] : false);
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
    public function _parse($sql)
    {
        $sql = $this->_escape($sql);
        $statement = oci_parse($this->id, $sql);
        return $statement;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $stmt (tipo) desc
     * @param $ph (tipo) desc
     * @param $pv (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function _bind($stmt, $ph, $pv)
    {
		if (is_array($pv))
		{
            ocibindbyname($stmt, $ph, $pv[0],$pv[1],$pv[2]);
		}
		else
		{
            ocibindbyname($stmt, $ph, $pv);
		}
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

    public function _escape($sql)
    {
        $sql = str_replace("\'","''",$sql);
        $sql = str_replace('\"','"',$sql);
        return $sql;
    }

    public function _execute($sql)
    {
        if (is_object($sql))
        {
            if ($success = oci_execute($sql->stmt, $this->executemode))
            {
                $this->affectedrows = oci_num_rows($statement);
                if (!$sql->bind)
                {
                    oci_free_statement ($statement);
                }
            }
        }
        else
        {
            $sql = $this->_escape($sql);
            $statement = oci_parse($this->id, $sql);
            if ($success = oci_execute($statement, $this->executemode))
            {
                $this->affectedrows = oci_num_rows($statement);
                oci_free_statement ($statement);
            }
        }
        if (!$success)
        {
            $this->traceback[] = $this->_error($statement);
        }
        return $success;
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function _createquery()
    {
        return new Oracle8Query();
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $timestamp (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function _chartotimestamp($timestamp, $format='DD/MM/YYYY HH24:MI:SS')
    {
        return ":TO_DATE('" . $timestamp . "','$format') ";
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $date (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function _chartodate($date, $format='DD/MM/YYYY')
    {
        return ":TO_DATE('" . $date . "','$format') ";
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $timestamp (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function _timestamptochar($timestamp, $format='DD/MM/YYYY HH24:MI:SS')
    {
        return "TO_CHAR($timestamp,'$format') ";
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $date (tipo) desc
     *
     * @returns (tipo) desc
     *
     */

    public function _datetochar($date, $format='DD/MM/YYYY')
    {
        return "TO_CHAR($date,'$format') ";
    }
}
?>
