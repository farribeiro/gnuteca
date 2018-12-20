<?php

class MActionPanel extends MPanel
{
    public $iconType     = 'large';
    public $controlWidth;
    public $controlHeight;
    
    public function __construct($name = '', $caption = '', $controls = NULL, $close = '', $icon = '', $iconType='large')
    {
        parent::__construct($name, $caption, $controls, $close, $icon);
        $this->setIconType($iconType);
    }

    public function setIconType($type = 'large')
    {
        $this->iconType = $type;
        if ( $this->iconType == 'large' )
        {
            $this->setControlSize('70px','68px');
        }
        else
        {
            $this->setControlSize('135px','36px');
        }
    }

    public function setControlSize($width, $height)
    {
        $this->controlWidth  = $width;
        $this->controlHeight = $height;
    }

    private function _getControl($label, $image, $actionURL, $target = NULL)
    {
//        $control = new MImageLinkLabel('', $label, $actionURL, $image);
        $actionURL = 'go:' . $actionURL;
        $control = new MImageButtonLabel('', $label, $actionURL, $image);
        if( $target != NULL)
        {
            $control->setTarget($target);
        }
        if( $this->iconType != 'large')
        {
            $control->setImageType('icon');
        }

        if($this->controlWidth)
        {
            $control->width = $this->controlWidth;
        }
        
        if($this->controlHeight)
        {
            $control->height = $this->controlHeight;
        }
        return $control;
    }


    public function addAction($label, $image, $module = 'main', $action = '', $item = NULL, $args = NULL)
    {
        $actionURL = $this->manager->getActionURL($module, $action, $item, $args);
        $control = $this->_getControl($label, $image, $actionURL);
        $this->addControl($control);
    }

    public function addLink($label, $image, $link, $target=NULL)
    {
        $actionURL = ($link instanceof MLink) ? $link->href : $link;
        $control = $this->_getControl($label, $image, $actionURL, $target);
        $this->addControl($control);
    }

    public function insertAction($pos, $label, $image, $module = 'main', $action = '', $item = NULL, $args = NULL)
    {
        $actionURL = $this->manager->getActionURL($module, $action, $item, $args);
        $control = $this->_getControl($label, $image, $actionURL);
        $this->insertControl($pos, $control);
    }


    public function addUserAction($transaction, $access, $label, $image, $module = 'main', $action = '', $item = '', $args = NULL)
    {
        if ( $this->manager->perms->checkAccess($transaction, $access) )
        {
            $this->addAction($label, $image, $module, $action, $item, $args);
        }
    }


    public function insertUserAction($pos, $transaction, $access, $label, $image, $module = 'main', $action = '', $item = '', $args = NULL)
    {
        if ( $this->manager->checkAccess($transaction, $access) )
        {
            $this->insertAction($pos, $label, $image, $module, $action, $item, $args);
        }
    }

    public function addGroupAction($transaction, $access, $label, $image, $module = 'main', $action = '', $item = '', $args = NULL)
    {
        if ( $this->manager->perms->checkAccess($transaction, $access, false, true) )
        {
            $this->addAction($label, $image, $module, $action, $item, $args);
        }
    }


    public function insertGroupAction($pos, $transaction, $access, $label, $image, $module = 'main', $action = '', $item = '', $args = NULL)
    {
        if ( $this->manager->checkAccess($transaction, $access, false, true) )
        {
            $this->insertAction($pos, $label, $image, $module, $action, $item, $args);
        }
    }

    public function addBreak()
    {
        $this->addControl( new MSpacer(), '0', 'clear' );
    }
}

?>
