<?

class MLookupField extends MTextField
{
    public $action;
    public $info;
    public $lookup_name;
    public $showButton=true;
    public $lookupType;
    // context
    public  $baseModule;
    public  $module;
    public  $item;
    public  $event;
    public  $filter;
    public  $related;
    public  $autocomplete = true;
    public  $title;
    // window
    public $windowType   = 'popup';
    public $windowWidth  = '';
    public $windowHeight = '';
    public $windowTop    = '';
    public $windowLeft   = '';


    public function __construct($name='',   $value='',  $label='',  $hint='',
                                $related='',$module='', $item='',   $event='filler', $filter='',$title='')
    {
        parent::__construct($name,$value,$label,0,$hint);
        $this->page->addScript('m_window.js');
        $this->page->addDojoRequire("miolo.Dialog");
        $this->page->addScript('m_lookup.js');

        if (is_array($related))
        {
            ksort($related);
        }
        else
        {
            $related = array(str_replace(' ','',$related));
        }

        $baseModule = MUtil::NVL($this->manager->GetConf("mad.module"), "admin");
        $event      = MUtil::NVL($event, 'filler');

        $this->setContext($baseModule,$module,$item,$event,$related,$filter,true,$title);

        $this->lookup_name = "lookup_{$this->formId}_{$this->name}";
    }

    public function setContext($baseModule='admin',$module='admin',$item='',$event='',$related='',$filter='',$autocomplete=true ,$title='')
    {
        $this->baseModule   = $baseModule;
        $this->module       = $module;
        $this->item         = $item;
        $this->event        = $event;
        $this->related      = $related;
        $this->filter       = MUtil::NVL($filter, $this->filter);
        $this->autocomplete = $autocomplete;
        $this->title        = $title;
    }

    public function getModuleItem()
    {
        return $this->module . '.' . $this->item;
    }

    public function setTitle($title='')
    {
        $this->title = $title;
    }

    public function setAutoComplete($autocomplete=true)
    {
        $this->autocomplete = $autocomplete;
    }

    public function setModuleItem($module, $item)
    {
        $this->module = $module;
        $this->item = $item;
    }

    public function setWindowSize( $width, $height )
    {
        $this->windowWidth  = $width;
        $this->windowHeight = $height;
    }

    public function setWindowType( $windowType='iframe', $width='', $height='', $top='', $left='')
    {
        $this->windowType   = $windowType;
        $this->windowTop    = $top;
        $this->windowLeft   = $left;
        $this->setWindowSize( $width, $height);
    }

    public function setShowButton( $show=true )
    {
        $this->showButton = $show;
    }

   public function generateInner()
   {
        $this->label = $this->label ? '&nbsp;' : '';

        $this->filter   = $this->filter             ? $this->filter : $this->name;
        $filter         = is_array($this->filter)   ? $this->filter : array($this->filter);

        $this->lookup_name = "lookup_{$this->formId}_{$this->name}";
        $lookup_name = $this->lookup_name;


        $attr = $this->getAttributes();

        if ($this->showButton )
        {
            $button = new MButtonFind("javascript:addAjaxLoading();{$this->lookup_name}.start();", "findButton_{$this->lookup_name}");
            $content[] = $button->generate();
        }

        $html =  $this->painter->generateToString($content);

        $aFilter    = implode(',',$filter);
        $akFilter   = implode(',',array_keys($filter));

        $jsCode     =
<<< HERE
        {$this->lookup_name}.setContext({
             baseModule : '{$this->baseModule}',
             name       : '{$lookup_name}',
             module     : '{$this->module}',
             item       : '{$this->item}',
             related    : '{$this->related}',
             filter     : '{$aFilter}',
             idxFilter  : '{$akFilter}',
             form       : '{$this->formId}',
             field      : '{$this->name}',
             event      : '{$this->event}',
             title      : '{$this->title}',
             autocomplete : '{$this->autocomplete}',
             wType      : '{$this->windowType}',
             wWidth     : '{$this->windowWidth}',
             wHeight    : '{$this->windowHeight}',
             wTop       : '{$this->windowTop}',
             wLeft      : '{$this->windowLeft}',
             autoPost   : '{$this->autoPostBack}'
        });
HERE;


        $this->page->addJsCode("{$this->lookup_name} = new Miolo.Lookup();");
        $this->page->addJsCode($jsCode);

        $this->inner = new MDiv('',$this->generateLabel() . $html, '');
   }
}


