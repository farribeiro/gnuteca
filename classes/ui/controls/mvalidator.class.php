<?php
/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MValidator extends MFormControl
{

/**
 * Attribute Description.
 */
    public $field;

/**
 * Attribute Description.
 */
    public $min;

/**
 * Attribute Description.
 */
    public $max;

/**
 * Attribute Description.
 */
    public $type = 'required';  // ex. required | optional | ignore/ readonly

/**
 * Attribute Description.
 */
    public $chars;

/**
 * Attribute Description.
 */
    public $mask;

/**
 * Attribute Description.
 */
    public $checker;

/**
 * Attribute Description.
 */
    public $msgerr;
    public $html; 

    
/**
 * Brief Description.
 * Complete Description.
 *
 * @returns (tipo) desc
 *
 */
    public function __construct()
    {   
        parent::__construct(''); 
        $this->checker = '';
        $this->html = ''; 
        $this->page->addScript('m_validate.js');
    }

/**
 * Brief Description.
 * Complete Description.
 *
 * @returns (tipo) desc
 *
 */
    public static function generateValidators($validators)
    {
        $MIOLO = Miolo::getInstance();
        $formId = $MIOLO->getPage()->getFormId();
        $MIOLO->getPage()->onLoad("miolo.getForm('{$formId}').validators = new Miolo.validate();");
        //$MIOLO->getPage()->onSubmit("miolo.getForm('{$formId}').validators.process()");
        foreach ( $validators as $v )
        {
            $v->generate();
        }
    }

/**
 * Brief Description.
 * Complete Description.
 *
 * @returns (tipo) desc
 *
 */
    public static function ifProcess($command)
    {
        $MIOLO = Miolo::getInstance();
        $formId = $MIOLO->getPage()->getFormId();
        return "if (miolo.getForm('{$formId}').validators.process()) { " . $command . "};";
    }

/**
 * Brief Description.
 * Complete Description.
 *
 * @returns (tipo) desc
 *
 */
    public function generate()
    {
        $v = "{id: '{$this->id}', form: '{$this->form}', field: '{$this->field}', label: '{$this->label}', min: '{$this->min}', max: '{$this->max}', type: '{$this->type}', chars: '{$this->chars}', mask: '{$this->mask}', msgerr: '{$this->msgerr}', {$this->html} checker: '{$this->checker}'}";
//        if ( $this->checker )
//        {
//            $html .= "\n{$name}.checker = 'MIOLO_Validate_Check_{$this->checker}';";
//        }
        $formId = $this->manager->getPage()->getFormId();
        $this->manager->getPage()->onLoad("miolo.getForm('{$formId}').validators.add({$v});");
    }    
}

