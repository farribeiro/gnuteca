<?php
/**
 * Brief Class Description.
 * Complete Class Description.
 */
class SQLiteConnection extends MConnection
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
            $this->id = sqlite_open($loginDB);
        }
        else
        {
            $this->id = sqlite_open($loginDB);
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
        sqlite_close ($this->id);
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
        return (($error = sqlite_last_error($this->id)) ? sqlite_error_string($error) : false);
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
        $success = @sqlite_exec($this->id, $sql);

        if ($success)
        {
            $this->affectedrows = sqlite_changes($this->id);
            unset ($rs);
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
        return new SQLiteQuery();
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
