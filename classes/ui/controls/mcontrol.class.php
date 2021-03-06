<?php
/**
 * Base class for all controls.
 * This class implements the properties and methods shared by all controls.
 *
 * @author Ely Edison Matos [ely.matos@ufjf.edu.br]
 * 
 * @version 1.0
 *
 * \b Maintainers: \n
 * Ely Edison Matos [ely.matos@ufjf.edu.br] 
 * 
 * @see 
 * {@link MComponent}
 *
 * @since 
 * This class was created 2005/01/01
 *
 * \b Organization: \n
 * SOLIS - Cooperativa de Solu��es Livres \n
 * The Miolo Development Team
 * 
 * \b CopyLeft: \n
 * CopyLeft (L) 2005 SOLIS - Cooperativa de Solu��es Livres \n
 *
 * \b License: \n
 * Licensed under GPL (for further details read the COPYING file or http://www.gnu.org/copyleft/gpl.html )
 * 
 * \b History: \n
 * See history in CVS repository: http://www.miolo.org.br
 * 
 */

abstract class MControl extends MComponent
{
    /**
     *  Center alignment
     */
    const ALIGN_CENTER = 'center';

    /**
     * Left alignment
     */
    const ALIGN_LEFT = 'left';

    /**
     * Right alignment
     */
    const ALIGN_RIGHT = 'right'; 

    /**
     * Horizontal layout
     */
    const LAYOUT_HORIZONTAL = 'horizontal';
    
    /**
     * Vertical layout
     */
    const LAYOUT_VERTICAL = 'vertical';
    
    /** 
     * Define the constants to be used
     * to indicate the $formMode
     */
    const FORM_MODE_WHOLE_ROW  = 0;
    const FORM_MODE_SHOW_SIDE  = 1;
    const FORM_MODE_SHOW_ABOVE = 2;
    const FORM_MODE_SHOW_NBSP  = 3;

    /** 
     * A number used to identify anonymous controls.
     */
    static  $_number = 0;

    /** 
     * An id based in $number.
     */
    private $_numberId;

    /** 
     * A id for the control.
     * This atribute identifies the control. It is used at (X)HTML rendering.
     */
    public $id;

    /** 
     * Another id for the control.
     * This atribute identifies the control's box in (X)HTML rendering.
     */
    public $uniqueId;

    /** 
     * CSS selector.
     */
    public $cssClass;

    /** 
     * Indicates if the control is enabled/disabled.
     */
    public $enabled;

    /** 
     * A list with style attributes.
     */
    public $style;

    /** 
     * Indicates if the control is to be showed.
     */
    public $visible;

    /** 
     * A list with (X)HTML attributes.
     */
    public $attrs; // array with HTML attributes

    /** 
     * A string with (X)HTML attributes.
     * For compatibilty only.
     */
    public $attributes;

    /** 
     * Indicates how to render the control/caption in the page.
     * FORM_MODE_WHOLE_ROW  = 0 : the control ocuppies whole row of form
     * FORM_MODE_SHOW_SIDE  = 1 : show caption: control side by side
     * FORM_MODE_SHOW_ABOVE = 2 : show caption: above the control
     * FORM_MODE_SHOW_NBSP  = 3 : show caption:&nbsp;&nbsp;control
     */
    public $formMode;

    /**
     * Indicates if the control is to be mantained in round-trips.
     */
    public $maintainState;

    /**
     * Show the control as a label.
     */
    public $readonly;

    /**
     * A caption for the control.
     */
    public $caption;

    /**
     * A hint showed as tooltip, using javascript.
     */
    public $jsHint;

    /**
     * The control's code according to render method.
     * The $inner is generated by the control itself, according to its properties.
     */
    public $inner;

    /**
     * The box that contains the control.
     * It is used, primarily, in CSS Positioning.
     */
    public $controlBox;
    public $box;

    /** 
     * Indicates if the control is to be CSS Positioned
     */
    public $cssp;

    /**
     * The parent component (the owner of this control).
     */
    public $parent;