/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MRequiredValidator extends MValidator
{
/**
 * Brief Description.
 * Complete Description.
 *
 * @param $field (tipo) desc
 * @param $label' (tipo) desc
 * @param $max=0 (tipo) desc
 * @param $msgerr='' (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
	function __construct($field,$label='',$max=0, $msgerr='')
    {
        parent::__construct();
		$this->id  = 'required';
		$this->field  = $field;
		$this->label  = $label;
        $this->mask  = '';
        $this->type  = 'required';
        $this->min   = 0;
        $this->max   = $max;
        $this->chars = 'ALL';
        $this->msgerr = $msgerr;
    }
}

/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MMASKValidator extends MValidator
{
/**
 * Brief Description.
 * Complete Description.
 *
 * @param $field (tipo) desc
 * @param $label' (tipo) desc
 * @param $mask (tipo) desc
 * @param $type (tipo) desc
 * @param = (tipo) desc
 * @param 'ignore' (tipo) desc
 * @param $msgerr='' (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function __construct($field,$label='',$mask,$type = 'ignore',$msgerr='')
    {
        parent::__construct();
		$this->id  = 'mask';
		$this->field  = $field;
		$this->label  = $label;
        $this->mask  = $mask;
        $this->type  = $type;
        $this->min   = 0;
        $this->max   = strlen($mask);
        $this->msgerr = $msgerr;
        $this->chars = 'ALL';
    }
}

/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MEmailValidator extends MValidator
{
/**
 * Brief Description.
 * Complete Description.
 *
 * @param $field (tipo) desc
 * @param $label' (tipo) desc
 * @param $type (tipo) desc
 * @param = (tipo) desc
 * @param 'optional' (tipo) desc
 * @param $msgerr='' (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function __construct($field,$label='',$type = 'optional',$msgerr='')
    {
        parent::__construct();
		$this->id  = 'email';
		$this->field  = $field;
		$this->label  = $label;
        $this->type  = $type;
        $this->min   = 0;
        $this->max   = 99;
        $this->chars = 'ALL';
        $this->mask  = '';
        $this->checker = 'EMAIL';
        $this->msgerr = $msgerr;
    }
}    
    
/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MPasswordValidator extends MValidator
{
/**
 * Brief Description.
 * Complete Description.
 *
 * @param $field (tipo) desc
 * @param $label' (tipo) desc
 * @param $type (tipo) desc
 * @param = (tipo) desc
 * @param 'required' (tipo) desc
 * @param $msgerr='' (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function __construct($field,$label='',$type = 'required',$msgerr='')
    {
        parent::__construct();
		$this->id  = 'password';
		$this->field  = $field;
		$this->label  = $label;
        $this->type  = $type;
        $this->min   = 0;
        $this->max   = 99;
        $this->chars = 'ALL';
        $this->mask  = '';
        $this->checker = 'PASSWORD';
        $this->msgerr = $msgerr;
    }
}    

/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MCEPValidator extends MValidator
{
/**
 * Brief Description.
 * Complete Description.
 *
 * @param $field (tipo) desc
 * @param $label' (tipo) desc
 * @param $type (tipo) desc
 * @param = (tipo) desc
 * @param 'optional' (tipo) desc
 * @param $msgerr='' (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function __construct($field,$label='',$type = 'optional',$msgerr='')
    {
        parent::__construct();
		$this->id  = 'cep';
		$this->field  = $field;
		$this->label  = $label;
        $this->type  = $type;
        $this->min   = 9;
        $this->max   = 9;
        $this->chars = '0123456789-';
        $this->mask  = '99999-999';
        $this->msgerr = $msgerr;
    }
}    
    
/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MPHONEValidator extends MValidator
{
/**
 * Brief Description.
 * Complete Description.
 *
 * @param $field (tipo) desc
 * @param $label' (tipo) desc
 * @param $type (tipo) desc
 * @param = (tipo) desc
 * @param 'optional' (tipo) desc
 * @param $msgerr='' (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function __construct($field,$label='',$type = 'optional',$msgerr='')
    {
        parent::__construct();
		$this->id  = 'phone';
		$this->field  = $field;
		$this->label  = $label;
        $this->type  = $type;
        $this->min   = 8;
        $this->max   = 13;
        $this->chars = '() 01234-56789';
//        $this->mask  = '(99)9999-9999';
        $this->msgerr = $msgerr;
    }
}    
    
/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MTIMEValidator extends MValidator
{
/**
 * Brief Description.
 * Complete Description.
 *
 * @param $field (tipo) desc
 * @param $label' (tipo) desc
 * @param $type (tipo) desc
 * @param = (tipo) desc
 * @param 'optional' (tipo) desc
 * @param $msgerr='' (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function __construct($field,$label='',$type = 'optional',$msgerr='')
    {
        parent::__construct();
		$this->id  = 'time';
		$this->field  = $field;
		$this->label  = $label;
        $this->type    = $type;
        $this->min     = 5;
        $this->max     = 5;
        $this->chars   = ':0123456789';
        $this->mask    = '99:99';
        $this->checker = 'TIME';
        $this->msgerr = $msgerr;
    }
}    
    
/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MCPFValidator extends MValidator
{
/**
 * Brief Description.
 * Complete Description.
 *
 * @param $field (tipo) desc
 * @param $label' (tipo) desc
 * @param $type (tipo) desc
 * @param = (tipo) desc
 * @param 'optional' (tipo) desc
 * @param $msgerr='' (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function __construct($field,$label='',$type = 'optional',$msgerr='')
    {
        parent::__construct();
		$this->id  = 'cpf';
		$this->field  = $field;
		$this->label  = $label;
        $this->type    = $type;
        $this->min     = 14;
        $this->max     = 14;
        $this->chars   = '.-0123456789';
        $this->mask    = '999.999.999-99';
        $this->checker = 'CPF';
        $this->msgerr = $msgerr;
    }
}

/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MCNPJValidator extends MValidator
{
/**
 * Brief Description.
 * Complete Description.
 *
 * @param $field (tipo) desc
 * @param $label' (tipo) desc
 * @param $type (tipo) desc
 * @param = (tipo) desc
 * @param 'optional' (tipo) desc
 * @param $msgerr='' (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function __construct($field,$label='',$type = 'optional',$msgerr='')
    {
        parent::__construct();
		$this->id  = 'cnpj';
		$this->field  = $field;
		$this->label  = $label;
        $this->type    = $type;
        $this->min     = 18;
        $this->max     = 18;
        $this->chars   = '/.-0123456789';
        $this->mask    = '99.999.999/9999-99';
        $this->checker = 'CNPJ';
        $this->msgerr = $msgerr;
    }
}

/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MDATEDMYValidator extends MValidator
{
/**
 * Brief Description.
 * Complete Description.
 *
 * @param $field (tipo) desc
 * @param $label' (tipo) desc
 * @param $type (tipo) desc
 * @param = (tipo) desc
 * @param 'optional' (tipo) desc
 * @param $msgerr='' (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function __construct($field,$label='',$type = 'optional',$msgerr='')
    {
        parent::__construct();
		$this->id  = 'datedmy';
		$this->field  = $field;
		$this->label  = $label;
        $this->type  = $type;
        $this->min   = 10;
        $this->max   = 10;
        $this->chars = '/0123456789';
        $this->mask  = '99/99/9999';
        $this->checker = 'DATEDMY';
        $this->msgerr = $msgerr;
    }
}    
    
/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MDATEYMDValidator extends MValidator
{
/**
 * Brief Description.
 * Complete Description.
 *
 * @param $field (tipo) desc
 * @param $label' (tipo) desc
 * @param $type (tipo) desc
 * @param = (tipo) desc
 * @param 'optional' (tipo) desc
 * @param $msgerr='' (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function __construct($field,$label='',$type = 'optional',$msgerr='')
    {
        parent::__construct();
		$this->id  = 'dateymd';
		$this->field  = $field;
		$this->label  = $label;
        $this->type  = $type;
        $this->min   = 10;
        $this->max   = 10;
        $this->chars = '/0123456789';
        $this->mask  = '9999/99/99';
        $this->checker = 'DATEYMD';
        $this->msgerr = $msgerr;
    }
}

/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MCompareValidator extends MValidator
{
/**
 * Attribute Description.
 */
    public $operator;

/**
 * Attribute Description.
 */
    public $value;

/**
 * Attribute Description.
 */
    public $datatype;  // 'i' (integer) ou 's' (string)


/**
 * Brief Description.
 * Complete Description.
 *
 * @param $field (tipo) desc
 * @param $label' (tipo) desc
 * @param $operator (tipo) desc
 * @param $value (tipo) desc
 * @param $datatype='s' (tipo) desc
 * @param $type (tipo) desc
 * @param = (tipo) desc
 * @param 'optional' (tipo) desc
 * @param $msgerr='' (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function __construct($field,$label='', $operator, $value, $datatype='s',  $type = 'optional',$msgerr='')
    {
        parent::__construct();
		$this->id  = 'compare';
		$this->field  = $field;
		$this->label  = $label;
        $this->type  = $type;
        $this->min   = 0;
        $this->max   = 255;
        $this->chars = 'ALL';
        $this->mask  = '';
        $this->checker = 'COMPARE';
        $this->operator = $operator;
        $this->value = $value;
        $this->datatype = strtolower($datatype);
        $this->msgerr = $msgerr;
    }

/**
 * Brief Description.
 * Complete Description.
 *
 * @returns (tipo) desc
 *
 */
    public function generate()
    {
        $this->html = "operator: '{$this->operator}',  value: '{$this->value}', datatype: '{$this->datatype}',";
        return parent::generate();
    }
}

