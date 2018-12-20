<?php
class MTabbedFormPage extends MControl
{
    public $tabbedform; // em qual tabbedform esta página está inserida
    public $form; // form a ser renderizado na pagina
    public $index; // indice desta pagina dentro do tabbedform (0-based)
    public $title; // titulo da pagina

    public function __construct($form)
    {
        parent::__construct();
        $this->form = $form;
        $this->visible = true;
        $this->enabled = true;
        $this->title = $form->title;
    }
}

class MTabbedForm extends MForm
{
    static  $order = 0; // número de ordem do form
    public $nOrder; // número de ordem do form
    public $pages; // array de TabbedFormPages
    public $activepage; // referencia a TabbedFormPage sendo mostrada
    public $currentpage; // indice da TabbedFormPage sendo exibida 
    public $pagecount; // quantas TabbedFormPage associadas a este form
    public $pagewidth = 80;
    public $pageheight = 250;
    public $header;
    public $footer;
    public $painterMethod;

    public function __construct($title = '', $action = '')
    {
        parent::__construct($title, $action);
        $this->nOrder = MTabbedForm::$order++;
//        $this->addStyleFile('m_tabforms.css');
        $this->page->addScript('x/x_core.js');
        $this->page->addScript('x/x_dom.js');
        $this->page->addScript('m_tabbed.js');
        $this->fields = array();
        $this->setCurrentPage($this->page->request('frm_currpage_') + 0);
        $this->pagecount = 0;
//        $this->painterMethod = 'html'; 
        $this->painterMethod = 'javascript'; 
    }

    public function addField()
    {
        $this->manager->assert(false, "Tabbed form doesn't yet support AddField Function!!!");
    }

    public function addPage($form)
    {
        $page = new MTabbedFormPage($form);
        $page->tabbedform = $this;
        $form->tabbedform = $this;
        $page->index = $this->pagecount;
        $this->pages[$page->index] = $page;
        ++$this->pagecount;
        $this->fields = array_merge($this->fields, $form->fields);

        foreach ($form->fields as $field)
        {
            if (is_array($field))
            {
                $namefield = uniqid('frm_array');
            }
            else
            {
                $namefield = $field->name;
            }

            $this->manager->assert(!isset($this->$namefield),
                                   "Err: field [$namefield] already defined in form [$this->title]!");
            $this->fields[$namefield] = $field;
        }

        $this->defaultButton = false;
    }

    public function setPages($forms)
    {
        if (is_array($forms))
        {
            foreach ($forms as $form)
            {
                $this->addPage($form);
            }
        }
    }

    //
    // return label of current page
    //
    public function getCurrentPage()
    {
        return $this->currentpage;
    }

    public function setCurrentPage($index)
    {
        $_POST['frm_currpage_'] = $index;
        $this->currentpage = $index;
    }

    //
    // returns a plain list of all fields contained in the tabbedform
    //
    public function getFieldList()
    {
        $fields = array
            (
            );

        for ($i = 0; $i < $this->pagecount; $i++)
        {
            $page = $this->pages[$i];
            $form = $page->form;
            $fields = array_merge($fields, $form->getFieldList());
        }

        return $fields;
    }

    public function eventHandler()
    {
        $form = $this->pages[$this->getCurrentPage()]->form;
        $form->eventHandler();
        parent::eventHandler();
    }

    public function setPainterMethod($method)
    {
        $this->painterMethod = $method; 
    }
    /*
        Renderize
    */
    public function generateHeader()
    {
        return ($this->header != NULL) ? new MDiv('',$this->header,'m-tabform-text') : NULL;
    }

    public function generateFooter()
    {
        return ($this->footer != NULL) ? new MDiv('',$this->footer,'m-tabform-text') : NULL;
    }

