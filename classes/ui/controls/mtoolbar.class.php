<?php
/**
 *  Mtoolbar component
 *
 * @author Daniel Afonso Heisler [daniel@solis.coop.br]
 *
 * @version $id$
 *
 * \b Maintainers: \n
 * Vilson Cristiano Gartner [vilson@miolo.org.br]
 * Armando Taffarel Neto [taffarel@solis.coop.br]
 *
 * @since
 * Creation date 2005/08/04
 *
 * \b Organization: \n
 * SOLIS - Cooperativa de Soluções Livres \n
 * The MIOLO2 AND SAGU2 Development Team
 *
 * \b CopyLeft: \n
 * Copyright (c) 2005 SOLIS - Cooperativa de Soluções Livres \n
 *
 * \b License: \n
 * Licensed under GPLv2 (for further details read the COPYING file or http://www.gnu.org/licenses/gpl.html)
 *
 * \b History: \n
 * See history in CVS repository: http://www.miolo.org.br
 *
 */

/*
 * Class MImageLabel
 * 
 * Component similar to MImageButtonLabel, but with no action 
 */
class MImageLabel extends MImage
{
    public function generateInner()
    {
        parent::generateInner();

        $image = new MDiv( '', $this->inner , 'm-image-centered' );
        $text  = new MSpan( '', $this->label, 'm-image-label' );
        $this->inner = $image->generate() . $text->generate();
    }
}

/*
 * Class MToolbarButton
 * 
 * Each part of Toolbar
 */
class MToolBarButton extends MFormControl
{
    public  $name;
    public  $caption;
    public  $enabled;
    public  $visible = true;

    protected $url;
    public  $hint;
    protected $enabledImage;
    protected $disabledImage;
    protected $type;

    /**
     * This is the constructor of the MToolbar class.
     *
     * @param $name (string) MToolbarButton name
     * @param $caption (string) Caption description
     * @param $url (string) Button action
     * @param $hint (string) Button hint
     * @param $enable (boolean) Button status
     * @param $enabledImage (string) Complete image URL
     * @param $disabledImage (string) Complete image URL
     * @param $method (string) Deprecated
     * @param $type (string) Button type: MToolBar::TYPE_ICON_ONLY, MToolBar::TYPE_ICON_TEXT or MToolBar::TYPE_TEXT_ONLY
     * 
     */
    public function __construct($name, $caption, $url, $hint, $enabled, $enabledImage, $disabledImage, $method='', $type)
    {
        parent::__construct($name);
        
        $this->name    = $name;
        $this->caption = $caption;
        $this->hint    = $hint;
        $this->enabled = $enabled;
        $this->enabledImage  = $enabledImage;
        $this->disabledImage = $disabledImage;
        /* DEPRECATED: $method */
        $this->url     = $url;
        $this->type    = $type;

    }
    /**
     * Set button type
     * 
     * @param $type (string) Button type: MToolBar::TYPE_ICON_ONLY, MToolBar::TYPE_ICON_TEXT or MToolBar::TYPE_TEXT_ONLY
     * 
     */    
    public function setType($type=MToolBar::TYPE_ICON_ONLY)
    {
        $this->type = $type;
    }

    /**
     * Show button
     * 
     */
    public function show()
    {
        $this->visible = true;
    }

    /**
     * Hide Button
     *
     */
    public function hide()
    {
        $this->visible = false;
    }

    /**
     * Enable button
     *
     */
    public function enable()
    {
        $this->enabled = true;
    }

    /**
     * Disable button
     *
     */
    public function disable()
    {
        $this->enabled = false;
    }
    
