<?php
/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MysqlConnection extends MConnection
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
        if ($persistent)
        {
            $this->id = @mysql_pconnect($dbhost, $loginUID, $loginPWD);
            mysql_select_db($loginDB, $this->id);
        }
        else
        {
            $this->id = @mysql_connect($dbhost, $loginUID, $loginPWD);
            mysql_select_db($loginDB, $this->id);
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
        mysql_close ($this->id);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function _begintransaction()
    {
        $this->_execute("begin transaction");
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function _commit()
    {
        $this->_execute("commit");
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function _rollback()
    {
        $this->_execute("rollback");
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function _error()
    {
        return mysql_error($this->id);
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
        $rs = mysql_query($sql);
        $success = false;

        if ($rs)
        {
            $success = true;
            @mysql_free_result ($rs);
        }
        else
        {
            $this->traceback[] = $this->getError();
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
        return new MysqlQuery();
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
        return " TO_DATE(" . $timestamp . ",'DD/MM/YYYY HH24:MI:SS') ";
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
        return " TO_DATE(" . $date . ",'DD/MM/YYYY') ";
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
        return " TO_CHAR(" . $timestamp . ",'DD/MM/YYYY HH24:MI:SS') ";
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
        return " TO_CHAR(" . $date . ",'DD/MM/YYYY') ";
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param &$sql (tipo) desc
     * @param $table1 (tipo) desc
     * @param $table2 (tipo) desc
     * @param $cond (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function _sqljoin(&$sql, $table1, $table2, $cond)
    {
        if ($sql->join)
        {
            $sql->join = "($sql->join INNER JOIN $table2 ON ($cond))";
        }
        else
        {
            $sql->join = "($table1 INNER JOIN $table2 ON ($cond))";
        }
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param &$sql (tipo) desc
     * @param $table1 (tipo) desc
     * @param $table2 (tipo) desc
     * @param $cond (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function _sqlleftjoin(&$sql, $table1, $table2, $cond)
    {
        if ($sql->join)
        {
            $sql->join = "($sql->join LEFT JOIN $table2 ON ($cond))";
        }
        else
        {
            $sql->join = "($table1 LEFT JOIN $table2 ON ($cond))";
        }
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param &$sql (tipo) desc
     * @param $table1 (tipo) desc
     * @param $table2 (tipo) desc
     * @param $cond (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function _sqlrightjoin(&$sql, $table1, $table2, $cond)
    {
        if ($sql->join)
        {
            $sql->join = "($sql->join RIGHT JOIN $table2 ON ($cond))";
        }
        else
        {
            $sql->join = "($table1 RIGHT JOIN $table2 ON ($cond))";
        }
    }
}
?>
