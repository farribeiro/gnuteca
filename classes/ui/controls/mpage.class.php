<?php
define ('PAGE_ISPOSTBACK', '__ISPOSTBACK');

class MPage extends MControl
{
    public $compliant;
    public $styles;
    public $styleCode;
    public $scripts;
    public $customScripts;
    public $metas;
    public $title;
	var $action;
	var $enctype;
    public $isPostBack = false;
	var $onload;
	var $onsubmit;
	var $onunload;
	var $onfocus;
    public $onerror;
    public $hasReport;
	var $state;
    public $jscode;
    public $goto;
    public $generateMethod = 'generateDefault';
    public $theme;
    public $ajax;
    public $redirect = false;
	var $file; // object to use with downloads
    public $dojoRequire;
    public $form;
    public $formid;
    public $winid;
    public $domwinid;
    public $stdout;

    public function __construct()
    {   global $state;

        parent::__construct('page' . uniqid());
        $this->compliant  = true;
		$this->enctype    = '';
      	$this->onsubmit   = new MStringList();
      	$this->onload     = new MStringList(false);
        $this->onload->add("deleteAjaxLoading();");
      	$this->onerror    = new MStringList(false);
        $this->onunload   = new MStringList();
        $this->onfocus    = new MStringList();
      	$this->jscode     = new MStringList();
      	$this->styles     = new MStringList(false);
      	$this->styleCode  = new MStringList();
      	$this->scripts    = new MStringList(false);
      	$this->dojoRequire = new MStringList(false);
      	$this->customScripts    = new MStringList(false);
      	$this->metas      = new MStringList();
        $this->title      = $this->manager->getConf('theme.title');
//		$this->action     = $this->manager->history->pop('context');
		$this->action     = $this->manager->getCurrentURL();
        $this->isPostBack = (MIOLO::_REQUEST($this->manager->formSubmit.'__ISPOSTBACK') != '');
        $back = $this->manager->history->back('context');
        $top = $this->manager->history->top('context');
//        $this->isPostBack = ($back === $top) && (MIOLO::_REQUEST(PAGE_ISPOSTBACK) != '');
        $this->ajax = $this->manager->ajax;
        $this->winid = $this->manager->_request('__WINID');
        $this->domwinid = $this->manager->_request('__DOMWINID');
        $this->formid = ($this->winid != '') ? 'frm' . $this->winid : 'frm__mainForm';
        $state            = new MState($this->formid);
        $this->state      = $state;
        $this->loadViewState();
        $this->loadPostData();
        if ( $this->manager->getIsAjaxCall() )
        {
            $this->generateMethod = 'generateAJAX';
        }
$this->manager->trace(print_r($_REQUEST,true));
	}

    public function addStyle($url)
    {
        $url = $this->manager->getThemeURL($url);
        $this->styles->add($url);
    }

    public function addStyleURL($url)
    {
        $this->styles->add($url);
    }

    public function addStyleCode($code)
    {
      $this->styleCode->add($code);
    }

    public function addScript($url, $module=null)
    {
        if ( $module )
        {
            $url = $this->manager->getActionURL( $module, 'scripts:' . $url);
        }
        else
        {
            $url = $this->manager->getAbsoluteURL('scripts/' . $url);
        }
        $this->scripts->add($url);
    }

    public function addScriptURL($url)
    {
//        $this->customScripts->add($url);
        $this->scripts->add($url);
    }

    public function insertScript($url)
    {
        $url = $this->manager->getAbsoluteURL('scripts/' . $url);
        $this->scripts->insert($url);
    }

    public function addDojoRequire($dojoModule)
    {
        $this->jscode->insert("dojo.require(\"{$dojoModule}\");");
    }

    public function addMeta($name,$content)
    {
      $this->metas->add("<meta name=\"$name\" content=\"$content\">");
    }

    public function addHttpEquiv($name,$content)
    {
      $this->metas->add("<meta http-equiv=\"$name\" content=\"$content\">");
    }

    public function getStyles()
    {
        return $this->styles;
    }

    public function getStyleCode()
    {
        return $this->styleCode;
    }

