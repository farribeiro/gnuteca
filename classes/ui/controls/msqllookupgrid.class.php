<?php
class MLookupGrid extends MDataGrid
{
    /**
      LookupGrid constructor
         $query - a query object
         $columns - array of columns objects
         $href - base url of this lookupgrid
         $pageLength - max number of rows to show (0 to show all)
    */
    public function __construct(&$query, $columns, $href, $pageLength = 15, $index = 0)
    {
        parent::__construct($query, $columns, $href, $pageLength, $index);
        $this->emptyMsg = 'Nenhum registro encontrado na pesquisa!';
        $this->setFiltered(true);

        $filtered = $this->getFiltered();
        $this->box->setClose( 'javascript:window.close();');
        $this->pn = new MGridNavigator($this->pageLength, $this->rowCount, 
          $this->getURL($filtered, $this->ordered), $this);
    }

    public function generateData()
    {
        global $page, $state;

        $this->data = $this->query->result;
        $this->rowCount = $this->query->getRowCount();

        if ($this->pageLength)
        {
            $filtered = $this->getFiltered();

            $this->pn->setGridParameters($this->pageLength, $this->rowCount, $this->getURL($filtered, $this->ordered), $this);

            $this->query->setpageLength($this->pageLength);
            $this->data = $this->query->getPage($this->pn->getPageNumber());
        }
        else
        {
            $this->pn = null;
        }
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
        $array[] = new MImageButton('', 'Filtrar', $this->getURL(true, $this->ordered), "/images/button_select.png");
//        $array[] = new MSeparator;
        $url = str_replace('&amp;','&', $url);
        $formId = $this->page->getFormId();
        $winId = $this->page->domwinid;
        $formNode = "miolo.getElementById('{$winId}')";
        $event = "miolo.doLinkButton('$url','','','$formId')";
        $this->page->onLoad("dojo.connect($formNode, 'onkeypress', function(event) { if (event.keyCode==dojo.keys.ENTER) { alert('no enter'); $event; event.stopPropagation();}})");
mdump('kkkkkkkkkkkkkkkkkk');
        return new MDiv('', $array, 'm-grid-filter');
    }

    public function generateHeader()
    {
        $header[] = $this->generateFilter();
        return $header;
    }

    public function generateFooter()
    {
        if (!$this->data)
            $footer[] = $this->generateEmptyMsg();

//        $footer[] = new MSeparator();
        $footer[] = $this->generateNavigationFooter();
        
        if ( $this->controls )
            $footer[] = $this->generateControls();
        
        return $footer;
    }
}

?>