class MLookupTextField extends MLookupField
{
    public  $autocomplete,
            $fieldLabel;


    public function __construct($name='',   $value='',  $label='',
                                $size=10,   $hint='',   $validator=null,    $related='',
                                $module='', $item='',   $event='filler',    $filter='',     $autocomplete=true )
    {
        parent::__construct($name,$value,$label,$hint,$related, $module, $item, $event, $filter); //$validator);

        $this->size         = $size;
        $this->filter       = $filter ? $filter : $this->name;
        $this->fieldLabel   = $label;
        $this->autocomplete = $autocomplete ? true : false;
        $this->validator    = is_string($validator) ? MValidator::MASKValidator($validator) : $validator;
        $this->showLabel    = false;
    }

    public function getAutocompleteData()
    {
        $autocomplete = new MAutoComplete($this->module,$this->item,$this->value,$this->related);
        $info = $autocomplete->getResult();
        return $info;
    }

   public function generateInner()
   {
        parent::generateInner();

        $field = new MTextField($this->name,$this->value,$this->fieldLabel,$this->size,$this->hint, $this->validator);
        $field->attrs = $this->attrs;
        if ( $this->autocomplete )
        {
            $field->addAttribute('onchange',"{$this->lookup_name}.start(true);");
            $this->page->onLoad("if (miolo.getElementById('{$this->name}').value) { {$this->lookup_name}.start(true); }");
        }
        $field->validator = $this->validator;
        $field->form      = $this->form;

        $field->setClass('m-text-field');
        $field->showLabel = $this->showLabel;
        $field->formMode = $this->formMode;
        $field->setReadOnly( $this->readonly );
        $field->addAttribute('lookUpField', "lookUpField");
        $field->addAttribute('lookUpName',  "{$this->lookup_name}");


//      $html = $field->generate();
        $div = new MDiv('', $field );

        $lookupField = $this->getInner();
        $c = new MHContainer('', array($field, ( $this->readonly  ? '' : $lookupField)));
        $c->setClass('mLookupField');
        $c->setShowChildLabel( false, true );

        if ( $this->getAttribute('readonly') )
        {
            $field->setClass('mLookupField m-readonly');
        }

        $this->inner = $c;
   }

}

class MLookupFieldValue extends MLookupField
{
	function __construct($name='',$value='',$label='',
                 $size=10,$hint='',$validator=null,$related='',
	             $module='',$item='', $event='', $filter='', $autocomplete=true)
    {
        parent::__construct($name,$value,$label,$hint,$validator);
        $this->size = $size;
        $this->filter = $this->name;
        $this->validator = is_string($validator) ? MValidator::MASKValidator($validator) : $validator;
    }

   public function generateInner()
   {
      parent::generateInner();
      $htmlInner = $this->getInner();
      $field = new MTextField($this->name,$this->value,$this->label,$this->size,$this->hint, $this->validator);
      $field->setClass('m-text-field');
      $field->showLabel = $this->showLabel;
      $field->formMode = $this->formMode;
//      $field->addBoxStyle('float','left');
      $field->setClass('m-readonly');
      $field->addAttribute('readonly');
      $html = $field->generate();
      $this->inner = ( $this->readonly  ? '' : $htmlInner) . $html;
   }

}

class MDialogLookup extends MLookupTextField
{

}

?>
