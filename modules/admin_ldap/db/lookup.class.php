<?
class BusinessAdminLookup
{

    public function autocompleteUser(&$context)
    {
        $sql = 'SELECT u.iduser, u.login, u.nickname, u.name FROM miolo_user u '.
               '    WHERE u.login = ?';
        $context->setContext('admin', $sql);
    }


	function LookupUser(&$lookup)
    {   
        $filterLogin = $lookup->getFilterValue('filterLogin');
        if (!$filterLogin) 
        {
            $filterLogin = $lookup->getFilterValue();
        }
        $filterName = $lookup->getFilterValue('filterName');
        if (!$filterNome)
        {
           if (!$filterLogin)
           {
               $filterNome = 'NÃO INFORMADO';
           }
        }
        $clause = $lookup->getFilterValue('clause');
        $lookup->addFilterField( new TextField('filterLogin', $filterLogin,'Login', 20));
        $lookup->addFilterField( new Selection('clause', $clause,'',array('AND' => '- e -','OR'  => '- ou -' )));
        $lookup->addFilterField( new TextField('filterName', $filterName,'Name', 40));
        $columns = array(
           new DataGridColumn('login','Login','left',true, '20%',true),
           new DataGridColumn('name','Name','left',true, '50%',true),
           new DataGridColumn('nickname','Nick','left',true, '30%',true)
        );
        $sql = new sql("u.iduser, u.login, u.nickname, u.name",'miolo_user u','','u.login');
        if ( $filterLogin || $filterName)
        {
            $sql->where .= "(";
            if ( $filterLogin )
            {
               $sql->where .= "( upper(u.login) like
               upper('{$filterLogin}%') )";
            }
            if ( $filterName )
            {
				if ($filterLogin)
				{
					$sql->where .= $clause;
				}
               $sql->where .= " ( upper(u.name)
               like upper('{$filterName}%') )";
            }
            $sql->where .= " )";
        }
        $lookup->setGrid('admin',$sql,$columns, 'Lookup Users',10,0);
    }

	function LookupTransaction(&$lookup)
    {
        $filter = $lookup->getFilterValue('filter');
        if (!$filter) 
        {
            $filter = $lookup->getFilterValue();
        } 
        $lookup->addFilterField( new MTextField('filter', $filter,'Transação', 20));
        $columns = array(
           new DataGridColumn('idtransaction','Id','right', true,'5%',true),
           new DataGridColumn('m_transaction','Transaction','left', true,'95%',true),
        );
        $sql = new sql('idtransaction, m_transaction','miolo_transaction','','m_transaction');
        if ( $filter )
        {
            $sql->where .= " ( upper(m_transaction) like upper('{$filter}%') )";
        }
        $lookup->setGrid('admin',$sql,$columns, 'Lookup Transactions',15,0);
    }

	function LookupTransactionGroup(&$lookup)
    {   
        global $MIOLO;
 
        $fTransaction = MUtil::NVL($lookup->getFilterValue('filter0'), $lookup->getFilterValue());
        $fGroup       = MUtil::NVL($lookup->getFilterValue('filter1'), '');

        $objTransaction = $MIOLO->getBusiness('admin','transaction');
        $objQuery = $objTransaction->listAll();

        $lookup->addFilterField( new MSelection('filter0', $fTransaction,'Transaction', $objQuery->result));
        $lookup->addFilterField( new MTextField('filter1', $fGroup,'Group', 20));
        $columns = array(
           new MDataGridColumn('idtransaction','Id','right', true, '5%',true),
           new MDataGridColumn('m_transaction','Transaction','left', true, '40%',true),
           new MDataGridColumn('idgroup','IdGroup','left', true, '5%',true),
           new MDataGridColumn('m_group','Group','left', true, '40%',true),
           new MDataGridColumn('rights','Rights','left', true, '10%',true)
        );
        $sql = new sql("t.idtransaction, t.m_transaction, g.idgroup, g.m_group, a.rights","miolo_transaction t, miolo_access a, miolo_group g", "(t.idtransaction = a.idtransaction) and (a.idgroup = g.idgroup)",'t.m_transaction, g.m_group');
        if ( $fGroup )
        {
            $sql->where .= " and ( upper(g.m_group) like upper('{$fGroup}%') )";
        }
        $sql->where .= " and ( t.idtransaction = '{$fTransaction}' )";
        $lookup->setGrid('admin',$sql,$columns,'Lookup Transaction/Groups',15,0);
    }

    public function autoCompleteGroup(&$context)
    {
        $sql = 'SELECT idgroup, m_group FROM miolo_group WHERE idgroup = ? ';
        $context->setContext('admin', $sql);
    }


	function LookupGroup(&$lookup)
    {
        $filter = $lookup->getFilterValue('filter');
        if (!$filter) 
           $filter = $lookup->getFilterValue();
        $lookup->addFilterField( new TextField('filter',$filter,'Grupo', 20));
        $columns = array(
           new DataGridColumn('idgrupo','Id','right',
            true, '10%',true),
           new DataGridColumn('grupo','Grupo','left', true, '90%',true)
        );
        $sql = new sql('idgrupo, grupo', 'cm_grupoacesso'
        ,'','idgrupo');
        if ( $filter )
        {
            $sql->where .= " ( upper(grupo) like
            upper('{$filter}%') )";
        }
        $lookup->setGrid('common',$sql,$columns,
        'Pesquisa Grupos',15,0);
    }
}
?>
