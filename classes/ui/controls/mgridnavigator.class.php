<?php
define('PN_PAGE', 'pn_page');
/**
 * Uma implementação de controles de navagação de páginas para grids
 */
class MGridNavigator extends MControl
{
    public $pageLength;
    public $pageNumber;
    public $action;
    public $range;
    public $rowCount;
    public $gridCount;
    public $pageCount;
    public $idxFirst;
    public $idxLast;
    public $showPageNo = false;
    public $linktype; // hyperlink or linkbutton
    public $grid;

    public function __construct($length = 20, // Number of records per page
                           $total = 0,   // Number total of records 
                           $action = '?', // Action URL
                           $grid = NULL// The grid which contains this component
        )
    {
        parent::__construct();
        $this->pageLength = $length;
        $this->gridCount = $length;
        $this->setRowCount($total);
        $this->grid = $grid;
/*
        if (urldecode($this->page->request('gridName')) == $this->grid->name)
        {
          $this->setPageNumber($this->page->request(PN_PAGE));
          $state->set('pn_page', $this->page->request(PN_PAGE), $this->grid->name);
        }
        else
        {
          $this->setPageNumber($state->get('pn_page', $this->grid->name));
        }
*/
        $this->setPageNumber(MIOLO::_REQUEST('pn_page'));
        //$this->setPageNumber($this->page->getViewState("pn_page",$this->grid->name));

//        $this->grid->pageNumber = MUtil::NVL($state->get('pn_page', $this->grid->name),1);
//        $this->grid->prevPage = MUtil::NVL($state->get('grid_page', $this->grid->name),1);

//        $this->grid->handlerSelecteds();

//        $state->set('grid_page', $this->getPageNumber(), $this->grid->name);

        $this->action = $action;
        $this->linktype = 'hyperlink';

    }

    public function setAction($url)
    {
        $this->action = $url;
    }

    public function setLinkType($linktype)
    {
        $this->linktype = $linktype;
    }

    public function setRowCount($rowCount)
    {
        $this->rowCount = $rowCount;
        $this->pageCount = ($this->pageLength > 0) ? (int)(($this->rowCount + $this->pageLength - 1) / $this->pageLength) : 1;
    }

    public function setGridCount($gridCount)
    {
        $this->gridCount = $gridCount;
    }

    public function setPageNumber($num)
    {
        $this->pageNumber = (int)($num ? $num : 1);
        $this->range = new MRange($this->pageNumber, $this->pageLength, $this->rowCount);
        $this->setIndexes();
    }

    public function setCurrentPage( $pageNumber )
    {
        $this->setPageNumber( $pageNumber );
    }

    public function setIndexes()
    {
      $this->range-> __construct($this->pageNumber, $this->pageLength, $this->rowCount);
      $this->idxFirst = $this->range->offset;
      $this->idxLast = $this->range->offset + $this->range->rows - 1;
      $this->setGridCount($this->range->rows);
    }

    public function setGridParameters($pageLength, $rowCount, $action, $grid)
    {
      $this->pageLength = $pageLength;
      $this->setRowCount($rowCount);
      $this->action = $action;
      $this->grid = $grid;
      $this->setIndexes();
    }

    public function getRowCount()
    {
        return $this->rowCount;
    }

    public function getGridCount()
    {
        return $this->gridCount;
    }

    public function getPageNumber()
    {
        return $this->pageNumber;
    }

    public function getPageCount()
    {
        return $this->pageCount;
    }

    public function getPagePosition($showPage = true)
    {
        $position = '[' . ($showPage ? _M('Page') : '') . ' ' . $this->getPageNumber() . ' ' . _M('of') . ' '
                        . $this->getPageCount() . "]";
        return $position;
    }

