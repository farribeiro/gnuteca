<?php
/**
 * Brief Class Description.
 * Complete Class Description.
 */
class Oracle8Query extends MQuery
{
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
     * @param $stmt (tipo) desc
     *
     * @returns (tipo) desc
     *
     */
    public function _querystmt($stmt)
    {
        $this->statement = $stmt;
        $this->fetched = true;
        $exec = oci_execute($this->statement,$this->conn->executemode);

        if (!$exec)
            throw new EDatabaseQueryException($this->_error());

        $this->rowCount = oci_fetch_all($this->statement, $this->result, $this->offset, $this->maxrows,
                                        OCI_NUM + OCI_FETCHSTATEMENT_BY_ROW + OCI_RETURN_LOBS);
        if ($this->rowCount === false)
            throw new EDatabaseQueryException($this->_error());

        $this->colCount = ocinumcols($this->statement);
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
        $stmt = oci_parse($this->conn->id, $this->sql);

        if (!$stmt)
            throw new EDatabaseQueryException();

        $this->_querystmt($stmt);
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
        $err = oci_error($this->statement);
        return ($err ? $err['message'] : false);
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
        ocifreestatement ($this->statement);
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
            $name = strtoupper(OCIColumnName($this->statement, $i + 1));
            $this->metadata['fieldname'][$i] = $name;
            $this->metadata['fieldtype'][$name] = $this->_getmetatype(OCIColumnType($this->statement, $i + 1));
            $this->metadata['fieldlength'][$name] = OCIColumnSize($this->statement, $i + 1);
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