    /**
     * generateInner method
     * 
     */
    public function generateInner()
    {
        if ( $this->visible )
        {
            if ( $this->enabled )
            {
                $image = $this->enabledImage;

                if ( $this->type == MToolBar::TYPE_ICON_ONLY )
                {
                    $button = new MImageButton($this->name, $this->caption, $this->url, $image);
                }
                elseif ( $this->type == MToolBar::TYPE_ICON_TEXT )
                {
                    $button = new MImageButtonLabel($this->name, $this->caption, $this->url, $image);
                }
                elseif ( $this->type == MToolBar::TYPE_TEXT_ONLY )
                {
                    $button = new MLink($this->name, $this->caption, $this->url);
                }
            }
            else
            {
                $image = $this->disabledImage;

                if ( $this->type == MToolBar::TYPE_ICON_ONLY )
                {
                    $button = new MImage($this->name, $this->caption, $image);
                }
                elseif ( $this->type == MToolBar::TYPE_ICON_TEXT )
                {
                    $button = new MImageLabel($this->name, $this->caption, $image);
                }
                elseif ( $this->type == MToolBar::TYPE_TEXT_ONLY )
                {
                    $button = new MLabel($this->caption);
                }
            }
            #$button->setJSHint( $this->hint );
            $button->addAttribute('alt' , $this->hint);
            $button->addAttribute('titte' , $this->hint);
            
            if ( $this->enabled )
            {
                $this->inner = new MDiv('', $button, 'm-toolbar-button');
            }
            else
            {
                $this->inner = new MDiv('', $button, 'm-toolbar-button-disabled');
            }
        }
    }

}

/*
 * Class MToolbar
 * 
 */
class MToolBar extends MBaseGroup
{
    /**
     * Button's name constants
     *
     */
    const BUTTON_NEW    = 'tbBtnNew';
    const BUTTON_SAVE   = 'tbBtnSave';
    const BUTTON_DELETE = 'tbBtnDelete';
    const BUTTON_SEARCH = 'tbBtnSearch';
    const BUTTON_PRINT  = 'tbBtnPrint';
    const BUTTON_RESET  = 'tbBtnReset';
    const BUTTON_EXIT   = 'tbBtnExit';
    
    /**
     * Toolbar button types
     *
     */
    const TYPE_ICON_ONLY = 'icon-only';
    const TYPE_TEXT_ONLY = 'text-only';
    const TYPE_ICON_TEXT = 'icon-text';

    protected $toolBarButtons;
    protected $width = '98%'; //MIOLO Default