    public function generateTabs()
    {
        global $MIOLO, $page;

        $currpage = $this->getCurrentPage();
        $t = array
            (
            );

        for ($i = 0; $i < $this->pagecount; $i++)
        {
            $t[] = new MDiv('', '', 'spacer');
            $page = &$this->pages[$i];

            if ($page->index == $currpage)
            {
                $t[] = new MDiv('', '', 'vertical1A');
                $t[] = new MDiv('', '', 'vertical2A');
                $t[] = new MDiv('', new MSpan('', $page->title, 'm-tabpage-link'), 'contentA');
                $t[] = new MDiv('', '', 'vertical3A');
                $t[] = new MDiv('', '', 'vertical4A');
            }
            else
            {
                if ($page->visible)
                {
                    $pageName = $this->page->name;
                    $href = "javascript:MIOLO_TabbedForm_GotoPage('$page->index')";
                    $t[] = new MDiv('', '', 'vertical1B');
                    $t[] = new MDiv('', '', 'vertical2B');

                    if ($page->enabled)
                    {
                        $link = new MLink('', '', $href, $page->title);
                        $link->setClass('m-tabpage-link');
                    }
                    else
                    {
                        $link = new MSpan('', $page->title);
                        $link->setClass('m-tabpage-link-disable');
                    }

                    $t[] = new MDiv('', $link, 'contentB');
                    $t[] = new MDiv('', '', 'vertical2B');
                    $t[] = new MDiv('', '', 'vertical1B');
                }
            }
        }

        $t[] = new MDiv('', '', 'contentC');
        return new MDiv('', $t, 'm-tabpage');
    }

    public function generateBody()
    {
        global $theme;

        // optionally generate errors
        if ($this->hasErrors())
        {
            $this->generateErrors();
        }

        $hidden = null;
        $currentPage = $this->getCurrentPage();
        $width = '100%';
        $row = 0;
        $t = new SimpleTable();
        $t->setAttributes("border=0 width=$width cellpadding=0 cellspacing=0 ");
        // header
        $t->attributes['cell'][$row][0] = "colspan=3";
        $t->cell[$row++][0] = $this->generateHeader();
        // tabs
        $t->attributes['cell'][$row][0] = "colspan=3";
        $t->cell[$row++][0] = $this->generateTabs();
        // page
        $t1 = new SimpleTable();
        $t1->setAttributes("border=0 width=$width cellpadding=0 cellspacing=5 ");
        $hidden = null;
        $this->activepage = $this->pages[$this->getCurrentPage()];
        $activeForm = $this->activepage->form;
        $t1->cell[0][0] = $activeForm->generateLayoutFields($hidden);
        $layout = $this->manager->theme->getLayout();

        if ($layout != 'print')
        {
            $buttons = $activeForm->generateButtons();

            if (count($buttons))
            {
                $t1->attributes['cell'][1][0] = "colspan=3";
                $t1->cell[1][0] = $buttons;
            }
        }

        $t->attributes['cell'][$row][0] = "class=\"m-tabform-body\"";
        $t->cell[$row++][0] = &$t1;
        // script
        $t->cell[$row++][0] = $activeForm->generateScript();
        // footer
        $t->attributes['cell'][$row][0] = "colspan=3";
        $t->cell[$row++][0] = $this->generateFooter();

        // buttons
        if ($layout != 'print')
        {
            $buttons = $this->generateButtons();

            if (count($buttons))
            {
                $t->attributes['cell'][$row][0] = "class=\"m-form-body\"";
                $t->cell[$row++][0] = $buttons;
            }
        }

        // hidden
        if ($hidden)
        {
            $t->cell[$row++][0] = $this->generateHiddenFields($hidden);
        }

        // gera campos 'HIDDEN' para os campos das páginas que não estão visíveis 
        $hidden = array
            (
            );

        foreach ($this->pages as $page => $tabbedPage)
        {
            if ($page != $currentPage)
            {
                $fields = $tabbedPage->form->fields;

                foreach ($fields as $f)
                {
                    if (is_array($f->value))
                    {
                        foreach ($f->value as $v)
                        {
                            $hidden[] = new HiddenField("{$f->name}[]", $v);
                        }
                    }
                    else
                    {
                        if (($f instanceof MRadioButton) || ($f instanceof MCheckBox))
                        {
                            if ($f->checked)
                            {
                                $hidden[] = new MHiddenField($f->name, $f->value);
                            }
                        }
                        else
                        {
                            $hidden[] = new MHiddenField($f->name, $f->value);
                        }
                    }
                }
            }
        }

        $hidden[] = new MHiddenField('frm_currpage_', $currentPage);

        if ($hidden)
        {
            $t->attributes['cell'][$row][0] = "colspan=3";
            $t->cell[$row++][0] = $this->generateHiddenFields($hidden);
        }

        return $t;
    }

