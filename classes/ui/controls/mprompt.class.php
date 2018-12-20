<?php

/**
 * Dialogs classes.
 * Implementation of the prompt class for generating common dialogs.
 * 
 * @author Vilson Cristiano Gartner [author] [vgartner@gmail.com]
 * @author Thomas Spriestersbach    [author] [ts@interact2000.com.br]
 * 
 * \b Maintainers: \n
 * Vilson Cristiano Gartner [author] [vilson@solis.coop.br]
 *
 * @package ui
 * @subpackage controls
 *
 * @since 
 * This class was created 2001/08/14
 *
 * \b Organization: \n
 * SOLIS - Cooperativa de Solucoes Livres
 *
 * \b Copyright: \n 
 *   CopyLeft (L) 2001-2002 UNIVATES, Lajeado/RS - Brasil
 *   Copyleft (L) 2005-present SOLIS, Lajeado/RS - Brasil
 * 
 * @license  
 *   Licensed under GPL (see COPYING.TXT or FSF at www.fsf.org for
 *   further details)
 *
 * @version $id$
 */
class MPrompt extends MControl
{
    /**
     * Information type message
     */
    const MSG_TYPE_INFORMATION  = 'information';
    
    /**
     * Error type message
     */
    const MSG_TYPE_ERROR = 'error';
    
    /**
     * Confirmation type message 
     */
    const MSG_TYPE_CONFIRMATION = 'confirmation';

    /**
     * Question type message 
     */
    const MSG_TYPE_QUESTION = 'question';
    
    /**
     * Prompt type message 
     */
    const MSG_TYPE_PROMPT = 'prompt';

    public $caption;
    public $message;
    public $buttons;
    public $icon;
    public $type = MPrompt::MSG_TYPE_PROMPT;
    public $box;
    
    /**
     * This is the constructor of the class.
     * Use the setType method to specify the type of the dialog.
     * 
     * @see setType
     * 
     * @param (string) $caption Title of the box
     * @param (string) $message Message for the prompt message
     * @param (string) $icon    URL of the image to display on the message
     *
     * @example
     * \code
     *     $dialog = new MPrompt('Information', 'Miolo is a nice framework :-)' );
     * \endcode
     * 
     * @return (void)
     */
    public function __construct($caption = null, $message = null, $icon = '/images/error.gif')
    {
        parent::__construct();
        $this->caption = $caption;
        $this->message = $message;
        $this->icon = $icon;

        if (!$this->caption)
        {
            $this->caption = _M('Alert');
        }

        if (!$this->message)
        {
            $this->message = _M('Unknown reason');
        }
    }

    public static function /* STATIC */ error($msg = '', $goto = '', $caption = '', $event = '')
    {
        if (!$caption)
        {
            $caption = _M('Error');
        }

        $prompt = new MPrompt($caption, $msg);
        $prompt->setType(MPrompt::MSG_TYPE_ERROR);

        if ($goto != 'NONE' && isset($goto))
        {
            $space = '&nbsp;&nbsp;&nbsp;';
            $prompt->addButton( $space._M('Back').$space, $goto, $event);
        }

        return $prompt;
    }

    public static function /* STATIC */ information($msg, $goto = '', $event = '')
    {
        global $MIOLO;

        $prompt = new MPrompt(_M('Information'), $msg, $MIOLO->url_home . '/images/information.gif');
        $prompt->setType(MPrompt::MSG_TYPE_INFORMATION);

        if ($goto != 'NONE' && isset($goto))
        {
            $space = '&nbsp;&nbsp;&nbsp;';
            $prompt->addButton( $space.'OK'.$space, $goto, $event);
        }

        return $prompt;
    }

    public static function /* STATIC */ confirmation($msg, $gotoOK = '', $gotoCancel = '', $eventOk = '', $eventCancel = '')
    {
        global $MIOLO;

        $prompt = new MPrompt(_M('Confirmation'), $msg, $MIOLO->url_home . '/images/attention.gif');
        $prompt->setType(MPrompt::MSG_TYPE_CONFIRMATION);
        
        $space = '&nbsp;&nbsp;&nbsp;';
        
        $prompt->addButton( $space.'OK'.$space, $gotoOK, $eventOk);
        $prompt->addButton( ' ' . _M('Cancel') . ' ', $gotoCancel, $eventCancel);


        return $prompt;
    }