   /**
    * MToolbar constructor
    * 
    * @param $name (string) Toolbar name
    * @param $url (string) Default URL
    * @param $type (string) Buttons type: MToolBar::TYPE_ICON_ONLY, MToolBar::TYPE_ICON_TEXT or MToolBar::TYPE_TEXT_ONLY
    * 
    */
    public function __construct($name='toolbar',  $url='', $type=MToolbar::TYPE_ICON_ONLY)
    {
        parent::__construct($name, '');

        $MIOLO  = MIOLO::getInstance();
        $module = MIOLO::getCurrentModule();
        $action = MIOLO::getCurrentAction();
        
        $this->name = $name;

        if( ! $url )
        {
            $url = $MIOLO->getActionURL( $module, $action);
        }

        $enabledImage  = $MIOLO->getUI()->getImageTheme($MIOLO->theme->id, 'toolbar-new.png');
        $disabledImage = $MIOLO->getUI()->getImageTheme($MIOLO->theme->id, 'toolbar-new-disabled.png');
        /*FIXME: Please find a better way to set the event*/
        $event         = $url . "&{$MIOLO->page->getFormId()}__EVENTTARGETVALUE=" . MToolBar::BUTTON_NEW . ':click';
        $newUrl        = $event . '&function=insert';
        $newUrl        = "miolo.doLink('$newUrl','{$MIOLO->page->getFormId()}')";
        $this->toolBarButtons[MToolBar::BUTTON_NEW] = new MToolBarButton(MToolBar::BUTTON_NEW, _M('New'), $newUrl, _M('Click to insert new record'), true, $enabledImage, $disabledImage, NULL, $type);

        $enabledImage  = $MIOLO->getUI()->getImageTheme($MIOLO->theme->id, 'toolbar-save.png' );
        $disabledImage = $MIOLO->getUI()->getImageTheme($MIOLO->theme->id, 'toolbar-save-disabled.png' );
        $event         = MToolBar::BUTTON_SAVE . ':click';
        $newUrl        = "miolo.doPostBack('$event','','{$MIOLO->page->getFormId()}')";
        $this->toolBarButtons[MToolBar::BUTTON_SAVE] = new MToolBarButton(MToolBar::BUTTON_SAVE, _M('Save'), $newUrl, _M('Click to save this record'), true, $enabledImage, $disabledImage, NULL, $type);

        $enabledImage  = $MIOLO->getUI()->getImageTheme($MIOLO->theme->id, 'toolbar-delete.png');
        $disabledImage = $MIOLO->getUI()->getImageTheme($MIOLO->theme->id, 'toolbar-delete-disabled.png');
        /*FIXME: Please find a better way to set the event*/
        $event         = MToolBar::BUTTON_DELETE . ':click';
        $newUrl        = "miolo.doAjax('$event','','{$MIOLO->page->getFormId()}')";
        $this->toolBarButtons[MToolBar::BUTTON_DELETE] = new MToolBarButton(MToolBar::BUTTON_DELETE, _M('Delete'), $newUrl, _M('Click to delete this record'), true, $enabledImage, $disabledImage, NULL, $type);

        $enabledImage  = $MIOLO->getUI()->getImageTheme($MIOLO->theme->id, 'toolbar-search.png');
        $disabledImage = $MIOLO->getUI()->getImageTheme($MIOLO->theme->id, 'toolbar-search-disabled.png');
        $event         = $url . "&{$MIOLO->page->getFormId()}__EVENTTARGETVALUE=" . MToolBar::BUTTON_SEARCH . ':click';
        $newUrl        = $event . '&function=search';
        $newUrl        = "miolo.doLink('$newUrl','{$MIOLO->page->getFormId()}')";
        $this->toolBarButtons[MToolBar::BUTTON_SEARCH] = new MToolBarButton(MToolBar::BUTTON_SEARCH, _M('Search'), $newUrl, _M('Click to go to search page'), true, $enabledImage, $disabledImage, NULL, $type);

        $enabledImage  = $MIOLO->getUI()->getImageTheme($MIOLO->theme->id, 'toolbar-print.png');
        $disabledImage = $MIOLO->getUI()->getImageTheme($MIOLO->theme->id, 'toolbar-print-disabled.png');
        $event         = MToolBar::BUTTON_PRINT . ':click';
        $newUrl        = "miolo.doAjax('$event','','{$MIOLO->page->getFormId()}')";
        $this->toolBarButtons[MToolBar::BUTTON_PRINT] = new MToolBarButton(MToolBar::BUTTON_PRINT, _M('Print'), $newUrl, _M('Click to print'), true, $enabledImage, $disabledImage, NULL, $type);

        $enabledImage  = $MIOLO->getUI()->getImageTheme($MIOLO->theme->id, 'toolbar-reset.png');
        $disabledImage = $MIOLO->getUI()->getImageTheme($MIOLO->theme->id, 'toolbar-reset-disabled.png');
        $newUrl        = 'document.forms[0].reset()';
        $this->toolBarButtons[MToolBar::BUTTON_RESET] = new MToolBarButton(MToolBar::BUTTON_RESET, _M('Reset'), $newUrl, _M('Click to reset the form'), true, $enabledImage, $disabledImage, NULL, $type);
                
        $enabledImage  = $MIOLO->getUI()->getImageTheme($MIOLO->theme->id, 'toolbar-exit.png');
        $disabledImage = $MIOLO->getUI()->getImageTheme($MIOLO->theme->id, 'toolbar-exit-disabled.png');
        /*FIXME: getPreviousURL doesn't returns complete URL*/
        $newUrl        = $MIOLO->getConf('home.url') . '/' . $MIOLO->getPreviousUrl();
        $newUrl        = "miolo.doLink('$newUrl','{$MIOLO->page->getFormId()}')";
        $this->toolBarButtons[MToolBar::BUTTON_EXIT] = new MToolBarButton(MToolBar::BUTTON_EXIT, _M('Exit'), $newUrl, _M('Click to exit this form'), true, $enabledImage, $disabledImage, NULL, $type);

        $this->setShowChildLabel(false);

        $this->page->onload("dojo.parser.parse('$this->name');");
    }

    /**
     * Adds a custom button
     *
     * @param $name (string) MToolbarButton name
     * @param $caption (string) Caption description
     * @param $url (string) Button action
     * @param $hint (string) Button hint
     * @param $enable (boolean) Button status
     * @param $enabledImage (string) Complete image URL
     * @param $disabledImage (string) Complete image URL
     * @param $method (string) Deprecated
     * @param $type (string) Button type: MToolBar::TYPE_ICON_ONLY, MToolBar::TYPE_ICON_TEXT or MToolBar::TYPE_TEXT_ONLY
     * 
     */
    public function addButton($name, $caption, $url, $hint, $enabled, $enabledImage, $disabledImage, $type=MToolBar::TYPE_ICON_ONLY)
    {
        $this->toolBarButtons[$name] = new MToolBarButton($name, $caption, $url, $hint, $enabled, $enabledImage, $disabledImage, NULL, $type);
    }
    
