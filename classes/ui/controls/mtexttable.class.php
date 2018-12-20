<?php
class MTextTable extends MFormControl
{
    protected $buttons;
    protected $fields;
    protected $showcode;
    protected $shownav;
    protected $layout;
    protected $codevalue;
    protected $colWidth;
    private $tableId;
    public $info;
    protected $numRows;
//    public $colWidth;
    private $scrollHeight;
    private $scrollWidth;
    private $table;
    private $select;
    private $index;
    private $zebra;
    private $title;

    public function __construct($name='', $value=array(), $label = '', $select = '', $zebra = true )
    {
        parent::__construct($name,$value,$label);
//        $this->page->addScript('x/x_core.js');
//        $this->page->addScript('x/x_dom.js');
//        $this->page->addScript('x/x_event.js');
        $this->page->addScript( 'm_texttable.js' );
        $this->tableId =  $name.'_table';
        $this->table = new MSimpleTable($this->tableId,"cellspacing=0 cellpadding=0 border=0 width=100%"); 
        $this->select = $select;
        $this->scrollHeight = '';
        $this->scrollWidth = '';
        $this->borderType   = $border;
        $this->caption      = $caption;
        $this->index = 0;
        $this->formMode = MControl::FORM_MODE_SHOW_ABOVE;
        $this->zebra = $zebra ? 'true' : 'false'; 
//        $this->page->onLoad("MIOLO_TextTable('{$this->tableId}',{$zebra});");
    }

    public function setScrollHeight( $height )
    {
        $this->scrollable   = true;
        $this->scrollHeight = $height;
    }

    public function setScrollWidth( $width )
    {
        $this->scrollWidth = $width;
    }

    public function setTitle( $title = array() )
    {
        $title = (is_array($title)) ? $title : array($title);
        foreach($title as $i=>$c)
        {
            $this->title[$i] = explode(':',$title[$i]);
            $this->colWidth[$i] = $this->title[$i][1];
        }
    }

    public function setColWidth( $colWidth = array() )
    {
        $this->colWidth = $colWidth;
    }

    public function setIndex($value)
    {
        $this->index = $value;
    }

    public function getTableId()
    {
        return $this->tableId;
    }

    public function addCode($code)
    {
        $this->codevalue[] = $code;
    }

    public function generateLink($value, $row)
    {
        $index = $row[$this->index];
        $href = ereg_replace('\$id', $index, $value);
        $n = count($row);
        for ($r = 0; $r < $n; $r++)
        {
            $href = str_replace("%$r%", urlencode($row[$r]), $href);
            $href = str_replace("#$r#", $row[$r], $href);
        }
        return $href;
    }

    public function generate()
    {
        $t = array();

        if (count($this->title))
        {
            $tableTitle = new MSimpleTable($this->tableId.'_head',"cellspacing=0 cellpadding=0 border=0 width=100%"); 
            $tableTitle->setColGroup(0);
            $c = 0;
            if ($this->select != '')
            {
                $tableTitle->setColGroupCol(0,0,"width=10");
                $control = new MButton('', '&nbsp;', '&nbsp;');
                $control->setClass('link-select',false);
                $tableTitle->setHead($c, $control); 
                $tableTitle->setHeadClass($c++, 'select'); 
            }
            foreach($this->title as $i=>$col)
            {
                $control = new MSpan('', $this->title[$i][0], 'colTitle');
                $tableTitle->setColGroupCol(0,$c+$i,"width=" . $this->title[$i][1]);
                $tableTitle->setHead($c+$i,$control->generate()); 
            }
            $html = $tableTitle->generate();
            $head = new MDiv('', $html, 'head' );
            $t[] = $head;
        }

        $colWidth = '['; 
        if (count($this->colWidth))
        {
            $c = ($this->select != '') ? 1 : 0;
            foreach($this->colWidth as $i=>$col)
            {
                $colWidth .= ($i ? ',':'') . $this->colWidth[$i];
                $this->table->setColGroupCol(0,$i+$c,"width=" . $this->colWidth[$i]);
            }
        }
        $colWidth .= ']';

        foreach($this->value as $r=>$row)
        {
            if (count($this->title))
            {
                $this->table->setColGroup(0);
            }
            $c = 0;
            if ($this->select != '')
            {
                if (count($this->title))
                {
                    $this->table->setColGroupCol(0,0,"width=10");
                }
                $link = $this->generateLink($this->select,$row);
                $control = new MButton('', '&nbsp;', $link);
                $control->setClass('link-select',false);
                $this->table->setCell($r,$c, $control); 
                $this->table->setCellClass($r,$c++, 'select'); 
            }
            foreach($row as $i=>$col)
            {
                $value = $this->generateLink($this->value[$r][$i], $row);
                $this->table->setCell($r,$c++,$value);
            }
        }
        
        $html = $this->table->generate();
        $scroll = new MDiv('', $html, 'scroll' );
        $scroll->height = $this->scrollHeight;
        $scroll->width = $this->scrollWidth;
        $t[] = $scroll;

        $div = new MDiv('', $t, 'm-texttable' );
        $div->width = $this->scrollWidth;

        $this->page->onLoad("miolo.page.controls.set('{$this->tableId}',new Miolo.TextTable('{$this->tableId}',{$this->zebra}, {$colWidth}));");
//        $this->page->addJsCode("var {$this->tableId} = null;");

        if ($this->codevalue)
        {
           foreach($this->codevalue as $code)
           {
               $this->page->onLoad($code);
           } 
        }

        return $this->generateLabel() . $div->generate();
    }
}
?>
