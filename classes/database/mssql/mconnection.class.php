<?php
/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MSSQLConnection extends MConnection
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
        if (false && $persistent)
        {
            $this->id = mssql_pconnect($dbhost,$loginUID,$loginPWD);
            @mssql_select_db($loginDB, $this->id);
        }
        else
        {
            $this->id = mssql_connect($dbhost,$loginUID,$loginPWD);
            @mssql_select_db($loginDB, $this->id);
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
        mssql_close($this->id);
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
        $msg = mssql_get_last_message();
        return $msg;
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
        $rs = mssql_query($sql,$this->id);
        if ($rs)
        { 
            $success = true;
            $this->affectedrows = mssql_rows_affected($this->id);
//            mssql_free_result($rs);
        }
        else
        {
            $success = false;
            $this->traceback[] = $this->_error();
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
        return new MSSQLQuery();
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
    public function _chartodate($date, $format='DD/MM/YYYY')
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
    public function _timestamptochar($timestamp,  $format='DD/MM/YYYY HH24:MI:SS')
    {

        return "convert(varchar," . $timestamp . ",131) ";
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

        return "convert(varchar," . $date . ",103) ";
    }
}
?>