    public function setStyles($value)
    {
        $this->styles->items = is_array($value) ? $value : array($this->manager->getThemeURL($value));
    }

    public function getScripts()
    {
        return $this->scripts;
    }

    public function getCustomScripts()
    {
        return $this->customScripts;
    }

    public function getMetas()
    {
        return $this->metas;
    }

    public function getOnLoad()
    {
        return $this->onload;
    }

    public function getOnError()
    {
        return $this->onerror;
    }

    public function getOnSubmit()
    {
        return $this->onsubmit;
    }

    public function getOnUnLoad()
    {
      return $this->onunload;
    }

    public function getOnFocus()
    {
      return $this->onfocus;
    }

    public function getJsCode()
    {
        return $this->jscode;
    }

    public function getFormId()
    {
        return $this->formid;
    }

    public function getTitle()
    {
        return $this->title;
    }

    public function setTitle($title)
    {
        $this->title = $title;
    }

    public function onSubmit($jscode)
    {
      $this->onsubmit->add($jscode);
    }

    public function onLoad($jscode)
    {
      $this->onload->add($jscode);
    }

    public function onUnLoad($jscode)
    {
      $this->onunload->add($jscode);
    }

    public function onError($jscode)
    {
        $this->onerror->add($jscode);
    }

    public function onFocus($jscode)
    {
      $this->onfocus->add($jscode);
    }

    public function addJsCode($jscode)
    {
      $this->jscode->add($jscode);
    }

    public function isPostBack()
    {
		return $this->isPostBack;
    }

    public function setPostBack($postback)
    {
        $this->isPostBack = $postback;
    }

    /* Used at main form */
	function setAction($action)
	{
		$this->action = $action;
	}

    /* Used at main form */
	function setEnctype($enctype)
	{
		$this->enctype = $enctype;
	}

	function setCompliant($value=true)
	{
		$this->compliant = $value;
	}

	function setFile($name,$content,$type,$length)
	{
        $this->file->name = $name;
        $this->file->content = $content;
        $this->file->type = $type;
        $this->file->length = $length;
	}

    public function request($vars, $component_name = '', $from='ALL')
    {
        $value = '';
        if ( ($vars != '') )
        {
           $value = MIOLO::_REQUEST($vars, $from);
           if (!isset($value))
           {
              if (!$component_name)
              {
                $value = $this->state->get($vars);
              }
              else
              {
                $value = $this->state->get($vars, $component_name);
              }
           }
        }
        return $value;
    }

    public function setViewState($var, $value, $component_name = '')
    {
        $this->state->set($var, $value, $component_name);
    }

    public function getViewState($var, $component_name = '')
    {
        return $this->state->get($var, $component_name);
    }

    public function loadViewState()
    {
        $this->state->loadViewState();
    }

    public function saveViewState()
    {
        $this->state->saveViewState();
    }

    public function loadPostData()
    {

    }

    // Set a value for a client element, using DOM
    // This method use a javascript code that is execute on response
    public function setElementValue($element, $value)
    {
        $this->onLoad("miolo.getElementById('{$element}').value = '{$value}';");
    }

    public function copyElementValue($element1, $element2)
    {
        $this->onLoad("miolo.getElementById('{$element1}').value = miolo.getElementById('{$element2}').value;");
    }

    public function redirect($url)
    {
         $this->manager->getSession()->freeze();
         $this->goto = str_replace('&amp;','&',$url);
         $this->generateMethod = 'generateRedirect';
    }

    public function window($url)
    {
         $this->manager->getSession()->freeze();
         $this->goto = str_replace('&amp;','&',$url);
         $this->generateMethod = 'generateWindow';
    }

    public function forward($url)
    {
         $this->isPostBack = false;
         $_REQUEST['__MIOLOTOKENID'] = $this->manager->getSession()->get('__MIOLOTOKENID');
         $this->goto = str_replace('&amp;','&',$url);
         $this->manager->forward = $this->goto;
         $this->manager->context->parseUrl($this->goto);
    }

