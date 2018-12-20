<?php

class frmUserSearch extends AdminSearchForm
{

    public function __construct()
    {
        $module = MIOLO::getCurrentModule();
        
        $title = _M( 'Users', $moudle ) . ' - ' . _M( 'Search', $module );
        
        parent::__construct( $title );
    }

    public function createFields()
    {
        $MIOLO = MIOLO::getInstance();
        $module = MIOLO::getCurrentModule();
        
        parent::createFields();
        
        $fields[] = new MTextField( 'username', '', _M( 'Login', $module ), 20 );
        $fields[] = new MTextField( 'fullname', '', _M( 'Name', 'admin' ), 30 );
        $fields[] = new MTextField( 'nickname', '', _M( 'Nick', 'admin' ), 20 );
        
        $fields[] = new MButton( 'search', _M( 'Search', $module ) );
        
        $grid = $this->createGrid();
        $fields[] = new MDiv( 'divGrid', $grid );
        
        $this->addFields( $fields );
    }

    public function createGrid($filters)
    {
        $MIOLO = MIOLO::getInstance();
        $module = MIOLO::getCurrentModule();
        $action = MIOLO::getCurrentAction();
        
        $user = $MIOLO->getBusiness( $module, 'user' );
        
        $columns = array( 
                new MDataGridColumn( 'iduser', _M( 'Id', $module ), 'right', true, '10%', true ), 
                new MDataGridColumn( 'login', _M( 'Username', $module ), 'left', true, '25%', true, null, true ), 
                new MDataGridColumn( 'name', _M( 'Name', $module ), 'left', true, '40%', true, null, true ), 
                new MDataGridColumn( 'nickname', _M( 'Nickname', $module ), 'left', true, '25%', true, null, true ) 
        );
        $href_datagrid = $MIOLO->getActionURL( $module, $action, '' );
        $query = $user->listByFilters( $filters );
        
      //  clog($query);
        $datagrid = new MDataGrid( $query, $columns, $href_datagrid, 15 );
        
        $href_edit = $MIOLO->getActionURL( $module, $action, '%0%', Array( 
                'event' => 'edit:click', 
                'function' => 'update' 
        ) );
        $datagrid->addActionUpdate( $href_edit );
        
        $href_dele = $MIOLO->getActionURL( $module, $action, '%0%', Array( 
                'event' => 'delete:click',
                'function' => 'delete'
        ) );
        $datagrid->addActionDelete( $href_dele );
        
        return $datagrid;
    
    }
    
    public function search_click()
    {
        $filters->login = $this->getFormValue( 'username' );
        $filters->fullname = $this->getFormValue( 'fullname' );
        $filters->nickname = $this->getFormValue( 'nickname' );
        
        $data = $this->createGrid( $filters );
        
        $this->setResponse( $data, 'divGrid' );
    }
}

?>
