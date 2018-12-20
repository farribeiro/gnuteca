<?php

class MPermsGnuteca extends MPermsMiolo
{
    public function __construct()
    {
        parent::__construct();

        $this->perms = array( A_ACCESS  => "ACESSAR",
                              A_INSERT  => "INCLUIR",
                              A_UPDATE  => "ALTERAR",
                              A_DELETE  => "REMOVER" );
    }
}
?>
