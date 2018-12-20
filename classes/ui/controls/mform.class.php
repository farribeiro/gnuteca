<?php
define ('FORM_SUBMIT_BTN_NAME', 'submit_button');

/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MForm extends MControl
{
/**
 * Attribute Description.
 */
    public $title;

/**
 * Attribute Description.
 */
    protected $action;

/**
 * Attribute Description.
 */
    public $method;

/**
 * Attribute Description.
 */
    public $buttons;

/**
 * Attribute Description.
 */
    public $fields=array();

/**
 * Attribute Description.
 */
    public $return;

/**
 * Attribute Description.
 */
    public $reset;

/**
 * Attribute Description.
 */
    public $styles;

/**
 * Attribute Description.
 */
    public $help;

/**
 * Attribute Description.
 */
    public $footer;

/**
 * Attribute Description.
 */
    public $width;

/**
 * Attribute Description.
 */
    public $showHints = true;

/**
 * Attribute Description.
 */
    public $enctype;

/**
 * Attribute Description.
 */
    public $validations;

/**
 * Attribute Description.
 */
    public $defaultButton;

/**
 * Attribute Description.
 */
    public $errors;

/**
 * Attribute Description.
 */
    public $infos;

/**
 * Attribute Description.
 */
    public $box;

    static $fieldNum = 0;
/**
 * Attribute Description.
 */
    public $layout;

/**
 * Attribute Description.
 */
    public $cssForm = false;
    public $cssButtons;
/**
 * Attribute Description.
 */
    public $zebra = false;
/**
 * Attribute Description.
 */
    public $labelWidth = NULL;

    public $bgColor = NULL;
    public $align = NULL;
    public $focus = '';
    public $winId;
    public $ajax;

    /**
     * This is the constructor of the Form class. It takes a title and an
     * action url as optional parameters. The action URL is typically
     * obtained by calling the <code>MIOLO->getActionURL()</code> method.
     *
     * @param $title  (string) the form's title string
     * @param $action (string) the URL for the forms <code>ACTION</code>
     *                attribute.
     */
    public function __construct($title='',$action='',$close='',$icon='')
    {
        parent::__construct();
//        $this->addStyleFile('m_forms.css');
//        $this->page->addScript('m_form.js');
//        $this->name = $this->page->name;
        $this->setId('frm' . uniqid());
        $this->box = new MBox($title,$close,$icon);
        $this->title  = $title;
        $this->action = $action;
        $this->method = 'post';
        $this->return = false;
        $this->width  = '95%';
        $this->defaultButton = true;
        $this->fields = array();
        $this->validations = array();
        $this->winId = $this->manager->_request('windowid');
        $this->ajax = $this->manager->ajax;
//		if (($this->isAjaxCall()) && (!$this instanceof MCompoundForm))  return;
        $this->createFields();
//        if ($this->isSubmitted())
        if ($this->page->isPostBack)
        {
            $this->getFormFields(); // set the fields array with form post/get values
        }
        $this->onLoad();
    }


/**
 * Brief Description.
 * Complete Description.
 *
 * @param $name (tipo) desc
 * @param $value (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function __set($name, $value)
    {
        if ($name == 'form') return;
        $this->addControl($value);
        $this->fields[$name] = $value;
    }


/**
 * Brief Description.
 * Complete Description.
 *
 * @param $name (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function __get($name)
    {
        return $this->fields[$name];
    }


/**
 * Brief Description.
 * Complete Description.
 *
 * @returns (tipo) desc
 *
 */
    public function onLoad()
    {
    }


/**
 * Brief Description.
 * Complete Description.
 *
 * @returns (tipo) desc
 *
 */
    public function createFields()
    {
    }

    public function isAjaxCall()
    {
		return ($this->page->request('cpaint_function') != "");
    }

/**
 * Brief Description.
 * Complete Description.
 *
 * @param $validator (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function addValidator($validator)
    {
        $field = $this->{$validator->field};
//        $validator->field = $field->name;
        $name = '_validator_' . $this->name . '_' . $validator->id . '_' . $validator->field;
        $validator->name  = $name;
        $validator->form  = $this->name;
        $validator->label = ($validator->label == '') ? $field->label : $validator->label;
        $validator->max = $validator->max ? $validator->max : $field->size;
        $this->validations[] = $validator;
        return $name;
    }


/**
 * Brief Description.
 * Complete Description.
 *
 * @param $validators (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function setValidators($validators)
    {
       if (is_array($validators))
       {
          foreach($validators as $v)
          {
             $this->addValidator($v);
          }
       }
       elseif (is_subclass_of($this,'validator'))
       {
             $this->addValidator($validators);
       }
    }


    /**
     * Detects if a form has been submitted.
     *
     * @return (boolean) true if the form has been submitted otherwise false
     */
    public function isSubmitted()
    {
        $isSubmitted = $this->defaultButton && MForm::getFormValue(FORM_SUBMIT_BTN_NAME);
        if (isset($this->buttons))
        {
            foreach($this->buttons as $b)
            {
                $isSubmitted = $isSubmitted || MForm::getFormValue($b->name);
            }
        }
        return $isSubmitted;
    }


    /**
     * Obtains the content of this form's title. Observe, that this
     * can be anything other as a simple text string too, such as array of
     * strings and an object implementing the <code>Generate()</code> method.
     *
     * @return (Mixed &) a reference to the title of the form
     */
    public function getTitle()
    {
        return $this->title;
    }


    /**
     * Set the form's title
     *
     * @param (string) $title Form title
     */
    public function setTitle($title)
    {
        $this->title = $title;
        $this->caption = $title;
        $this->box->setCaption($title);
    }

    /**
     * Sets the form's close action
     *
     * @param (string) $action Form action
     */
    public function setClose($action)
    {
        if ($this->box->boxTitle != NULL)
        {
           $this->box->boxTitle->setClose($action);
        }
    }

    /**
     * Sets the form's icon
     *
     * @param (string) $icon Icon URL
     */
    public function setIcon($icon)
    {
        if ($this->box->boxTitle != NULL)
        {
            $this->box->boxTitle->setIcon($icon);
        }
    }

    public function setAlternate($color0, $color1)
    {
        $this->zebra = array($color0, $color1);
    }


    /**
     * Obtains the content title of this form's footer. Observe, that this
     * can be anything other as a simple text string too, such as array of
     * strings and an object implementing the <code>Generate()</code> method.
     *
     * @return (Mixed &) a reference to the footer of the form
     */
    public function getFooter()
    {
        return $this->footer;
    }

    /**
     * Form's footer.
     * Sets the form's footer content.
     *
     * @param $footer (tipo) Footer content
     */
    public function setFooter($footer)
    {
        $this->footer = $footer;
    }

    public function setFocus($fieldName)
    {
        $this->focus = $fieldName;
    }

    /**
     * Obtains a submitted form fields's values and sets the array fields
     * Uses $page->request
     */
    public function getFormFields()
    {
       $this->_GetFormFieldValue($this->fields);
    }


/**
 * Brief Description.
 * Complete Description.
 *
 * @param $field (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function _GetFormFieldValue($field)
    {
        if ( is_array($field) )
        {
            foreach($field as $f)
            {
                $this->_GetFormFieldValue($f);
            }
        }
        else
        {
            if ($field instanceof MFormControl)
            {
                if ( $field->name )
                {
                    $defvalue = $field->getValue();
                    $value = $this->page->request($field->name);
                    if ( ($field instanceof MCheckBox) || ($field instanceof MRadioButton) )
                    {
                       $field->checked = (isset($value) ? ($value == $field->value) : false);
                    }
                    else
                    {
                       $field->setValue(isset($value) ? $value : $defvalue);
                    }
                }
            }
        }
    }

    /**
     * Obtains a submitted form field's value. This is a static function.
     *
     * @param (string) $name
     * @param (string) $value
     * @return (mixed) value of field contained in <code>$HTTP_POST_VARS</code>
     */
    public function getFormValue($name,$value=NULL)
    {
        $result = '';
        if ( ($name != '') && ((strpos($name,'[')) === false))
        {
           $result = $_REQUEST[$name]; //MIOLO::_REQUEST($name, 'ALL', 'PG');
        }

        if (! isset($result))
        {
            $result = $value;
        }
        return $result;
    }


    /**
     * Sets the content of a form field to the specified value. The
     * function does this by setting both, the field's value member and the
     * global <code>$_POST</code> to remain consistency between the values.
     *
     * @param (string) $name
     * @param (string) $value
     */
    public function setFormValue($name,$value)
    {
        $value = MForm::escapeValue($value);
        if (isset($this->$name))
            $this->$name->setValue($value);
        $_REQUEST[$name] = $value;
    }


    /**
     * Used to escapes special characters contained in a form field's value
     * Currently, only simple and double quote characters are subsituted
     * with their corresponding HTML entities.
     *
     * This function is used internally by some of the form's methods.
     *
     * @param (string) $value
     * @return
     */
    private function /* PRIVATE */ EscapeValue($value)
    {
        if ( is_array($value) )
        {
            for ( $i=0, $n = count($value); $i < $n; $i++ )
            {
                $value[$i] = $this->escapeValue($value[$i]);
            }
        }
        else
        {
            $value = str_replace('\"','&quot;',$value);
            $value = str_replace('"','&quot;',$value);
        }
        return $value;
    }


    /**
     * Adds JavaScript code which is to be executed, when the form is submitted.
     * when the form is generated, and any JS code has been registered using
     * this function, an <code>OnSubmit</code> handler is dynamically generated
     * where the code is placed.
     *
     * The generated code looks like the following where stmt stands for the
     * registered statments
     *
     * @param (string) $jscode Javascript code
     */
    public function onSubmit($jscode)
    {
        $this->page->onSubmit($jscode);
    }


/**
 * Brief Description.
 * Complete Description.
 *
 * @param $jscode (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function addJsCode($jscode)
    {
        $this->page->addJsCode($jscode);
    }


    /**
     * Sets the action URL for this form. This is the URL to which the
     * form data will be submitted. Usually, the URL is obtained by the
     * GetActionURL of the MIOLO class.
     *
     * @param (string) $action URL of the action
     */
    public function setAction($action)
    {
        $this->action = $action;
    }


    /**
     * Sets an URL to a help document. This document will be opened via
     * JavaScript in a new window. If this URL is set, the form will display
     * a help button in it's title bar.
     *
     * @param (string) $href URL
     */
    public function setHelp($href)
    {
        $this->help = $href;
    }


    /**
     * Obtain the list of form fields.
     *
     * @deprecated this function will be changed in the near future, so
     * don't use it anymore and keep in touch with the development team
     * to figure out, what will be the replacement.
     *
     * @return (array) the list of form fields
     */
    private function /*PRIVATE*/ GetFields()
    {
        return $this->fields;
    }


    /**
     * This function is used to set an array of fields for the form.
     *
     * @param (array) $fields Fields array
     */
    public function setFields($fields)
    {
//        $this->fields = $fields; // inicializa a lista de campos
//        $this->_RegisterField($this->fields);
        $this->fields = array();
        if (!is_array($fields)) $fields = array($fields);
        $this->layout = $fields;
        $this->_RegisterField($fields);
    }


    /**
     * This function is used internally of the form framework to
     * <i>prepare</i> the form fields for the usage within the form
     * framework.
     *
     * The function basically renames all fields to 'frm_' + name and
     * assigns the value from the global array <code>$HTTP_POST_VARS</code>
     * if the field has no value (null) assigned.
     *
     * @param $field (reference) to a single field or an array of fields
     *               If an array of fields is passed, the function is called
     *               recursively for each of the contained fields.
     *
     * @return (nothing)
     */
    private function /*PRIVATE*/ _RegisterField($field)
    {
        if ( is_array($field) )
        {
            for ( $i=0, $n = count($field); $i < $n; $i++ )
            {
                $this->_RegisterField($field[$i]);
            }
        }
        else
        {
            $field->form = $this;
            $className = $field->className;
            if ($field instanceof MFileField)
            {
                $this->enctype='multipart/form-data';
                $this->page->setEnctype($this->enctype);
            }
            if ($field->name == $field->id)
            {
                $namefield = $field->name;
            }
            else
            {
                $namefield = $field->id;
            }
    	    if ($namefield)
	        {
                $this->manager->assert(!isset($this->$namefield), "Err: property [$namefield] already in use in the form [$this->title]! Choose another name to [$namefield].");
                $this->$namefield = $field;
	        }
            if ($field instanceof MFormControl)
            {
                $value = $this->page->request($field->name);
                if ( ($field instanceof MCheckBox) || ($field instanceof MRadioButton) )
                {
                    // set checked flag of checkbox or radiobutton if the value matches
                    $field->checked = $this->page->isPostBack() ? (isset($value) ? ($value == $field->value) : $field->checked) : $field->checked;
                }
                elseif ( ($field instanceof MIndexedControl) )
                {
                    $this->addFields($field->controls);
                    $field->setValue($value);
                }
                elseif (($field instanceof MInputGrid))
                {
                    $field->setValue($value);
                }
                elseif ( $field->value == '' )
                {
                    $field->setValue($value);
                }
                if ($field instanceof MContainer)
                {
                    $this->_RegisterField($field->getControls());
                }
//                else
//                {
//                    $field->setValue($this->escapeValue($field->value));
//                }
                else
                {
                    $field->setValue($field->value);
                }
            }
            elseif ($field instanceof MDiv)
            {
                $this->_RegisterField($field->getInner());
            }
        }
    }

    /**
     * Adds a single field to the list of form fields and optionally adds
     * a hint text for the field.
     *
     * @param (object) $field Form field object
     * @param (string) $hint Optional hinto for the form field
     */
    public function addField($field,$hint=false)
    {
        if ( $hint )
        {
            $field->setHint($hint);
        }
        $this->_RegisterField($field);
        $this->layout[] = $field;
//        $this->fields[] = $field;
    }


    public function addFields($fields)
    {
        if ( is_array($fields) )
        {
           foreach($fields as $f)
           {
              $this->addField($f);
           }
        }
    }


    /**
     * Add button to the form.
     * This method adds a button to the form. Existing buttons will remaing unchanged.
     *
     * @see setButtons()
     * @see MButton
     *
     * @param (MButton) $btn Button object
     */
    public function addButton(MButton $button)
    {
        if (strtoupper($button->action == 'REPORT'))
        {
           $this->page->hasReport = true;
        }
        $button->form = $this;
        $this->buttons[] = $this->{$button->getId()} = $button;
    }


    /**
     * Sets the form buttons.
     * This method adds buttons to the form, but first removes existing ones.
     *
     * @see addButton()
     *
     * @param (mixed) $buttons MButton object or array of MButtons
     */
    public function setButtons($buttons)
    {
        $this->clearButtons();

        if ( is_array($buttons) )
        {
            for ( $i=0, $n = count($buttons); $i < $n; $i++ )
            {
                $this->addButton($buttons[$i]);
            }
        }
        else
        {
           $this->addButton($buttons);
        }
    }

    /**
     * Set the buttons labels.
     * This function is mainly used, to change the labels of the form's
     * default buttons for submit and return.
     *
     * @param (integer) $index The 0 based index of the button
     * @param (string) $label The new button label
     */
    public function setButtonLabel( $index, $label )
    {
        $this->buttons[$index]->label = $label;
    }

    /**
     * @deprecated This method is deprecated, use setShowReturnButton instead.
     */
    public function showReturn( $state )
    {
        $this->setShowReturnButton( $state );
    }

    /**
     * Return button visibility.
     * Use this function to set the visibility of the form's return button.
     *
     * @param (boolean) $state True to show, false to not show.
     */
    public function setShowReturnButton( $state )
    {
        $this->return = $state;
    }

    /**
     * Post button visibility.
     * Use this method to set the visibility of the Post Button.
     *
     * @param (boolean) $state The visible state of the Post Button
     */
    public function setShowPostButton( $state )
    {
        $this->defaultButton = $state;
    }

    /**
     * @deprecated This method is deprecated, use setShowResetButton instead.
     */
    public function showReset( $state )
    {
        $this->setShowResetButton( $state );
    }

    /**
    * Reset button visibility.
    * This function can be used to show or hide the form's reset button.
    *
    * @param (boolean) $state The visible state of the reset button
    */
    public function setShowResetButton( $state )
    {
        $this->reset = $state;
    }

    /**
     * Form's hints visibility.
     * This function returns the visibility of the form's hint texts.
     *
     * @see ShowHints
     */
    public function getShowHints()
    {
        return $this->showHints;
    }

    /**
     * Set form's hints visibility.
     * This function can be used to show or hide the form's hint texts.
     * Each form element may have a hint text associated with it. Using
     * this method, one can enable/disable the display of the texts. This
     * may be useful for implementing kind of an beginner/expert mode.
     *
     * @param (boolean) $state The visible state of the hint texts
     */
    public function setShowHints( $state )
    {
        $this->showHints = $state;
    }

    /**
     * @deprecated This method is deprecated, use setShowHints instead.
     */
    public function showHints( $state )
    {
        $this->setShowHints ( $state );
    }


    /**
     * Returns form fields list.
     * This is a placeholder function to bu the form's field list. It
     * is excpected, that the form returns a scalar list of all defined
     * fields which carry a form field value. Thus, form elements of
     * decorative purpose only should be omitted.
     * <br><br>
     * Derived classes such as <code>TabbedForm</code> override this
     * function to provide the list of fields independently of the form's
     * layout.
     *
     * @returns (array) a scalar array of form fields
     */
    public function getFieldList()
    {
        return $this->_GetFieldList($this->fields);
    }

    /**
     * Returns field list.
     * Internal function which takes a list of form elements possibly
     * consisting of single fields as well as arrays and returns a scalar
     * the list of fields filtering out some known decorative form fields.
     *
     * @param  (array) $allfields An array of form fields
     * @return (array) A scalar array of form fields
     */
    private function _getFieldList($allfields)
    {
        $fields = array();
        foreach ($allfields as $f )
        {
            if ( is_array($f) )
            {
                foreach ( $f as $a )
                {
                    if (is_a($a,'MBaseLabel')) continue;
                    $fields[] = $a;
                }
            }
            else
            {
                if ( is_a($f,'MBaseLabel') || is_null($f->value) ) continue;
                $fields[] = $f;
            }
        }
        return $fields;
    }

    public function clearFields()
    {
        $this->fields = NULL;
        $this->layout = NULL;
    }

    public function clearField($name)
    {
        $f = $this->fields[$name];
        $f->_addStyle('display','none');
    }


    /**
     * Remove existing buttons on the form.
     */
    public function clearButtons()
    {
        $this->buttons = NULL;
        $this->defaultButton = false;
    }

    /**
     * Validate all form fields.
     * Validates all form fields to have a non-empty content
     *
     * @param (boolean) $assert Flag how to handle invalid fields;
     *                  if TRUE, an error message will be shown
     *                  if FALSE no error message will be shown and the
     *                  caller can provide an appropriate action based on the
     *                  return value.
     * @returns (boolean) TRUE if all fields have a value;
     *                    FALSE if any of the fields has been left empty
     */
    public function validateAll( $assert=true )
    {
        foreach ( $this->getFieldList() as $f )
        {
            if ( $f->name )
            {
                $required[] = $f->name;
            }
        }
        return $this->validate($required, $assert);
    }

    /**
     * Validates required fields
     *
     * @param (tipo) $assert
     * @return (boolean)
     */
    public function validateRequiredFields( $assert=true )
    {
        foreach ( $this->getFieldList() as $f )
        {
            if ( $f->required )
            {
                $required[] = $f->name;
            }
        }
        return $this->validate( $required, $assert );
    }

    /**
     * Validates the form input
     * Validate form data based on an array of required variable names.
     *
     * @param (array) $required Fields to be validated
     * @param (boolean) $assert Should the program stop if a error is found?
     *
     * @return (boolean) TRUE if all fields have a value;
     *                   FALSE if any of the fields has been left empty
     */
    public function validate( $required, $assert=true )
    {   global $MIOLO,$HTTP_POST_VARS;

        $this->errors = array();
        // collect fields by label
        foreach ( $this->getFieldList() as $f )
        {
            $fields[$f->name] = $f->name;
        }
        foreach ( $required as $r )
        {
            $name  = $r;
            $label = $fields[$name];
            $MIOLO->assert( $label,
                            "ERROR: Required field [<b><font color=red>$name</font></b>] is not defined in form!" );

            $value = $this->getFormValue( $name );
            if ( $value === '' || (is_null($value)) )
            {
                $this->errors[] = "<b>$label</b> " . _M("was not informed!");
            }
        }
        if ( $assert && count($this->errors) )
        {
            $theme =& $MIOLO->getTheme();
            $theme->setContent( $this );
            $theme->generate();
        }
        return count( $this->errors ) == 0;
    }

    /**
     * Regiter the error
     * Registers the error related to the form
     *
     * @param $err (tipo) desc
     * @return (tipo) desc
     */
    public function error( $err )
    {   global $MIOLO;

        $MIOLO->logMessage('[DEPRECATED] Call method Form::error() is deprecated -- use Form::addError() instead!');
        $this->addError( $err );
    }

    /**
     * Adds the related form error
     *
     * @param (mixed) $err Error message string or array of messages
     */
    public function addError($err)
    {
        if ( $err )
        {
            if ( is_array($err) )
            {
                if ( $this->errors )
                {
                    $this->errors = array_merge($this->errors,$err);
                }

                else
                {
                    $this->errors = $err;
                }
            }
            else
            {
                $this->errors[] = $err;
            }
        }
    }


    /**
     *  Returns the number of error messages or 0 if no errors exist
     *
     * @return (integer) Error count
     */
    public function hasErrors()
    {
        return count($this->errors);
    }


    /**
     * Register an information related to the form
     *
     * @param (mixed) $info Information message string or array of messages
     */
    public function addInfo($info)
    {
        if ( $info )
        {
            if ( is_array($info) )
            {
                if ( $this->infos )
                {
                    $this->infos = array_merge($this->infos,$info);
                }

                else
                {
                    $this->infos = $info;
                }
            }
            else
            {
                $this->infos[] = $info;
            }
        }
    }


    /**
     * Returns the number of info messages or 0, if no info exist
     *
     * @return (integer) Information messages count
     */
    public function hasInfos()
    {
        return count($this->infos);
    }


    /**
     * Get form data and put it into the classmembers
     */
    public function collectInput($data)
    {
        foreach ( $this->getFieldList() as $f )
        {
            $field = $f->name;
            if ( $field != '' )
            {
                  $value = $this->getFormValue($field);
                  $data->$field = $value;
            }
        }
        return $data;
    }

    /**
     * Obtains form fields in a FormData object.
     *
     * @return (Object) Form fields
     */
    public function getData()
    {
        return $this->collectInput( new FormData() );
    }

    /**
     * Set data on the form fields.
     * Set form fields values. A subclassed form will likely override this
     * method, in order to provide a specialized processing for the passed
     * data object. <br><br>
     * This method simply calls the <code>_setData()</code> method of the
     * <code>Form</code> class.
     * @example
     * $data = new FormData();
     * $form->setData( $data );
     *
     * @param $data (MBusiness Object) object containing the field values
     */
    public function setData( MBusiness $data)
    {
        $this->_setData($data);
    }


    /**
     * This method sets the form field values in way, that it iterates
     * thru the list of fields and sets the values of all fields matching
     * the data object attribute names.
     *
     * In short it does the following<br>
     * @example
     * <code>$frm_name = $data->name;</code>
     *
     * This implies that the form field names must be identical the data
     * member names.
     *
	 * @param $data (array) Data to be assigned to formfields
 	 *
 	 * @return (void)
 	 */
    private function _setData($data)
    {
        foreach ( $this->fields as $field=>$name)
        {
            $name = $this->fields[$field]->name;
            if ( $name )
            {
                if ( ($this->fields[$field] instanceof MRadioButton) ||
                     ($this->fields[$field] instanceof MCheckBox) )
                {
                    $this->fields[$field]->checked = ( $data->$name == $this->fields[$field]->value );
                }
                else
                {
                    $value = $data->$name;

                    if ( ($this->fields[$field] instanceof MFormControl) &&
                         (isset($value)) )
                    {
                        $this->fields[$field]->setValue($value);
                        $_POST[$name] = $value;
                    }
                }
            }
        }
    }


    /**
     * Obtains a form field's value
     */
    public function getFieldValue($name,$value=false)
    {
        $field = $this->fields[$name];
        return ($field ? $field->getValue() : NULL);
    }


    /**
     * Set a form field's value
     */
    public function setFieldValue($name,$value)
    {
        $field = $this->fields[$name];
        $field->setValue($value);
    }


    /**
     * Set a form field's validator
     */
    public function setFieldValidator($name,$value)
    {
        for ( $i=0, $n = count($field); $i < $n; $i++ )
        {
            if ( $name == $this->fields[$i]->name )
            {
                $this->fields[$i]->validator = $value;
                break;
            }
        }
    }


    /**
     * Get a reference for a form field
     */
    public function & GetField($name)
    {
        return $this->fields[$name];
    }


    /**
     * Get a reference for a button
     */
    public function & GetButton($name)
    {
        for ( $i=0, $n = count($this->buttons); $i < $n; $i++ )
        {
            if ( $name == $this->buttons[$i]->name )
            {
                return $this->buttons[$i];
            }
        }
    }


    /**
     * Get a reference for page
     */
    public function & GetPage()
    {
        return $this->page;
    }


    /**
     * Set reference for page
     */
    public function setPage($page)
    {
        $this->page = $page;
    }


    /**
     * Set a form field's attribute a value
     */
    public function setFieldAttr($name,$attr,$value)
    {
//      $field = $this->$name;
//      $field->$attr = $value;
        $this->fields[$name]->$attr = $value;
    }


    /**
     * Get a form field's attribute value
     */
    public function getFieldAttr($name,$attr, $index=NULL)
    {
        $field = $this->fields[$name];
        if ( is_array($field->$attr) )
        {
            $a = $field->$attr;
            $value = $a[$index];
        }
        else
        {
          $value = $field->$attr;
        }
        return $value;
    }


    /**
     * Set a form field's attribute a value
     */
    public function setButtonAttr($name,$attr,$value)
    {
        $button = &$this->getButton($name);
        $button->$attr = $value;
    }


    /**
     * Set CSS for the field.
     *
     * @param (string) $name
     * @param (integer) $top
     * @param (integer) $left
     * @param (integer) $width
     * @param (string) $position
     */
    public function setFieldCSS($name,$top,$left,$width=NULL, $position='absolute')
    {
        $field = $this->$name;
//        $top = $this->box->top + $top;
//        $left = $this->box->left + $left;
        if ($width)
        {
            $field->width = "{$width}px";
        }

        $field->top = "{$top}px";
        $field->left = "{$left}px";

        if ($position)
        {
            $field->position = $position;
        }

        $field->formMode = 2;
    }

    /**
     * Set form CSS
     *
     * @param (integer) $height
     * @param (integer) $width
     * @param (integer) $top
     * @param (integer) $left
     * @param (integer) $buttons
     * @param (string) $position
     */
    public function setFormCSS($height=0, $width=0, $top=0, $left=0, $buttons=0, $position='absolute')
    {
        if ($height)
        {
            $this->box->addStyle('height',"{$height}px");
        }

        if ($width)
        {
            $this->box->addStyle('width',"{$width}px");
        }

        if ($top)
        {
            $this->box->addStyle('top',"{$top}px");
        }

        if ($left)
        {
            $this->box->addStyle('left',"{$left}px");
        }

        if ($position)
        {
            $this->box->addStyle('position',$position);
        }

        $this->cssButtons = "{$buttons}px";
        $this->cssForm = true;
    }

    public function setBackgroundColor($bgcolor)
    {
        $this->bgColor = $bgcolor;
    }

    public function setAlign($value)
    {
        $this->align = $value;
    }

    public function setWidth($width=NULL)
    {
        if ($width) $this->box->addStyle('width',"{$width}");
    }

    public function setHeight($height=NULL)
    {
        if ($height) $this->box->addStyle('height',"{$height}");
    }

    public function setResponse($controls,$element='')
    {
        $this->addJsCode("deleteAjaxLoading()");
        if ($element == '')
        {
            $element = $this->manager->_request('__FORMSUBMIT') . '_content';
        }
        $this->manager->ajax->setResponseControls($controls,$element);
    }

    public function getCloseWindow()
    {
        return "javascript:window.parent.Windows.close('{$this->manager->_request('windowid')}');";
    }

   /**
    * Renderize
    *
    * @param (integer) $width
    */
   public function setLabelWidth($width)
   {
        if ( (strpos($width, '%') === false) && (strpos($width, 'px') === false) )
        {
            $width = "{$value}%";
        }
        $this->labelWidth = $width;
   }

   public function submit_button()
   {
        $this->setResponse(new stdClass,'');
   }

/**
 * Brief Description.
 * Complete Description.
 *
 * @returns (tipo) desc
 *
 */
   public function generateErrors()
   {
        $prompt = MPrompt::error($this->errors,'NONE','Erros');
        return $prompt;
   }


/**
 * Brief Description.
 * Complete Description.
 *
 * @returns (tipo) desc
 *
 */
   public function generateInfos()
   {
        $prompt = MPrompt::information($this->infos,'NONE','Informações');
        return $prompt;
   }


/**
 * Brief Description.
 * Complete Description.
 *
 * @returns (tipo) desc
 *
 */
   public function generateBody()
   {
        global $MIOLO;

        $row = 0;
        $t = array();
        // optionally generate errors
        if ( $this->hasErrors() )
        {
            $t[] = $this->generateErrors();
        }
        if ( $this->hasInfos() )
        {
            $t[] = $this->generateInfos();
        }
        $hidden = null;
        $t = array_merge($t, $this->generateLayoutFields($hidden));

        if( method_exists($this->page,'getLayout') )
        {
            $layout = $this->page->theme->getLayout();
        }
        else
        {
            $layout = $this->manager->theme->getLayout();
        }

        if ( $layout != 'print')
        {
           $buttons = $this->generateButtons();
           if ($buttons)
           {
              $t = array_merge($t,array($buttons));
           }
        }
        if ($this->action == '')
        {
           $this->action = $this->page->action;
        }
        $hidden[] = new MHiddenField($this->getId() . '_action',$this->action);
        if ( $hidden )
        {
           $t = array_merge($t,$this->generateHiddenFields($hidden));
        }
        $t = array_merge($t,$this->generateScript());
        $body = new MDiv('divFormX',$t);
        return $body;
   }


/**
 * Brief Description.
 * Complete Description.
 *
 * @returns (tipo) desc
 *
 */
   public function generateFooter()
   {
   }


/**
 * Brief Description.
 * Complete Description.
 *
 * @param &$hidden (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
   public function generateLayoutFields(&$hidden)
   {
       $line = 0;
       $zebra = is_array($this->zebra);
       $t = array();
       if (is_array($this->layout))
       {
           foreach ( $this->layout as $f )
           {
               if ( $f->validator != NULL)
               {
                    if ($f->validator instanceof MValidator)
                    {
                        $this->addValidator($f->validator);
                    }
               }
               else
               {
                    foreach($this->validations as $validator)
                    {
                        if($validator->field == $f->name)
                        {
                            $f->validator = $validator;
                        }
                    }
               }
               $row = $t[] = $this->generateLayoutField($f, $hidden);
               if ($zebra)
               {
                   $row->addStyle('backgroundColor', $this->zebra[($line++) % 2]);
               }
           }
       }
       return $t;
   }

    public function getFieldValidator($name)
    {
        foreach($this->validations as $validator)
        {
            if( $validator && $validator->field == $name )
            {
                return $validator;
            }
        }
        return false;
    }

/**
 * Brief Description.
 * Complete Description.
 *
 * @param $f (tipo) desc
 * @param &$hidden (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
   public function generateLayoutField($f, &$hidden)
   {
       if ( is_array($f) )
       {
          $c = array();
          foreach($f as $fld)
          {
             if ($fld->visible) $c[] = $fld;
          }
          $f = new MHContainer('',$c);
          $f->showLabel = true;
       }
       if ( ! $f->visible ) return;
       $rowContent = NULL;
       $label = $f->label;
       if ( ( ( ($f->className == 'textfield') || ($f->className == 'mtextfield'))  && ($f->size==0) ) || ($f instanceof  MHiddenField) )
       {
          $hidden[] = $f;
          return;
       }
       if ( ( $f->readonly || $f->maintainstate) )
       {
          $hidden[] = $f;
       }
       if ( $f->cssp )
       {
          return $f;
       }

       if (($f->formMode != MControl::FORM_MODE_SHOW_SIDE) ||
          (($f->formMode == MControl::FORM_MODE_SHOW_SIDE) && (! $label)))
       {
          $rowContent = $f;
       }
       else
       {
          if ( $label != '' && $label != '&nbsp;' )
          {
              $label .= ':';
          }
          $tf = array();
          if ($label != '')
          {
             if ($f->id != '')
             {
                $lbl = new MFieldLabel($f->id,$label);

                if($f->validator && $f->validator->type == 'required')
                {
                    $lbl->setClass('m-caption-required');
                }
                else
                {
                    $lbl->setClass('m-caption');
                }
             }
             else
             {
                $lbl = new MSpan('',$label,'m-caption');
             }
             $slbl = $rowContent[] = new MSpan('',$lbl,'label');
             if ($this->labelWidth != NULL)
             {
                 $slbl->_AddStyle('width',$this->labelWidth);
             }
          }
          $afld = $f;
          if ( $this->showHints && $f->hint )
          {
             $hint = new MSpan('',$f->hint,'m-hint');
             $afld = array($f,'&nbsp;',$hint);
          }
          $sfld = new MSpan('',$afld,'field');
          $rowContent[] = $sfld;
          if ($this->labelWidth != NULL)
          {
             $sfld->_AddStyle('width', (95 - $this->labelWidth).'%');
          }
       }
       return new MDiv('',$rowContent, "m-form-row");
    }


/**
 * Brief Description.
 * Complete Description.
 *
 * @returns (tipo) desc
 *
 */
    public function generateButtons()
    {
           $ul = new MUnorderedList();
           if (isset($this->buttons) )
           {
              $ul->addOption(new MHr);
              foreach ( $this->buttons as $b )
              {
                 if ($b->visible) $ul->addOption($b);
              }
           }
           if ( $this->reset )
           {
              $ul->addOption(new MButton('_reset','Limpar','RESET'));
           }
           if ( $this->return )
           {
              $ul->addOption(new MButton('_return','Voltar','RETURN'));
           }
           $d = (count($ul->options) ? new MDiv('',$ul,'m-form-button-box') : NULL);
           return ($d ? new MDiv('',$d,'m-form-row') : NULL);
    }


/**
 * Brief Description.
 * Complete Description.
 *
 * @param $hidden (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function generateHiddenFields($hidden)
    {
        $f[] = "\n<!-- START OF HIDDEN FIELDS -->";
        foreach ( $hidden as $h )
        {
            $f[] = new MHiddenField($h->name,$h->value);
        }
        $f[] = "\n<!-- END OF HIDDEN FIELDS -->";
        return $f;
    }


    /**
     * Generate form specific script code
     */
    public function generateScript()
    {
//        $this->page->onLoad("form_{$this->name} = new Miolo.form('{$this->name}');");
        if ($this->focus != '')
        {
//             $this->page->onLoad("form_{$this->name}.setFocus('{$this->focus}');");
        }
        $f = array();
        if ( $this->validations )
        {
            MValidator::generateValidators($this->validations);
        }
        return $f;
    }

    public function generate()
    {
        if (!isset($this->buttons))
        {
            if ($this->defaultButton)
            {
                $this->buttons[] = new MButton(FORM_SUBMIT_BTN_NAME, 'Enviar', 'SUBMIT');
            }
        }
        $footer = $this->generateFooter();
        if ($this->cssForm)
        {
            $body = $this->generateBody();
            $this->box->setControls(array($body));
            $this->box->setBoxClass('m-form-css');
            return $this->box->generate();
        }
        else
        {
            $body = new MDiv('',$this->generateBody(),'m-form-body');
            if (!is_null($this->bgColor)) $body->addStyle('backgroundColor',$this->bgColor);
            $this->box->setControls(array($body, $footer));
            $id = $this->getId();
            $this->box->setBoxClass("m-form-outer");
            $form = new MDiv($id, $this->box,"m-form-box");
            if (!is_null($this->align)) $form->addBoxStyle('text-align',$this->align);
            return $form->generate();
//            return $this->box->generate();
        }
    }

    public function __toString()
    {
        return '';
    }
}

class FormData
{
}

?>
