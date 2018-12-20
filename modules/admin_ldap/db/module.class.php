<?php
class BusinessAdmin_ldapModule extends Business //implements IModule
{
    public $idModule;
    public $name;
    public $description;

    public function __construct($data = NULL)
    {
       parent::__construct('admin_ldap',$data);
    }
    
    public function getName()
    {
        return $this->name;
    }

    public function getId()
    {
        return $this->idModule;
    }
    
    public function save()
    {
    }
    
    public function delete()
    {
    }

    public function getById($id)
    {
    }

    public function listRange($range = NULL)
    {
    }

    public function listById($id)
    {
    }


    public function listAll($array)
    {
        global $MIOLO;
        $dir = dir($MIOLO->getModulePath('',''));
        $return = array();
        
        while($d = $dir->read())
            if( strpos($d, '.') !== 0 ) $return[$d] = $d;
        $dir->close();
        return $return;
    }
    
    public function listAllAccess($array)
    {
        $access= array( Admin           => 'Admin',
                        Register        => 'Register',
                        A_ADMIN         => 'A_ADMIN',
                        A_ACCESS        => 'A_ACCESS',
                        ACC_ACCESS      => 'ACC_ACCESS',
                        ACC_DELETE      => 'ACC_DELETE',
                        ACC_INSERT      => 'ACC_INSERT',
                        ACC_UPDATE      => 'ACC_UPDATE',
                        ACC_ADMIN       => 'ACC_ADMIN',
                        ACC_ACCOUNTING_LIMIT=>'ACC_ACCOUNTING_LIMIT',
                        ACD_ACCESS      => 'ACD_ACCESS',
                        ACD_DELETE      => 'ACD_DELETE',
                        ACD_INSERT      => 'ACD_INSERT',
                        ACD_UPDATE      => 'ACD_UPDATE',
                        ACD_ENROLL      => 'ACD_ENROLL',
                        ACD_ADMIN       => 'ACD_ADMIN',
                        BAS_ACCESS      => 'BAS_ACCESS',
                        BAS_DELETE      => 'BAS_DELETE',
                        BAS_INSERT      => 'BAS_INSERT',
                        BAS_UPDATE      => 'BAS_UPDATE',
                        BAS_ADMIN       => 'BAS_ADMIN',
                        FIN_ACCESS      => 'FIN_ACCESS',
                        FIN_DELETE      => 'FIN_DELETE',
                        FIN_INCOME_FORECAST_GENERATION=>'FIN_INCOME_FORECAST_GENERATION',
                        FIN_INSERT      => 'FIN_INSERT',
                        FIN_UPDATE      => 'FIN_UPDATE',
                        FIN_ADMIN       => 'FIN_ADMIN',
                        INS_ACCESS      => 'INS_ACCESS',
                        INS_DELETE      => 'INS_DELETE',
                        INS_INSERT      => 'INS_INSERT',
                        INS_UPDATE      => 'INS_UPDATE',
                        INS_ADMIN       => 'INS_ADMIN',
                        AST_ACCESS      => 'AST_ACCESS',
                        AST_DELETE      => 'AST_DELETE',
                        AST_INSERT      => 'AST_INSERT',
                        AST_UPDATE      => 'AST_UPDATE',
                        AST_ADMIN       => 'AST_ADMIN',
                        SPR_ACCESS      => 'SPR_ACCESS',
                        SPR_DELETE      => 'SPR_DELETE',
                        SPR_INSERT      => 'SPR_INSERT',
                        SPR_UPDATE      => 'SPR_UPDATE',
                        SPR_ADMIN       => 'SPR_ADMIN',
                        SPR_INSCRIPTION => 'SPR_INSCRIPTION',
                        CCP_ACCESS      => 'CCP_ACCESS',
                        CCP_DELETE      => 'CCP_DELETE',
                        CCP_INSERT      => 'CCP_INSERT',
                        CCP_UPDATE      => 'CCP_UPDATE',
                        CCP_ADMIN       => 'CCP_ADMIN',
                        HRS_ACCESS      => 'HRS_ACCESS',
                        HRS_DELETE      => 'HRS_DELETE',
                        HRS_INSERT      => 'HRS_INSERT',
                        HRS_UPDATE      => 'HRS_UPDATE',
                        HRS_ADMIN       => 'HRS_ADMIN',
                        RSH_ACCESS      => 'RSH_ACCESS',
                        RSH_DELETE      => 'RSH_DELETE',
                        RSH_INSERT      => 'RSH_INSERT',
                        RSH_UPDATE      => 'RSH_UPDATE',
                        RSH_ADMIN       => 'RSH_ADMIN',
                        WEB_ACCESS      => 'WEB_ACCESS',
                        view            => 'view',
                        access          => 'access',
                        acesso          => 'acesso',
                        admin           => 'admin',
                        forms           => 'forms',
                        'list'          => 'list',
                        'insert'        => 'insert',
                        'delete'        => 'delete',
                        'edit'          => 'edit',
                        );
        return $access;
    }
}
?>
