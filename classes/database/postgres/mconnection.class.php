<?php
/**
 * Brief Class Description.
 * Complete Class Description.
 */
class PostgresConnection extends MConnection
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
     *
     * @returns (tipo) desc
     *
     */
    public function _connect($dbhost, $loginDB, $loginUID, $loginPWD, $persistent = true)
    {
        $h = explode(':',$dbhost);
        $host       = $h[0];
        $port       = is_null($h[1]) ? '5432' : $h[1];

        $arg = "host=$host " . ($loginDB ? "dbname=$loginDB " : "") . "port=$port " . "user=$loginUID " . "password=$loginPWD";

        if (false && $persistent)
        {
            $this->id = pg_pconnect($arg);
        }
        else
        {
            $this->id = pg_connect($arg);
        }
        $encoding = ($enc = $this->_miolo->getConf('options.charset')) != '' ? $enc : 'ISO-8859-1';
        pg_query($this->id, "SET CLIENT_ENCODING TO '{$encoding}'");
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
        pg_close($this->id);
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
        return pg_result_error($resource ? $resource : $this->id);
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
        $rs = pg_query($this->id, $sql);
        $success = false;

        if ($rs)
        {
            $success = true;
            $this->affectedrows = pg_affected_rows($rs);
            pg_free_result($rs);
        }
        else
        {
            $this->traceback[] = pg_last_error($this->id);
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
        return new PostgresQuery();
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
    public function _chartotimestamp($timestamp,  $format='DD/MM/YYYY HH24:MI:SS')
    {
        return ":TO_TIMESTAMP('" . $timestamp . "','$format') ";
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
    public function _timestamptochar($timestamp,  $format='DD/MM/YYYY HH24:MI:SS')
    {
        return "TO_CHAR(" . $timestamp . ",'$format') ";
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
    public function _datetochar($date,  $format='DD/MM/YYYY')
    {
        return "TO_CHAR(" . $date . ",'$format') ";
    }
}
?>
