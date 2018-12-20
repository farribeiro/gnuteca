<?php
/**
 * Brief Class Description.
 * Complete Class Description.
 */
class PostgresQuery extends MQuery
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
        $this->id_result = pg_query($this->conn->id, $this->sql);
        $this->error = $this->_error();

        if (!$this->error)
        {
            if ($this->rowCount = pg_num_rows($this->id_result))
            {
                for ($n = 0; $n < $this->rowCount; $this->result[$n] = pg_fetch_array($this->id_result, $n, PGSQL_NUM),$n++);
                $this->fetched = true;
            }

            $this->colCount = pg_num_fields($this->id_result);
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
        $error = pg_result_error($this->id_result) . pg_last_error();
        return $error;
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
            pg_free_result($this->id_result);
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
            $name = strtoupper(@pg_field_name($this->id_result, $i));
            $this->metadata['fieldname'][$i] = $name;
            $this->metadata['fieldtype'][$name] = $this->_getmetatype(@pg_field_type($this->id_result, $i));
            $this->metadata['fieldlength'][$name] = @pg_field_size($this->id_result, $i);
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
        elseif ($type == "DATE")
        {
            $rType = 'T';
        }

        return $rType;
    }
}
?>