    /**
     * A list with the contained controls, indexed by numbers.
     */
    public $controls;

    /** 
     * A list with the contained controls, indexed by id.
     */
    public $controlsId;
    //    var $controlsCount;

    /**
     * A list with registered event handlers .
     */
    public $eventHandlers;

    /**
     * The class for renderize controls.
     */
    public $painter;


    /**
     * Initialize some properties.
     * @param $name (string) a optional name for the control
     */
    public function __construct( $name = NULL )
    {
        parent::__construct( $name );

        $this->_numberId = MControl::$_number++;
//        $this->id        = ( ( $this->name == NULL ) ? 'm'.$this->_numberId : $this->name );
        $this->id        = $name;
        $this->cssClass  = '';
        $this->enabled   = true;
        $this->attrs     = new MStringList();
        $this->style     = new MStringList();
        $this->visible   = true;
        $this->formMode  = FORM_MODE_WHOLE_ROW;
        $this->maintainState = false;
        $this->readonly   = false;
        $this->cssp       = false;
        $this->uniqueId   = 'm'.$this->_numberId;
        $this->controls   = new MObjectList();
        $this->controlsId = new MObjectList();
        $this->eventHandlers = array ( );
        $this->inner   = '';
        $this->box     = NULL;
        $this->painter = $this->manager->getPainter();
    }

    /** 
     * The clone method.
     * It is used to clone controls, avoiding references to same attributes, styles and controls.
     */
    public function __clone()
    {
        $this->attrs      = clone $this->attrs; 
        $this->style      = clone $this->style; 
        $this->controls   = clone $this->controls; 
        $this->controlsId = clone $this->controlsId; 
    }

    public function __toString()
    {
        return '';
    }
 
    /** 
     * The setter method.
     * It is used, primarily, to decide if a attribute is for the control or for CSS Box.
     */
    public function __set( $name, $value )
    {
        switch ( $name )
            {
            case 'color':
            case 'font':
            case 'border':
                $this->_addStyle( $name, $value );

                break;

            case 'fontSize':
                $this->_addStyle( 'font-size', $value );

                break;

            case 'fontStyle':
                $this->_addStyle( 'font-style', $value );

                break;

            case 'fontFamily':
                $this->_addStyle( 'font-family', $value );

                break;

            case 'fontWeight':
                $this->_addStyle( 'font-weight', $value );

                break;

            case 'cursor':
                $this->_addStyle( 'cursor', $value );
                $this->addBoxStyle('cursor', $value);

                break;

            case 'textAlign':
                $this->_addStyle  ( 'text-align', $value );
                $this->addBoxStyle( 'text-align', $value );

                break;

            case 'textIndent':
                $this->_addStyle  ( 'text-indent', $value );
                $this->addBoxStyle( 'text-indent', $value );

                break;

            case 'lineHeight':
                $this->_addStyle( 'line-height', $value );

                break;

            case 'padding':
            case 'margin':
            case 'width':
            case 'height':
            case 'float':
            case 'clear':
            case 'visibility':
                $this->addBoxStyle( $name, $value );

                break;

            case 'top':
            case 'left':
            case 'position':
                $this->addBoxStyle( $name, $value );

                break;

            case 'zIndex':
                $this->addBoxStyle( 'z-index', $value );

                $this->cssp = true;
                break;

            case 'backgroundColor':
                $this->addBoxStyle( 'background-color', $value );

                break;

            case 'verticalAlign':
                $this->addBoxStyle( 'vertical-align', $value );

                break;

            default:
                $this->_addStyle( $name, $value );

                break;
            }
    }


    public function __get( $name )
    {
        switch ( $name )
            {
            case 'top':
            case 'left':
            case 'width':
            case 'height':
            case 'padding':
            case 'float':
            case 'position':
                return $this->getBox()->style->get( $name );

                break;
            }
    }


    protected function _AddStyle($name, $value)
    {
        if ( $value != '' )
        {
            $this->style->addValue($name, $value);
        }
    }


    public function setReadOnly($status)
    {
        $this->readonly = $status;
    }

