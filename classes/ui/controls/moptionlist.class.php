<?php

class MOptionListItem extends MControl
{
    public $type;
    public $control;


    public function __construct( $type, $control, $cssClass )
    {
        $this->type    = $type;
        $this->control = $control;
        $this->setClass($cssClass);
    }


    public function generateMenu()
    {
        return new MDiv( '', $this->control, $this->getClass() );
    }


    public function generateLink()
    {
        $this->control->setClass( $this->getClass() );

        return $this->control->generate();
    }


    public function generateOption()
    {
        $this->control->setClass( $this->getClass() );

        return $this->control->generate();
    }


    public function generateText()
    {
        $this->control->setClass( $this->getClass() );

        return $this->control;
    }


    public function generateSeparator()
    {
        return $this->control->generate();
    }

    public function generateControl()
    {
        return $this->control->generate();
    }

    public function generate()
    {
        $method = 'Generate' . ucfirst( $this->type );

        return $this->$method();
    }
}


class MOptionList extends MControl
{
    protected $options;
    protected $cssClassItem;


    public function __construct($name = '')
    {
        parent::__construct($name);

//        $this->addStyleFile('m_themeelement.css');
        $this->options = array ( );

        $this->cssClassItem['link']      = 'm-menu-link';
        $this->cssClassItem['option']    = 'm-menu-link';
        $this->cssClassItem['menuTitle'] = 'm-submenu-title';
        $this->cssClassItem['menuText']  = 'm-submenu-text';
        $this->cssClassItem['menu']      = 'm-submenu-box';
        $this->cssClassItem['text']      = 'm-submenu-text';
    }


    public function setCssClassItem( $type, $class )
    {
        $this->cssClassItem[$type] = $class;
    }


    public function getOptions()
    {
        return $this->options;
    }


    public function addItem( $type, $control )
    {
        $this->options[] = new MOptionListItem( $type, $control, $this->cssClassItem[$type] );
    }


    public function addLink( $label, $link = '#', $target = '_self' )
    {
        $control = new MLink( NULL, $label, $link, '', $target );
        $this->addItem( 'link', $control );
    }


    public function addHyperLink( $hyperlink )
    {
        $this->addItem( 'link', $hyperlink );
    }


    public function addLinkButton( $linkbutton )
    {
        $this->addItem( 'link', $linkbutton );
    }


    public function addOption( $label, $module = 'main', $action = '', $item = null, $args = null )
    {
        $control = new MLink( NULL, $label );
        $control->setAction( $module, $action, $item, $args );
        $this->addItem( 'option', $control );
    }


    public function addUserOption( $transaction, $access, $label, $module = 'main', $action = '', $item = '', $args = null )
    {
        if ( $this->manager->perms->checkAccess( $transaction, $access ) )
        {
            $this->addOption($label, $module, $action, $item, $args);
        }
    }


    public function addText($text = '')
    {
        $control = new MLabel($text);

        $this->addItem( 'text', $control, 'submenuText' );
    }


    public function addSeparator($name = null)
    {
        $this->addItem( 'separator', new MSeparator() );
    }


    public function addMenu( $menu )
    {
        $this->addItem( 'menu', $menu );
    }


    public function addUserMenu( $transaction, $access, &$menu )
    {
        if ( $this->manager->checkAccess( $transaction, $access) )
        {
            $this->addMenu($menu);
        }
    }


    public function addControl( $control )
    {
        $this->addItem( 'control', $control );
    }


    public function clear()
    {
        $this->options = array ( );
    }


    public function hasOptions()
    {
        return ( count($this->options) > 0 );
    }


    public function generateUnorderedList()
    {
        $ul = new MUnorderedList();

        if ($this->hasOptions())
        {
            foreach ( $this->options as $o )
            {
                $ul->addOption( $o->generate() );
            }
        }

        return $ul;
    }
}

?>