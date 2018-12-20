<?php
class MLookupGrid extends MGrid
{
    /**
        Base class to Lookup Grids

        $href - base url of this lookupgrid
        $pageLength - max number of rows to show (0 to show all)
        $index - columns acting as index
    */
    
    public $href;
    public $pageLength;
    public $index;
    public $emptyMsg;

    public function __construct($columns, $href, $pageLength = 15, $index = 0)
    {
        parent::__construct(NULL,$columns,$href, $pageLength = 15, $index = 0);
        $this->emptyMsg = "Nenhum registro encontrado.";
        $this->setFiltered(true);
        $filtered = $this->getFiltered();
        $this->pn = new MGridNavigator($this->pageLength, $this->rowCount, $this->getURL($filtered, $this->ordered), $this);
    }

    public function generateTitle()
    {
        $t = new MBoxTitle('boxTitle', $this->title, "javascript:miolo.getWindow('{$this->page->winid}').close();");
        return $t;
    }

    public function generateFilter()
    {
        global $page;

        if (!$this->filter)
            return null;

        foreach ($this->filters as $k => $f)
        {
            $array[] = $f->generate();
        }

        $url = $this->getURL(true, $this->ordered);
        $array[] = new MImageButton('', 'Filtrar', $this->getURL(true, $this->ordered), "images/button_select.png");
        $url = str_replace('&amp;','&', $url);
        $formId = $this->page->getFormId();
        $winId = $this->page->domwinid;
        $formNode = "miolo.getElementById('{$winId}')";
        $event = "miolo.doLinkButton('$url','','','$formId')";
        $this->page->onLoad("miolo.connect('{$winId}', 'onkeypress', function(event) { if (event.keyCode==dojo.keys.ENTER) {  event.preventDefault();$event;}});");
        return new MDiv('', $array, 'm-grid-filter');
    }

    public function generateHeader()
    {
        $header[] = $this->generateFilter();
        return $header;
    }

    public function generateFooter()
    {
        //FIXME: trecho adicionado para testar se foi clicado no botão pesquisar. Ticket #7455
        $submit = false;
        //percorre o request para encontrar se foi ou não clicado no botão pesquisar
        foreach( $_REQUEST as $key=>$value )
        {
            if ( preg_match('/frm.*__FORMSUBMIT/', $key, $found) )
            {
                $submit = true;
                break;
            }
        }
        if ( (!$this->data) && ($submit) )
        {
            $footer[] = $this->generateEmptyMsg();
        }
        $footer[] = $this->generateNavigationFooter();
        if ( $this->controls )
        {
            $footer[] = $this->generateControls();
        }
        return $footer;
    }
}

?>