    /**
     * Enabled status.
     * Acessory method to set the enabled status of the control.
     * 
     * @param state (boolean) true or false depending the status
     */
    public function setEnabled($state)
    {
        $this->enabled = $state;
    }

    public function setName($name)
    {
        MUtil::setIfNull($this->id, $name);

        parent::setName($name);
    }


    public function setId($id)
    {
        $this->id = $id;
        MUtil::setIfNull( $this->name, $id );
    }


    public function getId()
    {
        return $this->id;
    }


    public function getName()
    {
        return $this->name;
    }


    public function getUniqueId()
    {
        return $this->uniqueId;
    }


    public function setClass( $cssClass, $add =false )
    {
        if ( $add )
        {
            $this->cssClass .= MUtil::ifNull($this->cssClass, '', ' ') . $cssClass;
        }
        else
        {
            $this->cssClass = $cssClass;
        }

    }


    public function addStyleFile( $styleFile )
    {
        $this->page->addStyle($styleFile);
    }


    public function getClass()
    {
        return $this->cssClass;
    }


    public function addStyle($name, $value)
    {
        $this->$name = $value;
    }

    public function setStyle($style)
    {
        $this->style->items = $style;
    }

    public function getStyle()
    {
        return $this->style->hasItems() ? " style=\"" . $this->style->getText(':', ';') . "\"" : '';
    }


    public function addAttribute( $name, $value = '' )
    {
        $this->attrs->addValue( $name, ( $value != '' ) ? "\"$value\"" : '' );
    }


    public function setAttribute( $name, $value )
    {
        $this->addAttribute( $name, $value );
    }

    public function getAttribute( $name )
    {
        $items = $this->attrs->getItems();
        $a = $items[strtolower($name)];
        return substr($a,1,strlen($a)-1);
    }

    public function setAttributes($attr)
    {
        if ( $attr != NULL )
        {
            if ( is_array($attr) )
            {
                foreach( $attr as $ak => $av )
                {
                    $this->setAttribute($ak, $av);
                }
            }
            else if ( is_string($attr) )
            {
                $attr = str_replace( "\"", '', trim($attr) );

                foreach ( explode(' ', $attr) as $a )
                {
                    $a = explode('=', $a);
                    $this->setAttribute($a[0], $a[1]);
                }
            }
        }
    }

    public function attributes( $mergeDuplicates=false )
    {
        if ( $mergeDuplicates )
        {
            $items = $this->attrs->getItems();

            $items_new = array( );
            foreach( $items as $id=>$item )
            {
                if ( $items_new[ strtolower($id) ] )
                {
                    $items_new[ strtolower($id) ] = substr($items_new[ strtolower($id) ], 0, -1) .';' . substr($item, 1);
                }
                else
                {
                    $items_new[ strtolower($id) ] = $item;
                }
            }
            $this->attrs->setItems( $items_new );
        }
        return $this->attrs->hasItems() ? ' ' . $this->attrs->getText("=", " ") : '';
    }

    public function getAttributes( $mergeDuplicates=false )
    {
        return $this->attributes( $mergeDuplicates ) . $this->getStyle();
    }

    public function setFormMode( $mode )
    {
        $this->formMode = $mode;
    }

    public function setJsHint( $hint )
    {
        if ( $hint != '' )
        {
            $this->jsHint = $hint;
            $this->page->addDojoRequire("dijit.Tooltip");
        }
        return;
    }

    public function setPosition($left, $top, $position = 'absolute')
    {
        $this->addBoxStyle('position', $position);
        $this->addBoxStyle('left', "{$left}px");
        $this->addBoxStyle('top', "{$top}px");
    }

    public function setWidth($value)
    {
        if ( ! $value )
        {
            return;
        }

        if ( strpos($value, '%') === false )
        {
            $v = "{$value}";
        }
        else
        {
            $v = $value;
        }

        $this->addBoxStyle('width', $v);
    }

    public function setHeight($value)
    {
        if ( ! $value )
        {
            return;
        }

        if ( strpos($value, '%') === false )
        {
            $v = "{$value}px";
        }
        else
        {
            $v = $value;
        }

        $this->addBoxStyle('height', $v);
    }

