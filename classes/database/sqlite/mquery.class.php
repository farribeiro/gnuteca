<?php
/**
 * Brief Class Description.
 * Complete Class Description.
 */
class SQLiteQuery extends MQuery
{
    /**
     * Attribute Description.
     */
    public $id_result;

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function __construct()
    {
        parent::__construct();
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function _query()
    {
        $this->fetched = false;
        $this->sql = $this->maxrows ? $this->sql . " LIMIT $this->maxrows" : $this->sql;
        $this->sql = $this->offset ? $this->sql . " OFFSET $this->offset" : $this->sql;
        $this->id_result = sqlite_query($this->conn->id, $this->sql);
        $this->error = $this->_error();

        if (!$this->error)
        {
            $this->rowCount = sqlite_num_rows($this->id_result);

            for ($n = 0; $n < $this->rowCount; $this->result[$n++] = sqlite_fetch_array($this->id_result, SQLITE_NUM))
                ;

            $this->fetched = true;
            $this->colCount = sqlite_num_fields($this->id_result);
        }
        else
        {
            throw new EDatabaseQueryException($this->error);
        }

        return (!$this->error);
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
        return (($error = sqlite_last_error($this->conn->id)) ? sqlite_error_string($error) : false);
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
        if ($this->id_result)
            unset ($this->id_result);
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @returns (tipo) desc
     *
     */
    public function _setmetadata()
    {
        $numCols = $this->colCount;
        $this->metadata = array
            (
            );

        for ($i = 0; $i < $numCols; $i++)
        {
            $name = strtoupper(sqlite_field_name($this->id_result, $i));
            $name = ($p = strpos($name, '.')) ? substr($name, $p + 1) : $name;
            $this->metadata['fieldname'][$i] = $name;
            $this->metadata['fieldtype'][$name] = 'C';
            $this->metadata['fieldlength'][$name] = 0;
            $this->metadata['fieldpos'][$name] = $i;
        }
    }

    /**
     * Brief Description.
     * Complete Description.
     *
     * @param $type (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function _getmetatype($type)
    {
        $type = strtoupper($type);
        $rType = 'N';

        if ($type == "VARCHAR")
        {
            $rType = 'C';
        }
        elseif ($type == "CHAR")
        {
            $rType = 'C';
        }
        elseif ($type == "NUMBER")
        {
            $rType = 'N';
        }
        elseif ($type == "INTEGER")
        {
            $rType = 'N';
        }
        elseif ($type == "DATE")
        {
            $rType = 'T';
        }
        elseif ($type == "TIMESTAMP")
        {
            $rType = 'T';
        }

        return $rType;
    }
}
?>