    public static function /* STATIC */ question($msg, $gotoYes = '', $gotoNo = '', $eventYes = '', $eventNo = '')
    {
        global $MIOLO;

        $prompt = new MPrompt(_M('Questão'), $msg, $MIOLO->url_home . '/images/question.gif');
        $prompt->setType(MPrompt::MSG_TYPE_QUESTION);
        
        $space = '&nbsp;&nbsp;&nbsp;';

        $prompt->addButton( $space . _M('Yes') . $space, $gotoYes, $eventYes);
        $prompt->addButton( $space . _M('No') . $space, $gotoNo, $eventNo);

        return $prompt;
    }

    /**
     * Sets the type of the message. Use the MPrompt::MSG_TYPE_??? constants as parameter
     *
     * @param (string) $type 
     */
    public function setType( $type = MPrompt::MSG_TYPE_INFORMATION )
    {
        $this->type = $type;
    }

    /**
     * Adds a button to the prompt dialog.
     *
     * @param (string) $label Button label
     * @param (string) $href  Url address which will be open when the button is clicked  
     * @param (string) $event A event which will be attached to the button
     */
    public function addButton($label, $href, $event = '')
    {
        $this->buttons[] = array ($label, $href, $event);
    }

    public function generateInner()
    {
        $content = '';

        if ( ! is_array($this->message) )
        {
            $this->message = array($this->message);
        }

        $content .= "<ul>\n";

        foreach ($this->message as $m)
        {
            $content .= "<li>$m</li>";
        }

        $content .= "</ul>\n";
        $textBox = new MDiv('', $content, 'm-prompt-box-text');
        $content = '&nbsp;';

        if ($this->buttons)
        {
            $content = "<ul>\n";

            foreach ($this->buttons as $b)
            {
            	if ( is_array( $b ))
            	{
            		
	                $label = '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'.$b[0].'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';

                    if ( strpos($b[1], 'javascript:') === 0 )
                    {
                        $goto  = $b[1];
                    }
                    else
                    {
                        $goto  = 'go:'.$b[1];
                    }
	                
	                $event = $b[2];
	                $name  = $this->name . trim($label);
	
	                if ($goto != '')
	                {
	                    $onclick = $goto . (($event != '') ? "&event=$event" : "");
	                    //$button  = new MImageButton($name, $label, $onclick);
	                    $button  = new MButton($name, $label, $onclick);
	                    $button->setClass('m-button');
	                    $content .= '<li>' . $button->generate() . '</li>';
	                }
	                else
	                {
	                    if ($event != '')
	                    {
	                        $eventTokens = explode(';', $event);
	                        $onclick = "_doPostBack('{$eventTokens[0]}','{$eventTokens[1]}')";
	                    }
	
	                    $button = new MButton($name, $label, $onclick);
	                    $button->setClass('button');
	                    $content .= '<li>' . $button->generate() . '</li>';
	                }
            	}
            	else if ( is_object( $b ) )
            	{
            		$content .= '<li>'.$b->generate().'</li>';
            	}
            }

            $content .= "</ul>\n";
            $buttonBox = new MDiv('', $content, 'm-prompt-box-button');
        }
        else
        {
            $buttonBox = new MSpacer('20px');
        }

        $this->type = strtolower($this->type);
        $this->close = $onclick;
        $this->inner = new MDiv('',array($textBox,$buttonBox),"m-prompt-box-{$this->type}");
	}

	function generate()
    {
        $this->generateInner();
        $this->box = new MBox($this->caption, $this->close, '');
        $this->box->boxTitle->setBoxClass("m-prompt-box-title m-prompt-box-title-{$this->type}");
        $this->box->setControls(array($this->inner));
        
        $id = $this->getUniqueId();
        $prompt = new MDiv("pb$id",new MDiv($id,$this->box,"m-prompt-box-box"),"m-prompt-box");
        
        return $prompt->generate();
    }
}

?>

