<?php

class MUnOrderedList extends MListControl
{
    public $content;


    public function __construct( $name = '', $options = array() )
    {
        parent::__construct( $name, '', $options );

        $this->formMode = MControl::FORM_MODE_WHOLE_ROW;
    }


    public function addOption( $value, $li = true )
    {
        $o = new MOption( '', $value );
        $o->type = $li ? 'circle' : 'circle';
        $this->options[] = $o;
    }


    public function addOptions( $array )
    {
        if ( ! is_array( $array ) )
        {
            $array = array( $array );
        }

        foreach ( $array as $value )
        {
            $this->addOption( $value );
        }
    }


    public function generateInner()
    {
        if ( $this->readonly )
        {
            return;
        }

        $this->content = '';

        foreach ( $this->options as $o )
        {
            $o->value = $this->painter->generateToString( $o->value );
            $this->content .= $this->painter->unOrderedListItem( $o );
        }

        $this->inner = $this->getRender( 'unorderedlist' );
    }
}

?>