    public function generateHtml()
    {
        global $MIOLO;

        if (!isset($this->buttons))
        {
            if ($this->defaultButton)
            {
                $this->buttons[] = new FormButton(FORM_SUBMIT_BTN_NAME, 'Enviar', 'SUBMIT');
            }
        }

        $body = $this->generateBody();

        $b = new MDiv('', $body, '');
        $title = new MSpan('',$this->title,'m-tabform-title'); 
        $f = new MDiv('', array($title, $b), 'm-tabform-box');
        return $f->generate();
    }

    public function generateJavascript()
    {
        global $MIOLO;

        if (!isset($this->buttons))
        {
            if ($this->defaultButton)
            {
                $this->buttons[] = new FormButton(FORM_SUBMIT_BTN_NAME, 'Enviar', 'SUBMIT');
            }
        }
        $id = $this->name . '_tab' . $this->nOrder;
        $w = $this->pagecount * $this->pagewidth;
        $h = $this->pageheight;
        $code = "var $id = new xTabPanelGroup('{$id}', $w, $h, 20, 'm-tabform-panel','m-tabform-group','m-tabform-default','m-tabform-selected',{$this->currentpage})";
        $this->page->onLoad($code);


        $hidden = null;
        $currentPage = $this->getCurrentPage();
        $width = '100%';
        $row = 0;
        $body = array();
        // tabs
        $tabs = array();
        for ($i = 0; $i < $this->pagecount; $i++)
        {
            $page = $this->pages[$i];
            $pageName = $this->page->name;
            $span = new MSpan('',$page->title,'m-tabform-span');  
            $tabs[] = new MDiv('', $span, 'm-tabform-default');
        }

        $body[] = new MDiv('', $tabs, 'm-tabform-group');

        // pages
        $header = $this->generateHeader();
        $hidden = array();
        for ($i = 0; $i < $this->pagecount; $i++)
        {
            $page = $this->pages[$i];
            $pgs = array(); 
            if ( $page->form->hasErrors() )
            {
                $pgs[] = $page->form->generateErrors();
            }
            if ( $this->hasInfos() )
            {
                $pgs[] = $page->form->generateInfos();
            }
            $pgs[] = $page->form->generateLayoutFields($hidden);
            $buttons = $page->form->generateButtons();
            $script[] = $page->form->generateScript();
            if (count($buttons))
            {
               $pgs[] = new MDiv('', $buttons, '');
            }
            $body[] = new MDiv('', $pgs, 'm-tabform-panel');
        }
        $buttons = $this->generateButtons();
        if (count($buttons))
        {
           $body[] = new MDiv('', $buttons, '');
        }
        $hidden[] = new MHiddenField('frm_currpage_', $this->getCurrentPage());
        $body[] = $this->generateHiddenFields($hidden); 

        $b = new MDiv($id,$body, 'm-tabform-panel-group');
        $f = new MDiv('', array($header, $b, $script),'m-collapsible');
        return $f->generate();
    }

    public function generate()
    {
        $method = 'Generate' . $this->painterMethod;
        return $this->$method();
    }
}
?>