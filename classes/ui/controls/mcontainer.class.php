<?
class MContainer extends MFormControl
{
    public $disposition;
    public $separator;
    public $spaceHeight; // espaçamento em pixels entre os campos no disposition=vertical
    public $spaceWidth='&nbsp;&nbsp;'; //espaçamento em pixels entre os campos no disposition=horizontal
    public $formMode;
    
    /* se label deve ser exibido junto com os campos
     *  Esse atributo foi modificado para private para forçar a 
     *  utilizaçào do método setShowLabel. Esta modificação foi
     *  necessária para os casos em que o programador necessite
     *  que os labels dos conteúdos fossem exibidos
     */
    public $showLabel;

    /*  esta propriedade controla a exibição ou não do label dos
     *   conteúdos de um container. É necessário utilizar o método
     *   setShowChildLabel para modificar esta propriedade.
     */
    public $showChildLabel = true; //se o label dos conteiner conteúdos deste serão exibidos

    public function __construct($name = NULL, $controls = NULL, $disposition = 'none', $formMode = MControl::FORM_MODE_SHOW_ABOVE)
    {
        parent::__construct($name);
        $this->formMode = $formMode;
        $controls = (($controls != '') && is_array($controls)) ? $controls : array();
        $this->showLabel = true;
        $this->spaceHeight = '3px';
        $this->spaceWidth = '5px';
        $this->setControls($controls);
        $this->setDisposition($disposition);
    }

    public function setClass($cssClass)
    {
        $this->setBoxClass($cssClass);
    }

    public function setSpaceHeight($value)
    {
        $this->spaceHeight = $value;
    }

    public function setSpaceWidth($value)
    {
        $this->spaceWidth = $value;
    }

    public function setDisposition($disposition)
    {
        $this->disposition = ($disposition == 'none') ? 'horizontal' : $disposition;

/* o uso do separator foi substituido pelos atributos css - ely
        switch ($this->disposition)
            {
            case 'vertical':
                $div = new MSpacer($this->spaceHeight);

                break;

            case 'horizontal':
                $div = new MDiv('', $this->spaceWidth);

                break;

            default:
                $div = NULL;

                break;
            }

        $this->separator = $div;
*/
    }

    public function isShowLabel()
    {
        return $this->showLabel;
    }

    public function isShowChildLabel()
    {
        return $this->showChildLabel;
    }

    public function setShowChildLabel( $visible=true, $recursive=true )
    {
        $this->showChildLabel = $visible;
        $controls = $this->getControls();
        $this->setControls($controls,$recursive);
    }

    public function setShowLabel( $visible=true, $recursive=true )
    {
        $this->showLabel = $visible;

        if( $recursive )
        {
            $this->setShowChildLabel( $visible, $recursive );
        }
    }

    public function setControls($controls,$recursive=false)
    {
        $this->clearControls();

        foreach ( $controls as $c )
        {
            if ( $recursive && ($c instanceof MContainer) )
            {
                $c->setShowChildLabel($this->showChildLabel,true);
            }
            if( is_object($c) )  //acrescentado devido ao erro!
            {
                $c->showLabel = $this->showChildLabel;
                $this->addControl($c);
            }
            /*else
            {
                trigger_error( _M('Trying to access a property on a non-object'), E_USER_WARNING);
            }*/
        }
    }

    public function generateInner()
    {
        $float = false;
        $t = array();

        $controls = $this->getControls();

        foreach ($controls as $control)
        {
            $c = clone $control;
            if ($c instanceof MFormControl)
            {
                $c->setAutoPostBack($this->autoPostBack || $c->autoPostBack);
            }
            if ( $c->showLabel )
            {
               $c->formMode = $this->formMode;
            }

            if ($this->disposition == 'horizontal')
            {
//                $c->float = $this->separator->float = 'left';
                $c->float = 'left';
                $c->addBoxStyle('margin-right', $this->spaceWidth);
                $float = true;
            }
            else
            {
                if ( $this->formMode == MControl::FORM_MODE_SHOW_SIDE )
                {
                    $c = MForm::generateLayoutField($c);
                }
                else
                {
                    $c = new MDiv('', $c);
                    $c->addBoxStyle('margin-bottom', $this->spaceHeight);
                }
            }

            $t[] = MHtmlPainter::generateToString($c);
//            $t[] = $this->separator;
        }

        if ($float)
        {
            $t[] = new MSpacer();
        }

        $this->inner = $t;
        $this->getBox()->setAttributes($this->getAttributes());
    }
}

class MVContainer extends MContainer
{
    public function __construct($name = NULL, $controls = NULL, $formMode = MControl::FORM_MODE_SHOW_ABOVE)
    {
        parent::__construct($name, $controls, 'vertical', $formMode);
    }

}

class MHContainer extends MContainer
{
    public function __construct($name = NULL, $controls = NULL)
    {
        parent::__construct($name, $controls, 'horizontal');
    }
}
?>