/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MRangeValidator extends MValidator
{
/**
 * Attribute Description.
 */
    public $minvalue;

/**
 * Attribute Description.
 */
    public $maxvalue;

/**
 * Attribute Description.
 */
    public $datatype;  // 'i' (integer) ou 's' (string) ou 'd' (date)


/**
 * Brief Description.
 * Complete Description.
 *
 * @param $field (tipo) desc
 * @param $label' (tipo) desc
 * @param $min (tipo) desc
 * @param $max (tipo) desc
 * @param $datatype='s' (tipo) desc
 * @param $type (tipo) desc
 * @param = (tipo) desc
 * @param 'optional' (tipo) desc
 * @param $msgerr='' (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function __construct($field,$label='', $min, $max, $datatype='s',  $type = 'optional',$msgerr='')
    {
        parent::__construct();
		$this->id  = 'range';
		$this->field  = $field;
		$this->label  = $label;
        $this->type  = $type;
        $this->min   = 0;
        $this->max   = 255;
        $this->chars = 'ALL';
        $this->mask  = '';
        $this->checker = 'RANGE';
        $this->minvalue = $min;
        $this->maxvalue = $max;
        $this->datatype = strtolower($datatype); // 'i' (integer) ou 's' (string)
        $this->msgerr = $msgerr;
    }

/**
 * Brief Description.
 * Complete Description.
 *
 * @returns (tipo) desc
 *
 */
    public function generate()
    {
        $this->html = "minvalue: '{$this->minvalue}', maxvalue: '{$this->maxvalue}', datatype: '{$this->datatype}',";
        return parent::generate();
    }
}

