<?php

class frmTransaction extends AdminForm
{

    public function __construct()
    {
        $module = MIOLO::getCurrentModule();
        
        $function = MIOLO::_request( 'function' );
        switch ( $function )
        {
            case 'update' :
                $title = _M( 'Update', $module );
                break;
            default :
                $title = _M( 'Insert', $module );
                break;
        }
        
        $title = _M( 'Transactions', $module ) . ' - ' . $title;
        
        parent::__construct( $title );
    }

    public function createFields()
    {
        $MIOLO = MIOLO::getInstance();
        $module = MIOLO::getCurrentModule();
        
        parent::createFields();
        
        $fields[] = new MTextField( 'idTransaction', '', _M( 'Id', $module ) );
        
        $fields[] = new MTextField( 'transaction', '', _M( 'Transaction', $module ), 20 );
        
        $modules = $MIOLO->getBusiness( $module, 'module' );
        $fields[] = new MSelection( 'idModule', NULL, _M( 'Module', $module ), $modules->listAll()->chunkResult() );
        
        $fields[] = new MButton( 'save', _M( 'Save', $module ) );
        
        $validators[] = new MRequiredValidator( 'transaction', '', _M( 'Transaction', $module ) );
        
        $this->addFields( $fields );
        $this->setValidators( $validators );
        $this->setFieldAttr( 'idTransaction', 'visible', false );
    }

    public function save_click()
    {
        parent::save_click( 'transaction' );
    }

    public function edit_click()
    {
        $MIOLO = MIOLO::getInstance();
        $module = MIOLO::getCurrentModule();
        
        $this->toolbar->enableButtons( MToolBar::BUTTON_NEW );
        
        $item = MIOLO::_request( 'item' );
        
        $transaction = $MIOLO->getBusiness( $module, 'transaction' );
        $transaction->getById( $item );
        
        if ( $transaction->idTransaction )
        {
            $this->setFieldValue( 'idTransaction', $transaction->idTransaction );
            $this->setFieldValue( 'transaction', $transaction->transaction );
            $this->setFieldValue( 'idModule', $transaction->idModule );
            $this->setFieldAttr( 'idTransaction', 'visible', true );
            $this->setFieldAttr( 'idTransaction', 'readonly', true );
        }
    }

    public function delete_click()
    {
        $MIOLO = MIOLO::getInstance();
        $module = MIOLO::getCurrentModule();
        $action = MIOLO::getCurrentAction();
        
        $idTransaction = $this->getFormValue( 'idTransaction' ) ? $this->getFormValue( 'idTransaction' ) : MIOLO::_request( 'item' );
        
        parent::delete_click( 'transaction', $idTransaction );
    }
}

?>