    public function setColor($value)
    {
        $this->addStyle('color', $value);
    }

    public function setVisibility($value)
    {
        $value = ($value ? 'visible' : 'hidden');
        $this->visibility = $value;
    }

    public function setFont($value)
    {
        $this->addStyle('font', $value);
    }

    public function setCaption($caption)
    {
        $this->caption = $caption;
    }

    public function setHTMLTitle($title)
    {
        $this->addAttribute('title',$title);
    }

    public function setInner($inner)
    {
        $this->inner = $inner;
    }

    public function getInner()
    {
        return $this->inner;
    }

    //
    // Controls
    //
    protected function _AddControl($control, $pos = 0, $op = 'add')
    {
        if(is_array($control))
        {
            foreach($control as $c)
            {
                $this->_AddControl($c);
            }
        }
        elseif ( $control instanceof MControl )
        {
            if ( $op == 'add' )
            {
                $this->controlsId->add($control, $control->getId() );
                $this->controls->add($control);
            }
            elseif ( $op == 'ins' )
            {
                $this->controlsId->add($control, $control->getId() );
                $this->controls->insert($control, $pos);
            }
            elseif ( $op == 'set' )
            {
                $this->controlsId->set( $control->getId(), $control );
                $this->controls->set($pos, $control);
            }

            $control->parent = $this;
        }
        elseif ( ! is_null($control) )
        {
            if ( ! is_object($control) )
            {
                throw new EControlException(
                          "Using non-object with _AddControl;<br/>type: " . gettype($control) . ';<br/>value: ' . $control
                              . ';<br/>Try using Label control instead');
            }
            else
            {
                throw new EControlException('Using non-control with _AddControl; class: ' . get_class($control).'; name: '.$control->name.'; id: '.$control->id);
            }
        }
    }

    public function addControl($control)
    {
        $this->_AddControl($control);
    }

    public function insertControl($control, $pos = 0)
    {
        $this->_AddControl($control, $pos, 'ins');
    }

    public function setControl($control, $pos = 0)
    {
        $this->_AddControl($control, $pos, 'set');
    }

    public function setControls($controls)
    {
        $this->clearControls();

        foreach ( $controls as $c )
            $this->addControl($c);
    }

    public function getControls()
    {
        return $this->controls->items;
    }

    public function getControl($pos)
    {
        return $this->controls->get($pos);
    }

    public function getControlById($id)
    {
        return $this->controlsId->get($id);
    }

    public function findControlById($id)
    {
        $k = NULL;
        $controls = $this->controlsId->items;
        foreach ( $controls as $c )
        {
            if ( $c->id == $id )
            {
                return $c;
            }

            elseif ( ( $k = $c->findControlById($id) ) != NULL )
                break;
        }
        return $k;
    }

    public function setControlById($control, $id)
    {
        $this->controlsId->set($id, $control);
    }

    public function clearControls()
    {
        $this->controls->clear();
        $this->controlsId->clear();
    }

    //
    //  EventHandler
    // 
    public function eventHandler()
    {
        $subject = $this;
        $form = $this->manager->formSubmit;
        $event = MIOLO::_REQUEST($form.'__EVENTTARGETVALUE');
        $args  = MIOLO::_REQUEST($form.'__EVENTARGUMENT');
        if ($event == '')
        {
            $event = MIOLO::_REQUEST('__EVENTTARGETVALUE');
            $args  = MIOLO::_REQUEST('__EVENTARGUMENT');
        }
        if (($args == '') && ( $this->manager->getIsAjaxCall() ))
        {
            $args = (object)$_REQUEST;
        }
        if ($event != '')
        {
            $eventTokens = explode(':', $event);
            $sender = $subject->findControlById( $eventTokens[0] );
            $func   = str_replace(':', '_', $event);
            if ( method_exists($subject, $func) )
            {
                $subject->$func($args);
            }
            elseif ( $sender instanceof MControl )
            {
                $eventType = $eventTokens[1];
                $func      = $sender->eventHandlers[$eventType]['handler'];
                if ( ! is_null($func) )
                {
                    if ( method_exists($subject, $func) )
                    {
                        $subject->$func($args);
                    }
                    elseif ( function_exists($func) )
                    {
                        $func($args);
                    }
                }
            }
        }
        if($eventTokens = explode(';', MIOLO::_REQUEST('event')))
        {
            $e = str_replace(':', '_', $eventTokens[0]);

            if ( (strtolower($e) !== strtolower($func)) && (method_exists($subject, $e) ) )
            {
                $params = $eventTokens[1];
                $subject->$e($params);
            }
        }
    }