    public function insert($url)
    {
         $this->goto = str_replace('&amp;','&',$url);
         $context = clone $this->manager->context;
         $this->manager->context->parseUrl($this->goto);
         $this->manager->invokeHandler($this->manager->context->module,$this->manager->context->action);
         $this->manager->context = $context;
    }

    /*
        deprecated at 2.5

    public function refresh()
    {
       $this->onLoad('document.' . $this->name . '.submit();');
    }
    */

    public function generate()
    {
        $this->manager->logMessage('[PAGE] Generating Page : ' . $this->generateMethod);
	    return $this->{$this->generateMethod}();
    }

    public function generateRedirect()
    {
        if ( $this->manager->getIsAjaxCall() )
        {
            $tokenId = $this->manager->getSession()->get('__MIOLOTOKENID');
            $scripts = array('','',"; miolo.page.tokenId = '$tokenId'; miolo.doRedirect('{$this->goto}','__mainForm');",'');
            $this->ajax->setResponseScripts($scripts);
            $response = $this->ajax->response;
            $this->ajax->set_data($response);
            $this->ajax->return_data();
        }
        else
        {
            header('Location:'.$this->goto);
        }
    }

    public function generateWindow()
    {
        if ( $this->manager->getIsAjaxCall() )
        {
            $scripts = array('','',"miolo.doWindow('{$this->goto}','__mainForm');",'');
            $this->ajax->setResponseScripts($scripts);
            $response = $this->ajax->response;
            $this->ajax->set_data($response);
            $this->ajax->return_data();
        }
        else
        {
            header('Location:'.$this->goto);
        }
    }

    private function sendTokenId()
    {
        $tokenId = $this->manager->getSession()->get('__MIOLOTOKENID');
        $this->onload("miolo.page.tokenId = '$tokenId';");
    }

    public function prepareForm()
    {
        $formId = $this->getFormId();
        $onsubmit = ($o = $this->getOnSubmit()->getValueText('',' && ' . chr(13))) ? $o : 'true';
        $onload = $this->getOnLoad()->getValueText('',chr(13));
        $formOnLoad =     <<< HERE

function $formId()
{
    miolo.addForm('$formId');
    miolo.getForm('$formId').onLoad = function ()
    {
        $onload
    };
    miolo.getForm('$formId').onSubmit = function ()
    {
        miolo.submit();
        var result = $onsubmit;
        return result;
    };
    miolo.setForm('$formId');
    miolo.getForm('$formId').onLoad();
}
$formId();

HERE;

        $this->onload->clear();
        $this->onLoad($formOnLoad);
    }

    public function generateForm()
    {
        $this->sendTokenId();
        $formId = $this->getFormId();
        $this->form = new MHtmlForm($formId);
        $this->theme = $this->manager->getTheme();
        $this->theme->setForm($this->form);
        $content[] = $this->theme->generate();
        $content[] = new MHiddenField($formId.'__VIEWSTATE',$this->state->getViewState());
        $content[] = new MHiddenField('cpaint_response_type');
        $content[] = new MHiddenField($formId.'__ISPOSTBACK');
        $content[] = new MHiddenField($formId.'__EVENTTARGETVALUE');
        $content[] = new MHiddenField($formId.'__EVENTARGUMENT');
        $content[] = new MHiddenField($formId.'__FORMSUBMIT',$formId);
        if ($this->winid != '')
        {
            $content[] = new MHiddenField('__WINID',$this->winid);
            $content[] = new MHiddenField('__DOMWINID',$this->domwinid);
        }
        $this->prepareForm();
        $this->form->setContent($content);
        $this->form->setEnctype($this->enctype);
        $this->form->setAction($this->action);
    }

