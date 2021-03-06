<?php

class MBasePanel extends MContainer
{
    public $box;

    public function __construct($name = '', $caption = '', $controls = NULL, $close = '', $icon = '')
    {
        parent::__construct($name, $controls, 'horizontal');
        $this->box = new MBox($caption, $close, $icon);
        $this->box->setBoxClass('m-panel-box');
    }


    public function setTitle($title)
    {
        $this->box->setCaption($title);
    }


    public function addControl($control, $width = '', $float = 'left', $class = null)
    {
        if ( is_array($control) )
        {
            foreach ($control as $c)
            {
                $this->addControl($c, $width, $float);
            }
        }
        else
        {
            if ($width == '100%')
            {
                $width = '';
            }

            $control->width = MUtil::NVL( $control->width, $width );

            if ($float == 'clear')
            {
                $control->clear = 'both';
            }
            else
            {
                $control->float = MUtil::NVL( $control->float, $float );
            }

            $control->setBoxClass(is_null($class) ? "m-panelcontrol-box" : $class);

            parent::addControl($control);
        }
    }


    public function insertControl($pos, $control, $width = '', $float = 'left')
    {
        if ( $width == '100%' )
        {
            $width = '';
        }

        $control->width = MUtil::NVL( $control->width, $width );

        if ( $float == 'clear' )
        {
            $control->clear = 'both';
        }
        else
        {
            $control->float = MUtil::NVL( $control->float, $float );
        }

        $control->setBoxClass('m-panelcontrol-box');
        parent::insertControl( $control, $pos );
    }


    public function generate()
    {
        $body = new MDiv( $this->name, $this->getControls(), 'm-panel-body' );
        $this->box->setControls( array($body) );
        return $this->box->generate();
    }

}


class MPanel extends MBasePanel {}

?>