    public function attachEventHandler( $name, $handler, $param = NULL )
    {
        $this->eventHandlers[$name]['handler'] = $handler;
        $this->eventHandlers[$name]['param']   = $param;
    }

    public function attachEvent($event, $handler)
    {
        if ( $handler{0} == ':' )
        {
            $handler = $this->manager->getUI()->getAjax($handler);
            $this->addAttribute("on".$event, $handler);
        }
        else
        {
            $connect = "miolo.connect(\"{$this->id}\",\"{$event}\",{$handler});";
            $this->page->onLoad($connect);
        }
    }

    public function getBox()
    {
        $this->cssp = true;

        if ( is_null($this->box) )
        {
            $this->box = new MControlConcrete( 'm_' . MUtil::NVL( $this->name, $this->uniqueId ) );
        }

        return $this->box;
    }


    public function setBoxId( $id )
    {
        $this->getBox()->setId( $id );
    }


    public function setBoxClass( $cssClass, $add = true )
    {
        $this->getBox()->setClass( $cssClass, $add );
    }


    public function getBoxClass()
    {
        return $this->getBox()->cssClass;
    }

    public function addBoxAttribute($attr,$value)
    {
        $this->getBox()->addAttribute($attr,$value);
    }

    public function setBoxAttributes($attr)
    {
        $this->getBox()->setAttributes($attr);
    }

    public function getBoxAttributes()
    {
        return $this->getBox()->getAttributes();
    }

    public function addBoxStyle($name, $value)
    {
        $this->getBox()->_AddStyle($name, $value);
    }


    public function generateBox( $content )
    {
        $box = $this->getBox();
        $box->inner = $content;

        return $box->getRender('div');
    }

    public function getRender( $method )
    {
        return $this->painter->$method( $this );
    }


    public function getInnerToString()
    {
        return $this->painter->generateToString( $this->getInner() );
    }


    public function generateInner()
    {
        if ( $this->inner == '' )
        {
            if ( $this->controls->hasItems() )
            {
                $this->inner = $this->controls->items;
            }
        }
    }


    public function generate()
    {
        $this->generateInner();
        $content = $this->getInner();

        if ( $this->jsHint != '' )
        {
//            $hint = new MSpan('', $content, 'tipHint');
//            $hint->addAttribute( "title", "{$this->jsHint}" );
            $jsHint = $this->jsHint;
            $hint = new MDiv('', '', null, "dojoType=\"dijit.Tooltip\" connectId=\"{$this->getId()}\" ");
            $hint->addBoxAttribute("label",$jsHint);
//            $hint->addAttribute( "connectId", $this->getId() );
//            $hint->addAttribute( "label", "{$this->jsHint}" );
            $content = $hint->generate() .$content;
//var_dump($content);
        }
        if ( count($this->eventHandlers) )
        {
            foreach($this->eventHandlers as $eventType=>$event)
            {
                if ( ! strncmp($eventType,'on',2) )
                {
                    $this->page->addScript('x/x_core.js');
                    $this->page->addScript('x/x_event.js');
                    $eventType = substr($eventType,2);
                    $this->page->onLoad("xAddEventListener('{$this->id}','{$eventType}' ,{$event['handler']});");
                }
            }
        }

        return ( $this->cssp ? $this->generateBox($content) : $this->painter->generateToString($content) );
    }
}

class MControlConcrete extends MControl
{
}

?>