    public function getPageLinks($showPage = true, $limit = 10)
    {           
        $pageCount = $this->getPageCount();
        $pageNumber = $this->getPageNumber();
        $pageLinks = array();

        $p = 0;

        if (!$this->getRowCount())
        {
            $pageLinks[$p] = new MLabel('&nbsp;&nbsp;&nbsp;');
            $pageLinks[$p++]->setClass('m-pagenavigator-text');
        }
        else
        {
            if ($showPage)
            {
                $pageLinks[$p] = new MText('', '&nbsp;Página:&nbsp;');
                $pageLinks[$p++]->setClass('m-pagenavigator-text');
            }

            if ($pageNumber <= $limit)
            {
                $o = 1;
            }
            else
            {
                $o = ((int)(($pageNumber - 1) / $limit)) * $limit;
                $pageLinks[$p] = new MLinkButton('', '...', "$this->action&" . PN_PAGE . "=" . $o++ . "&gridName=". urlencode($this->grid->name));
                $pageLinks[$p++]->setClass('m-pagenavigator-link');
            }

            for ($i = 0; ($i < $limit) && ($o <= $pageCount); $i++, $o++)
            {
                $pg = $o;
                if ($o != $pageNumber)
                {
                    $pageLinks[$p] = new MLinkButton('', $pg, "$this->action&" . PN_PAGE . "=" . $o . "&gridName=". urlencode($this->grid->name));
                    $pageLinks[$p]->setClass('m-pagenavigator-link');
                    $pageLinks[$p++]->setAttribute('onMouseOver', "top.status='Página $pg'");
                }
                else
                {
                    $pageLinks[$p] = new MLinkButton('', "$pg", "$this->action&" . PN_PAGE . "=" . $o . "&gridName=". urlencode($this->grid->name));
                    $pageLinks[$p++]->setClass('m-pagenavigator-selected');
                }
            }

            if ($o < $pageCount)
            {
                $pageLinks[$p++] = new MLabel('');
                $pageLinks[$p] = new MLinkButton('', '...', "$this->action&" . PN_PAGE . "=" . $o . "&gridName=". urlencode($this->grid->name));
                $pageLinks[$p++]->setClass('m-pagenavigator-link');
            }
        }

        return $pageLinks;
    }

    public function getPageRange($subject = '')
    {
        if (!$this->getRowCount())
        {
            $range = 'Nenhum dado';
        }
        else
        {
            $first = $this->idxFirst + 1;
            $last = $this->idxLast + 1;
            $range = '[' . $first . '..' . $last . '] de ' . $this->getRowCount() . $subject;
        }

        return new MSpan('', $range, 'm-pagenavigator-range');
    }

    public function getPageRows($subject = '')
    {
        $rows = $this->getGridCount() . '&nbsp;' . $subject;
        return $rows;
    }

    public function getPageFirst()
    {
        $pageNumber = $this->getPageNumber();
        $attrs = array('border' => '0');
        $btn_first0 = new MImage('_gnFirst', 'Primeira', "images/but_pg_primeira.gif", $attrs);
        $btn_first1 = new MImageButton('_gnFirst', 'Primeira', "$this->action&" . PN_PAGE . "=1" . "&gridName=". urlencode($this->grid->name),
                                      "images/but_pg_primeira_x.gif");
        $btn = ($pageNumber > 1 ? $btn_first1 : $btn_first0);
        return new MSpan('', $btn, 'm-pagenavigator-image');
    }

    public function getPagePrev()
    {
        $pageNumber = $this->getPageNumber();
        $pagePrev = $pageNumber - 1;
        $attrs = array('border' => '0');
        $btn_prev0 = new MImage('_gnPrev', 'Anterior', "images/but_pg_anterior.gif", $attrs);
        $btn_prev1 = new MImageButton('_gnPrev', 'Anterior', "$this->action&" . PN_PAGE . "=" . $pagePrev . "&gridName=". urlencode($this->grid->name),
                                     "images/but_pg_anterior_x.gif");
        $btn = ($pageNumber > 1 ? $btn_prev1 : $btn_prev0);
        return new MSpan('', $btn, 'm-pagenavigator-image');
    }

    public function getPageNext()
    {
        $pageNumber = $this->getPageNumber();
        $pageNext = $pageNumber + 1;
        $pageCount = $this->getPageCount();
        $attrs = array('border' => '0');
        $btn_next0 = new MImage('_gnNext', 'Próxima', "images/but_pg_proxima.gif", $attrs);
        $btn_next1 = new MImageButton('_gnNext', 'Próxima', "$this->action&" . PN_PAGE . "=" . $pageNext . "&gridName=". urlencode($this->grid->name),
                                     "images/but_pg_proxima_x.gif");
        $btn = ($pageNumber < $pageCount ? $btn_next1 : $btn_next0);
        return new MSpan('', $btn, 'm-pagenavigator-image');
    }

    public function getPageLast()
    {
        $pageNumber = $this->getPageNumber();
        $pageCount = $this->getPageCount();
        $attrs = array('border' => '0');
        $btn_last0 = new MImage('_gnLast', 'Última', "images/but_pg_ultima.gif", $attrs);
        $btn_last1 = new MImageButton('_gnLast', 'Última', "$this->action&" . PN_PAGE . "=" . $pageCount . "&gridName=". urlencode($this->grid->name),
                                     "images/but_pg_ultima_x.gif");
        $btn = ($pageNumber < $pageCount ? $btn_last1 : $btn_last0);
        return new MSpan('', $btn, 'm-pagenavigator-image');
    }
}
?>
