<?php

class MFormControl extends MControl
{
    public $label;
    public $value;
    public $hint;
    public $form;
    public $formName;
    public $showLabel; // se label deve ser exibido junto com o campo
    public $autoPostBack;
    public $validator;


    public function __construct( $name, $value = '', $label = '', $color = '', $hint = '' )
    {
        parent::__construct( $name );

//        $this->addStyleFile( 'm_controls.css' );
        $this->setValue($value);
        $this->label = $label;
        $this->hint  = $hint;

        if ( $color != '' )
        {
            $this->color = $color;
        }

        $this->showLabel    = true;
        $this->autoPostBack = false;
        $this->form         = NULL;
    }

    public function __toString()
    {
        return '';
    }

    public function setValue( $value )
    {
        $this->value = $value;
    }


    public function getValue()
    {
        return $this->value;
    }


    public function setLabel( $label )
    {
        $this->label = $label;
    }


    public function setAutoPostBack( $value )
    {
        $this->autoPostBack = $value;
    }

    public function setAutoSubmit( $isAuto = true )
    {
        $this->autoPostBack = $isAuto;
    }

    public function generateLabel()
    {
        $label = '';
        $this->showLabel = ( $this->formMode >= MControl::FORM_MODE_SHOW_ABOVE );

        if ( ( $this->showLabel ) && ( $this->label != '' ) )
        {
            $span  = new MSpan( '', $this->label, 'm-caption' );

            if( ! $this->validator && method_exists($this->form,'getFieldValidator') )
            {
                $this->validator = $this->form->getFieldValidator($this->name);
            }

            //if($this->name == 'zipCode')
            //    vaR_dump($this->validator->type,get_class($this));

            $r = $this->attrs->items['required'] || ($this->validator && $this->validator->type == 'required');

            if( $r && trim(MUtil::removeSpaceChars($this->label)) )
            {
                $span->setClass('m-caption-required');
            }

            $label = $this->painter->span( $span );

            if ( $this->formMode == MControl::FORM_MODE_SHOW_ABOVE )
            {
                $label .= $this->painter->BR;
            }
            elseif ( $this->formMode == MControl::FORM_MODE_SHOW_NBSP )
            {
                $label .= "&nbsp;&nbsp;";
            }
        }
        return $label;
    }

}
?>