/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MRegExpValidator extends MValidator
{
/**
 * Attribute Description.
 */
    public $regexp;


/**
 * Brief Description.
 * Complete Description.
 *
 * @param $field (tipo) desc
 * @param $label' (tipo) desc
 * @param $regexp='' (tipo) desc
 * @param $type (tipo) desc
 * @param = (tipo) desc
 * @param 'optional' (tipo) desc
 * @param $msgerr='' (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function __construct($field,$label='', $regexp='',  $type = 'optional',$msgerr='')
    {
        parent::__construct();
		$this->id  = 'regexp';
		$this->field  = $field;
		$this->label  = $label;
        $this->type  = $type;
        $this->min   = 0;
        $this->max   = 255;
        $this->chars = 'ALL';
        $this->mask  = '';
        $this->checker = 'REGEXP';
        $this->regexp = $regexp;
        $this->msgerr = $msgerr;
    }

/**
 * Brief Description.
 * Complete Description.
 *
 * @returns (tipo) desc
 *
 */
    public function generate()
    {
        $this->html = "regexp: '{$this->regexp}',";
        return parent::generate();
    }
}

/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MIntegerValidator extends MRegExpValidator
{
/**
 * Brief Description.
 * Complete Description.
 *
 * @param $field (tipo) desc
 * @param $label' (tipo) desc
 * @param $type (tipo) desc
 * @param = (tipo) desc
 * @param 'optional' (tipo) desc
 * @param $msgerr='' (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function __construct($field,$label='', $type = 'optional',$msgerr='')
    {
        parent::__construct($field,$label, '(^-?[0-9][0-9]*$)', $type,$msgerr);
    }
}

/**
 * Brief Class Description.
 * Complete Class Description.
 */
class mFloatValidator extends MRegExpValidator
{
/**
 * Brief Description.
 * Complete Description.
 *
 * @param $field (tipo) desc
 * @param $label' (tipo) desc
 * @param $type (tipo) desc
 * @param = (tipo) desc
 * @param 'optional' (tipo) desc
 * @param $msgerr='' (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function __construct($field,$label='', $separator='.', $precision=2, $type = 'optional',$msgerr='')
    {
        parent::__construct($field,$label, '^[+-]?[0-9]{1,}(\\'.$separator.'[0-9]{1,'.$precision.'})?$', $type,$msgerr);
        $this->chars = '0123456789+-'.$separator;
    }
}


/**
 * Brief Class Description.
 * Complete Class Description.
 */
class MDATETimeDMYValidator extends MValidator
{
/**
 * Brief Description.
 * Complete Description.
 *
 * @param $field (tipo) desc
 * @param $label' (tipo) desc
 * @param $type (tipo) desc
 * @param = (tipo) desc
 * @param 'optional' (tipo) desc
 * @param $msgerr='' (tipo) desc
 *
 * @returns (tipo) desc
 *
 */
    public function __construct($field,$label='',$type = 'optional',$msgerr='')
    {
        parent::__construct();
		$this->id  = 'datetimedmy';
		$this->field  = $field;
		$this->label  = $label;
        $this->type  = $type;
        $this->min   = 10;
        $this->max   = 16;
        $this->chars = ':/0123456789 ';
        $this->mask  = '99/99/9999 99:99';
        $this->checker = 'DATETimeDMY';
        $this->msgerr = $msgerr;
    }
}

?>