    /**
     * Shows one or more buttons
     *
     * @param $name (string or array) Button's name
     */
    public function showButtons($name)
    {
        if ( is_array($name) )
        {
            foreach ( $name as $n )
            {
                $this->toolBarButtons[$n]->show();
            }
        }
        else
        {
            $this->toolBarButtons[$name]->show();    
        }
    }

    /**
     * Shows one or more buttons
     *
     * @deprecated use showButtons instead
     * 
     * @param $name (string or array) Button's name
     */    
    public function showButton($name)
    {
        $MIOLO = MIOLO::getInstance();
        
        $MIOLO->logMessage('[DEPRECATED] Call method MToolbar::showButton() is deprecated -- use MToolbar::showButtons() instead!');
        
        $this->showButtons($name);
    }
    /**
     * Hides one or more buttons
     *
     * @param $name (string or array) Button's name
     */
    public function hideButtons($name)
    {
        if ( is_array($name) )
        {
            foreach ( $name as $n )
            {
                $this->toolBarButtons[$n]->hide();
            }
        }
        else
        {
            $this->toolBarButtons[$name]->hide();    
        }
    }

    /**
     * Hides one or more buttons
     *
     * @deprecated use hideButtons instead
     * 
     * @param $name (string or array) Button's name
     */    
    public function hideButton($name)
    {
        $MIOLO = MIOLO::getInstance();
        
        $MIOLO->logMessage('[DEPRECATED] Call method MToolbar::hideButton() is deprecated -- use MToolbar::hideButtons() instead!');
        
        $this->hideButtons($name);
    }

	/**
     * Enables one or more buttons
     *
     * @param $name (string or array) Button's name
     */
    public function enableButtons($name)
    {
        if ( is_array($name) )
        {
            foreach ( $name as $n )
            {
                $this->toolBarButtons[$n]->enable();
            }
        }
        else
        {
            $this->toolBarButtons[$name]->enable();    
        }
    }
    
    /**
     * Enables one or more buttons
     *
     * @deprecated use enableButtons instead
     * 
     * @param $name (string or array) Button's name
     */    
    public function enableButton($name)
    {
        $MIOLO = MIOLO::getInstance();
        
        $MIOLO->logMessage('[DEPRECATED] Call method MToolbar::enableButton() is deprecated -- use MToolbar::enableButtons() instead!');
        
        $this->enableButtons($name);
    }

	/**
     * Disables one or more buttons
     *
     * @param $name (string or array) Button's name
     */
    public function disableButtons($name)
    {
        if ( is_array($name) )
        {
            foreach ( $name as $n )
            {
                $this->toolBarButtons[$n]->disable();
            }
        }
        else
        {
            $this->toolBarButtons[$name]->disable();    
        }
    }

   
    /**
     * Disables one or more buttons
     *
     * @deprecated use disablesButtons instead
     * 
     * @param $name (string or array) Button's name
     */    
    public function disableButton($name)
    {
        $MIOLO = MIOLO::getInstance();
        
        $MIOLO->logMessage('[DEPRECATED] Call method MToolbar::disableButton() is deprecated -- use MToolbar::disableButtons() instead!');
        
        $this->disableButtons($name);
    }
    
    /**
     * Set button's type
     * 
     * @param $type (string) Button type: MToolBar::TYPE_ICON_ONLY, MToolBar::TYPE_ICON_TEXT or MToolBar::TYPE_TEXT_ONLY
     * 
     */     
    public function setType($type=MToolBar::TYPE_ICON_ONLY)
    {
        foreach ( $this->toolBarButtons as $tbb )
        {
            $tbb->setType($type);
        }
    }
    
    /**
     * Set toolbar width
     *
     * @param $width (string) Width size
     */
    public function setWidth($width)
    {
        $this->width = $width;
    }
    
    /**
     * Add custom control to toolbar
     *
     * @param $control (object) mcontrol instance
     * @param $name (string) control name
     */    
    public function addControl($control, $name=NULL)
    {
        parent::addControl($control);
        
        if ( $name )
        {
            $this->toolBarButtons[$name] = $control;
        }
    }
    
    /**
     * generateInner method
     *
     */
    public function generateInner()
    {
        parent::__construct( $this->name, '', $this->toolBarButtons );

        parent::setWidth($this->width);

        parent::generateInner();
    }
}

?>
