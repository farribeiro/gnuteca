<?php
class MObjectGridColumn extends MGridColumn
{
    public $attribute; // attribute of object

    public function __construct($attribute,      $title = '',    $align = 'left', $nowrap = false, $width = 0, $visible = true,
                         $options = null, $order = false, $filter = false)
    {
        parent::__construct($title, $align, $nowrap, $width, $visible, $options, $order, $filter);
        $this->attribute = $attribute;
    }
}

class MObjectGridHyperlink extends MGridHyperlink
{
    public $attribute; // attribute of object

    public function __construct($attribute, $title = '', $href, $width = 0, $visible = true, $options = null, $order = false,
                         $filter = false)
    {
        parent::__construct($title, $href, $width, $visible, $options, $order, $filter);
        $this->attribute = $attribute;
    }
}

class MObjectGridControl extends MGridControl
{
    public $attribute; // attribute of object

    public function __construct(&$control, $attribute, $title = '', $alinhamento = null, $nowrap = false, $width = 0,
                         $visible = true)
    {
        parent::__construct($control, $title, $alinhamento, $nowrap, $width, $visible);
        $this->attribute = $attribute;
    }
}

class MObjectGridAction extends MGridAction
{

    public function __construct($type, $alt, $value, $href, $index = null, $enabled = true)
    {
        parent::__construct($type, $alt, $value, $href, $enabled, $index);
    }
}

class MObjectGrid extends MGrid
{
    /**
      ObjectGrid constructor
         $array - the object array
         $columns - array of columns objects
         $href - base url of this grid
         $pagelength - max number of rows to show (0 to show all)
    */

    protected $objArray;
    public function __construct($array, $columns, $href, $pagelength = 15, $index = 0)
    {
        parent::__construct(NULL, $columns, $href, $pagelength, $index);
        if ( $this->pageLength )
        {
            $this->pn = new MGridNavigator($this->pageLength, $this->rowCount, $this->getURL($this->filtered, $this->ordered), $this);
        }
        $this->objArray = $array;
        $this->data = array
            (
            );

        $this->rowCount = count($this->objArray);
    }

    public function generateData()
    {
        global $page, $state;

        if ($this->objArray == NULL)
            return;

        foreach ($this->objArray as $i => $row)
        {
            foreach ($this->columns as $k => $col)
            {
                eval("\$v = \$row->{$col->attribute};");
                $this->data[$i][$k] = $v;
            }
        }

        $this->orderby = $page->request('orderby');

        if ($this->ordered = isset($this->orderby))
        {
            $this->applyOrder($this->orderby);
            $state->set('orderby', $this->orderby, $this->name);
        }

        if ($this->getFiltered())
        {
            $this->applyFilter();
        }

        if ($this->pageLength)
        {
            $this->pn->setGridParameters($this->pageLength, $this->rowCount, $this->getURL($this->filtered, $this->ordered), $this);
            $this->data = $this->getPage();
        }
        else
            $this->pn = null;
    }

    public function callRowMethod()
    {
        if (isset($this->rowmethod))
        {
            $i = $this->currentRow;
            $row = $this->data[$i];
            call_user_func($this->rowmethod, $i, $row, $this->actions, $this->columns, $this->query);
        }
    }
}


?>