    public function prepareBase()
    {
        $this->addHttpEquiv('Content-Type','text/html; charset=' + $this->manager->getConf('options.charset'));
        $this->addMeta('Generator','MIOLO Version '. MIOLO_VERSION . '; http://www.miolo.org.br');
//        $this->addStyleURL($this->manager->getConf('home.url')."/scripts/dojoroot/dijit/themes/tundra/tundra.css");
        $this->addStyle('dojo.css');
        $this->addStyle('miolo.css');
        $this->addStyle( $this->manager->getConf('theme.search').'.css' ); //FIXME solução temporária pois não funcionáva o addStyle de dentro do nossos formulários
        $this->insertScript('m_md5.js');
        $this->insertScript('m_compatibility.js');
        $this->insertScript('m_form.js');
        $this->insertScript('m_grid.js');
        $this->insertScript('m_box.js');
        $this->insertScript('m_encoding.js');
        $this->insertScript('m_ajax.js');
        $this->insertScript('m_page.js');
        $this->insertScript('m_miolo.js');
        $this->insertScript('prototype/prototype.js');
        $this->insertScript('dojoroot/dojo/dojo.js');
        $this->addDojoRequire("dojo.parser");
    }


    public function generateBase()
    {
        $this->sendTokenId();
        $this->prepareBase();
        return $this->painter->page($this);
    }

    public function generateDefault()
    {
        $this->sendTokenId();
        $this->saveViewState();
        $this->prepareBase();
        if ($this->manager->getContext()->inDomain())
        {
            $this->onLoad("   miolo.setTitle('" . $this->title  . "');");
        }
        if (($themeLayout = $this->manager->_request('themelayout')) != '')
        {
            $this->manager->getTheme()->setLayout($themeLayout);
        }
        $this->generateForm();
        return $this->painter->page($this);
    }

    public function generateAJAX()
    {
        $this->sendTokenId();
        $this->theme = $this->manager->getTheme();
$this->manager->trace('generateAjax...');
        $this->saveViewState();
        $this->setElementValue($this->state->getIdElement(),$this->state->getViewState());

        if ($this->ajax->response_type == 'TEXT')
        {
            $response = $this->theme->generateElementInner('ajax');
// $this->manager->trace($response);
        }
        elseif (!$this->ajax->get_data())
        {
            if ($this->ajax->response == NULL)
            {
                $element = $this->manager->formSubmit;
                if ($this->winid != '')
                {
                    $this->theme->setLayout('content');
                    $this->generateForm();
                    $content = $this->form->generate();
                    $element = $this->domwinid;
                }
                elseif ($element == '__mainForm')
                {
                    $this->generateForm();
                    $content = $this->form->generate();
                }
                else
                {
                    $this->theme->setLayout('dynamic');
                    $content = $this->theme->generate($element);
                    $this->prepareForm();
                    $element = array_keys($content);
                }

//      $this->manager->trace(print_r($content,true));
//      $this->manager->trace(print_r($element,true));

                $this->ajax->setResponseControls($this->stdout, "stdout");
                ob_end_clean();

                $this->ajax->setResponseControls($content, $element);
            }
            $scripts[0] = $this->getScripts()->getTextByTemplate("<script type=\"text/javascript\" src=\"/:v/\"></script>\n");
            $scripts[1] = $this->getJsCode()->getValueText('',chr(13));
            $scripts[2] = ($onload = $this->getOnLoad()->getValueText('',chr(13))) ? "{$onload}" : '';
            $scripts[3] = ($onerror = $this->getOnError()->getValueText('',chr(13))) ? "{$onerror}" : '';

            $this->ajax->setResponseScripts($scripts);
//      $this->manager->trace($this->ajax->response->html[0]);
//      $this->manager->trace($this->ajax->response->html[1]);
            $response = $this->ajax->response;
        }
        $this->ajax->set_data($response);
        $this->ajax->return_data();
    }

    public function generateFile()
    {
       $this->sendTokenId();
       $response = $this->manager->response;
	   $response->setContentType($this->file->type);
       $response->setContentLength($this->file->length);
       $response->setFileName($this->file->name);
       $response->sendBinary($this->file->content);
    }

    public function generateDOMPdf()
    {
       $this->theme = $this->manager->getTheme();
       $this->addHttpEquiv('Content-Type','text/html; charset=ISO-8859-1');
//       $this->addStyle('m_common.css');
//       $this->addStyle('m_boxes.css');
       $this->addStyle('miolo.css');
       return $this->painter->dompdf($this);
    }
}
?>
