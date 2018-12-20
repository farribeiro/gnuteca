<?php

class frmGroupSearch extends AdminSearchForm
{

    public function __construct()
    {
        $module = MIOLO::getCurrentModule();
        
        $title = _M( 'Groups', $moudle ) . ' - ' . _M( 'Search', $module );
        
        parent::__construct( $title );
    }

    public function createFields()
    {
        $MIOLO = MIOLO::getInstance();
        $module = MIOLO::getCurrentModule();
        
        parent::createFields();
        
        $fields[] = new MTextField( 'group', '', _M( 'Group', $module ), 20 );
        
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
        
        $group = $MIOLO->getBusiness( $module, 'group' );
        
        $columns = array( 
                new MDataGridColumn( 'idgroup', _M( 'Id', $module ), 'right', true, '20%', true ), 
                new MDataGridColumn( 'm_group', _M( 'Group', $module ), 'left', true, '80%', true, null, true ), 
        );
        $href_datagrid = $MIOLO->getActionURL( $module, $action, '' );
        $query = $group->listByGroup( $filters );
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
        $filters = $this->getFormValue( 'group' );
        
        $data = $this->createGrid( $filters );
        
        $this->setResponse( $data, 'divGrid' );
    }
}

?>
