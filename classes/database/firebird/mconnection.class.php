<?php
/**
 * Brief Class Description.
 * Complete Class Description.
 */
class FirebirdConnection extends MConnection
{
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
     * @param $parameters= (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function _connect($dbhost, $loginDB, $loginUID, $loginPWD, $persistent = true, $parameters = null)
    {
        $buffers = (isset($parameters['buffers'])) ? ($parameters['buffers']) : (null);
        $characterset = (isset($parameters['characterset'])) ? ($parameters['characterset']) : (null);
        $dialect = (isset($parameters['dialect'])) ? ($parameters['dialect']) : (null);
        $role = (isset($parameters['role'])) ? ($parameters['role']) : (null);

        if (false && $persistent)
        {
            $this->id = ibase_pconnect($loginDB, $loginUID, $loginPWD, $characterset, $buffers, $dialect, $role);
        }
        else
        {
            $this->id = ibase_connect($loginDB, $loginUID, $loginPWD, $characterset, $buffers, $dialect, $role);
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
        ibase_close ($this->id);
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
        return ibase_errmsg();
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param &$sql (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function _parse(&$sql)
    {
        $sql = preg_replace("/:((.+) /", "\?", $sql);
        $statement = ibase_prepare($this->id, $sql);
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
    public function _execute($sql)
    {
        $prepared = ibase_prepare($this->id, $sql);

        if ($prepared)
        {
            $rs = ibase_execute($prepared);
            $success = false;

            if ($rs)
            {
                $success = true;
                $this->affectedrows = ibase_affected_rows($this->id);
                ibase_free_result ($rs);
            }
            else
            {
                $this->traceback[] = $this->_error($this->id);
            }
        }
        else
        {
            $this->traceback[] = $this->_error($this->id);
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
        return new FirebirdQuery();
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
    public function _chartotimestamp($timestamp)
    {
        return "'" . substr($timestamp, 7, 4) . '/' . substr($timestamp, 4, 2) . '/' . substr($timestamp, 1, 2) . ' ' . substr($timestamp, 11);
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
    public function _chartodate($date)
    {
        return $date;
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
    public function _timestamptochar($timestamp)
    {
        return $timestamp;
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
    public function _datetochar($date)
    {
        return $date;
    }
}
?>
