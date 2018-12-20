<?
class MBaseGrid extends MControl
{
}

class MGridColumn extends MBaseGrid
{
    public $grid; // grid which this columns belongs to
    public $title; // column title
    public $footer; // column footer
    public $options; // array for mapping of data value to display value
    public $align; // column align - rigth, center, left
    public $nowrap; // column wrap/nowrap
    public $width; // column width in pixels or percent
    public $order; // column position on the grid
    public $value; // value at current row
    public $basecontrol; // base Control to render value
    public $control; // array of Control clonning of basecontrol
    public $index; // column index in the data array

    public function __construct($title = '',    $align = 'left', $nowrap = false,
                         $width = 0,     $visible = true, $options = null,
                         $order = false, $filter = false)
    {
        parent::__construct();
        $this->setClass('data');
        $this->visible = $visible;
        $this->title   = $title;
        $this->options = $options;
        $this->align   = $align;
        $this->nowrap  = $nowrap;
        $this->width   = $width;
        $this->order   = $order;
        $this->value   = '';
        $this->index   = 0;
        $this->footer  = null;
        $this->basecontrol = new MLabel('');
        $this->control = array();
    }

    public function generate()
    {
        $i = $this->grid->getCurrentRow();
        $row = $this->grid->data[$i];
        $this->control[$i] = clone $this->basecontrol; // clonning
        $value = $row[$this->index];
        $this->control[$i]->value = $value;

        if ($this->options)
        {
            $this->control[$i]->value = $this->options[$value];

            if ($this->grid->showid)
            {
                $this->control[$i]->value .= " ($value)";
            }
        }

        return $this->control[$i];
    }
}

class MGridHyperlink extends MGridColumn
{
    public $href; // link - replaces #?# with column's value
    public function __construct($title = '', $href, $width = 0, $visible = true, $options = null, $order = false,
                         $filter = false)
    {
        parent::__construct($title, null, false, $width, $visible, $options, $order, $filter);
        $this->align = 'left';
        $this->href = $href;
        $this->basecontrol = new MLink('', '', $href);
        $this->basecontrol->setClass('m-grid-column-link');
    }

    public function generate()
    {
        $i = $this->grid->currentRow;
        $row = $this->grid->data[$i];
        $this->control[$i] = clone $this->basecontrol; // clonning
        $value = $row[$this->index];
        $n = count($row);
        $href = $this->href;

        for ($r = 0; $r < $n; $r++)
        {
            $href = str_replace("#$r#", trim($row[$r]), $href);
        }

        $href = str_replace('#?#', $value, $href);
        $this->control[$i]->href = $href;
        $this->control[$i]->action = $href;
        $this->control[$i]->label = $value;
        return $this->control[$i];
    }
}

class MGridControl extends MGridColumn
{
    public $control; // web control for the column

    public function __construct($control, $title = '', $align = 'left', $nowrap = false, $width = 0, $visible = true)
    {
        parent::__construct($title, $align, $nowrap, $width, $visible);
        $this->basecontrol = $control;
    }

    public function generate()
    {
        $i = $this->grid->currentRow;
        $row = $this->grid->data[$i];
        $this->control[$i] = clone $this->basecontrol; // clonning
        $name = $this->control[$i]->getName();

        //se o nome não é um array acrescenta os colchetes para torná-lo um
        if (strpos($name, "[") === false && strpos($name, "]") === false)
        {
            $name .= "[$i]";
        }
        else
        {
            //posição do caracter identificador, que será substituído
            $pos = strpos($name, '%');

            //se o nome está de acordo com as regras de nomenclatura do grid. Numero da linha entre %'s
            if (!$pos === false)
            {
                $rowNumber = substr($name, $pos + 1, -2);
                $name = str_replace("%$rowNumber%", trim($row[$rowNumber]), $name);
            }
        }

        $this->control[$i]->setName($name);
        $this->control[$i]->setId($name);
        $n = count($row);

        for ($r = 0; $r < $n; $r++)
        {
            $this->control[$i]->setValue(str_replace("%$r%", trim($row[$r]), $this->control[$i]->getValue()));
        }

        return $this->control[$i];
    }
}

class MGridAction extends MBaseGrid
{
    public $grid; // grid which this action belongs to
    public $type; // "text", "image", "select" or "none"
    public $alt; // image alt
    public $value; // image/text label for on
    public $valueoff; // image/text label for off
    public $href; // link pattern - replaces
    // #n# with value of column "n"
    // %n% with urlencode(value) of column "n"
    // $id with value of column "index"
    public $index; // deprecated
    public $enabled;

    public function __construct($grid, $type, $alt, $value, $href, $enabled = true, $index = null)
    {
        parent::__construct();
        $this->grid = $grid;
        $this->type = $type;
        $this->alt = $alt;

        if (is_array($value))
        {
            $this->value = $value[0];
            $this->valueoff = $value[1];
        }
        else
        {
            $this->value = $this->valueoff = $value;
        }

        $this->href = $href;
        $this->index = $index;
        $this->enabled = $enabled;
    }

    public function enable()
    {
        $this->enabled = true;
    }

    public function disable()
    {
        $this->enabled = false;
    }

    public function generateLink($row)
    {
        $index = $row[$this->grid->index];
        $href = ereg_replace('\$id', $index, $this->href);
        $n = count($row);

        // substitute positional parameters
        for ($r = 0; $r < $n; $r++)
        {
            if( is_object($row[$r]) && method_exists($row[$r], 'generate'))
            {
                $row[$r] = $row[$r]->generate( );
            }
            $href = str_replace("%$r%", urlencode($row[$r]), $href);
            $href = str_replace("#$r#", addslashes($row[$r]), $href);
        }

        return (($this->grid->linktype == 'hyperlink') ? 'go:' : '') . $href;
    }

    public function generate()
    {
    }

    public function setTarget($target)
    {
        $this->target = $target;
    }

}

class MGridActionIcon extends MGridAction
{
    public $path;

    public function __construct($grid, $value, $href, $alt = null)
    {
        parent::__construct($grid, 'image', $alt, $value, $href);
        $this->path[true] = $this->manager->getUI()->getIcon("{$this->value}-on");
        $this->path[false] = $this->manager->getUI()->getIcon("{$this->value}-off");
    }

    public function generate()
    {
        $path = $this->path[$this->enabled];
        $class = "m-grid-action-icon";
        if ($this->enabled)
        {
            $row = $this->grid->data[$this->grid->currentRow];
            $href = $this->generateLink($row);
            $img = $this->grid->getImage($this->value);
            $control = new MImageButton('', $this->alt, $href, $path);
        }
        else
        {
            $control = new MImage('', $this->alt, $path);
        }
        $control->setClass($class);
        return $control;
    }
}

class MGridActionText extends MGridAction
{

    public function __construct($grid, $value, $href)
    {
        parent::__construct($grid, 'text', null, $value, $href);
        $this->attributes = "width=\"20\" align=\"center\"";
    }

    public function generate()
    {
        $value = $this->value;

        if ($this->enabled)
        {
            $row = $this->grid->data[$this->grid->currentRow];
            $n = count($row);

            for ($r = 0; $r < $n; $r++)
            {
                $value = str_replace("%$r%", $row[$r], $value);
            }

            $href = $this->generateLink($row);
            $control = ($this->grid->linktype == 'hyperlink') ? new MLink('', $value, $href) : new MLink('', $value, $href);
            $control->setClass('m-grid-link');
        }
        else
        {
            $control = new MSpan('', $value, 'm-grid-link-disable');
        }

        return $control;
    }
}

class MGridActionDefault extends MGridActionText
{

    public function generate()
    {
        if ($this->href == '#')
		{
			return '&nbsp;&nbsp;';
		}
		else
		{
			$control = parent::generate();
		    $control->setClass('m-grid-link-action-default',false);
            return substr(strtoupper($control->href), 0, 7) == 'HTTP://' || substr(strtoupper($control->href), 0, 8) == 'HTTPS://' ? "javascript:miolo.linkButton('{$control->href}','','');" : $control->href;
        }
    }
}

class MGridActionDetail extends MGridActionIcon
{
    public function generate()
    {
        $class = "m-grid-action-icon-detail";
        $row = $this->grid->data[$this->grid->currentRow];
        $n = count($row);

        $href = $this->href;
        for ($r = 0; $r < $n; $r++)
        {
            $href = str_replace("%$r%", $row[$r], $href);
        }
        $href = str_replace("%r%", $this->grid->currentRow, $href);
        $hrefOn = str_replace("%s%", '1', $href);
        $hrefOff = str_replace("%s%", '0', $href);
        $controlOn = new MImage('', '', $this->path[true]);
        $controlOff = new MImage('', '', $this->path[false]);
        $controlOn->addAttribute('onClick',$hrefOn);
        $controlOn->setClass($class);
        $controlOff->addAttribute('onClick',$hrefOff);
        $controlOff->setClass($class);
        $control = new MDiv('',array($controlOn, $controlOff),'detail');
        return $control;
    }
}

class MGridActionSelect extends MGridAction
{

    public function __construct($grid, $index = 0)
    {
        parent::__construct($grid, 'select', null, null, null, true, $index);
    }

    public function generate()
    {
        $i = $this->grid->currentRow;
        $row = $this->grid->data[$i];
        $index = $row[$this->grid->index];
        $control = new MCheckBox("select".$this->grid->name."[$i]", $index, '');
        $control->addAttribute('onclick', "javascript:miolo.grid.check(this,'".$this->grid->name."[$i]"."');");
        return $control;
    }
}

class MGridHeaderLink extends MLink
{
    public function __construct($id, $label, $href)
    {
        parent::__construct($id, "[$label]", $href);
        $this->setClass('m-grid-link');
    }
}

class MGridFilter extends MBaseGrid
{
    public $grid; // grid which this filter belongs to
    public $type; // "text", "selection"
    public $label; // image alt
    public $value; // image/text label for on/off
    public $index; // column index in the data array
    public $enabled;
    public $control;

    public function __construct($grid, $type, $label, $value, $index, $enabled = false)
    {
        parent::__construct();
        $this->grid = $grid;
        $this->type = $type;
        $this->label = $label;
        $this->index = $index;
        $this->enabled = $enabled;
        $this->control = null;
    }

    public function generate()
    {
        if ($this->enabled)
        {
            $array[] = new MSpan('', $this->label . '&nbsp;', 'm-grid-font');
            $this->control->setValue(($this->grid->getFiltered()) ? $this->value : NULL);
            $array[] = $this->control->generate();
            $array[] = '&nbsp;&nbsp;&nbsp;';
        }
        return $array;
    }
}

class MGridFilterText extends MGridFilter
{
    public function __construct($grid, $label, $value = '', $index = 0, $enabled = false)
    {
        parent::__construct($grid, 'text', $label, $value, $index, $enabled);
        $this->control = new MTextField("m-grid-filter-text-$index", $value, $label, 20);
        $this->value = $this->page->request($this->control->name) ? $this->page->request($this->control->name) : $value;
    }
}

class MGridFilterSelection extends MGridFilter
{

    public function __construct($grid,      $label, $options = array(
        ),               $index = 0, $enabled = false)
    {
        parent::__construct($grid, 'selection', $label, '', $index, $enabled);
        $this->control = new MSelection("m-grid-filter-sel-$index", '', $label, $options);
        $this->value = $this->page->request($this->control->name) ? $this->page->request($this->control->name) : $value;
    }
}

class MGridFilterControl extends MGridFilter
{

    public function __construct($grid, &$control, $type = 'text', $index = 0, $enabled = false)
    {
        parent::__construct($grid, $type, $control->label, $control->value, $index, $enabled);
        $this->control = $control;
        $this->value = $this->page->request(
                           $this->control->name) ? $this->page->request($this->control->name) : $control->value;
    }
}

class MGrid extends MBaseGrid
{
    public $title; // table display title
    public $filters; // array of grid filter controls
    public $filtered; // is filtered?
    public $filter; // show/hide filters
    public $orderby; // base column to sort
    public $ordered; // is ordered?
    public $data; // table data cells
    public $actions; // array with actions controls
    public $select; // a column for select action
    public $showid; // show ids or not?
    public $columns; // array with columns
    public $icons; // action icons
    public $errors; // array of errors
    public $pageLength; // max number of rows to show - 0 to all rows
    public $rowCount; // total number of rows
    public $href; // grid url
    public $pn; // gridnavigator
    public $headerLinks; // array of headerlinks
    public $linktype; // hyperlink or linkbutton (forced post)
    public $width; // table width for the grid
    public $rowmethod; // method to execute (callback) at each row
    public $index; // the column to act as index of grid
    public $controls;
    public $emptyMsg;
    public $currentRow; // index of row to renderize
    public $box;
    public $selecteds;
    public $allSelecteds;
    public $pageNumber;
    public $prevPage;
    public $name;
    public $css;
    public $footer;
    public $hasDetail;
	var $actionDefault;
    public $alternateColors;
    public $buttonSelectClass;
    protected $isShowHeaders= true;
    protected $scrollable   = false;
    protected $scrollWidth  = '99%';
    protected $scrollHeight = '99%';

/*
      Grid constructor
         $data - the data array
         $columns - array of columns objects
         $href - base url of this grid
         $pageLength - max number of rows to show (0 to show all)
*/

    public function __construct($data, $columns, $href, $pageLength = 15, $index = 0, $name = '', $useSelecteds = true, $useNavigator = true)
    {
        parent::__construct(NULL);
        $this->setName($name);
//        $this->addStyleFile('m_grids.css');
        $this->setColumns($columns);
        $this->href = $href;
        $this->pageLength = $pageLength;
        $this->headerLinks = array();
        $this->width = '';
        $this->setLinkType('linkbutton');
        $this->box = new MBox('', 'backContext', '');
        $this->rowmethod = null;
        $this->data = $data;
        $this->index = $index;
        $this->emptyMsg = 'Nenhum registro encontrado!';
        $this->data = $data;
        $this->rowCount = count($this->data);
        $this->controls = array();
        $this->select = NULL;
        $this->hasDetail = false;

        if (urldecode($this->page->request('gridName')) == $this->name)
        {
            $this->page->setViewState('pn_page', $this->page->request('pn_page'), $this->name);
        }
        $this->pageNumber = MUtil::NVL($this->page->getViewState('pn_page', $this->name),'1');
        $this->prevPage = MUtil::NVL($this->page->getViewState('grid_page', $this->name),'1');

        $this->page->setViewState('grid_page', $this->pageNumber, $this->name);
        $this->selecteds = array();
        $this->allSelecteds = array();
		$this->actionDefault = new MGridActionDefault($this, '&nbsp;&nbsp;', NULL);
        $this->alternateColors = true;
        $this->buttonSelectClass = 'linkbtn';
        $this->currentRow = 0;

        $this->setUseSelecteds($useSelecteds);

//        if (!$useNavigator) {
          $this->handlerSelecteds();
//        }
        $this->page->addScript('m_grid.js');

//        $this->css = file_get_contents($this->manager->getTheme()->getPath() . '/m_grids.css');
    }

    public function setShowHeaders( $show=true )
    {
        $this->isShowHeaders = $show;
    }

    public function showHeaders( )
    {
        return $this->isShowHeaders;
    }

    public function setCurrentPage($pageNumber)
    {
        $this->pageNumber = $pageNumber;
        $this->page->setViewState('grid_page', $pageNumber, $this->name);
        $this->prevPage = MUtil::NVL($this->page->setViewState('grid_page', $this->name),'1');
    }

    public function getURL($filter = false, $order = false, $item = '')
    {
        $url = $this->href;
		$url = eregi_replace("&pn_page=(.*)[^&]","",$url);
		$url = eregi_replace("&__filter=(.*)[^&]","",$url);
    	$url = eregi_replace("&orderby=(.*)[^&]","",$url);
        $url .= ($filter) ? "&__filter=1" : "&__filter=0";

        if ($order)
            $url .= "&orderby={$this->orderby}";

        if ($item)
            $url .= $item;

        return $url;
    }

    public function setTitle($title)
    {
        $this->caption = $this->title = $title;
    }

    public function setPageLength($pageLength)
    {
        $this->pageLength = $pageLength;
    }

    public function getPageLength()
    {
        return $this->pageLength;
    }

    public function setFooter($footer)
    {
        $this->footer = $footer;
    }

    public function setColumns($columns)
    {
        $this->columns = array();

        if (!is_array($columns))
            $columns = array($columns);

        foreach ($columns as $k => $c)
        {
            $this->columns[$k] = $c;
            $this->columns[$k]->index = $k;
            $this->columns[$k]->grid = $this;
        }
    }

    public function setLinkType($linktype)
    {
        $this->linktype = strtolower($linktype);
    }

    public function setControls($controls)
    {
        if (!is_array($controls))
        {
            $controls = array($controls);
        }
        $this->controls = array_merge($this->controls, $controls);
    }

    public function setButtons($aButtons) //backward compatibility
    {
        $this->setControls($aButtons);
    }

    public function setWidth($width)
    {
        $this->width = $width;
    }

    public function setIndex($index)
    {
        $this->index = $index;
    }

    public function setRowMethod($class, $method)
    {
        $this->rowmethod = array($class,$method);
    }

    public function setIsScrollable($scrollable=true, $width='99%', $height='99%')
    {
        $this->scrollable   = $scrollable;
        $this->scrollWidth  = $width;
        $this->scrollHeight = $height;
    }

    public function setScrollWidth($width='99%')
    {
        $this->scrollWidth = $width;
    }

    public function setScrollHeight($height='99%')
    {
        $this->scrollHeight = $height;
    }

    public function headerLink($id, $label, $href)
    {
        $this->headerLinks[$id] = new MGridHeaderLink($id, $label, $href);
    }

    public function setColumnAttr($col, $attr, $value)
    {
        $this->columns[$col]->$attr = $value;
    }

    public function setButtonSelectClass($class='')
    {
        $this->buttonSelectClass = $class;
    }

    public function setAlternate($status = true)
    {
        $this->alternateColors = $status;
    }

    public function setData($data)
    {
        $this->data = $data;
        $this->rowCount = count($this->data);
    }

    public function getData()
    {
        return $this->data;
    }

    public function getDataValue($row, $col)
    {
        return $this->data[$row][$col];
    }

    public function getPage()
    {
        if ( count($this->data) && is_array($this->data) )
        {
            return array_slice($this->data, $this->pn->idxFirst, $this->pn->gridCount);
        }
    }

    public function getPageNumber()
    {
        return $this->pageNumber;
    }

    public function getPrevPage()
    {
        return $this->prevPage;
    }

    public function getCurrentRow()
    {
        return $this->currentRow;
    }

    public function setActionDefault($href)
    {
        $this->actionDefault = new MGridActionDefault($this, '&nbsp;&nbsp;', $href);
    }

	function addActionSelect()
    {
        $this->select = new MGridActionSelect($this);
    }

    public function addActionIcon($alt, $icon, $href, $index = 0)
    {
        if ($p = strpos($icon,'.')) $icon = substr($icon,0,$p);
        $this->actions[] = new MGridActionIcon($this, $icon, $href, $alt);
    }

    public function addActionText($alt, $text, $href, $index = 0)
    {
        $this->actions[] = new MGridActionText($this, $text, $href);
    }

    public function addActionUpdate($href)
    {
//        $this->addActionIcon('Editar', array('button_edit.png', 'button_noedit.png'), $href);
        $this->addActionIcon('Editar', 'edit', $href);
    }

    public function addActionDelete($href)
    {
//        $this->addActionIcon('Excluir', array('button_drop.png', 'button_noempty.png'), $href);
        $this->addActionIcon('Excluir', 'delete', $href);
    }

    public function addActionDetail($href)
    {
        $this->hasDetail = true;
        $this->actions[] = new MGridActionDetail($this, 'detail', $href);
    }

    public function addFilterSelection($index, $label, $options, $value = '')
    {
        $f = new MGridFilterSelection($this, $label, $options, $index, $this->getFilter());
        $this->filters[$index] = $f;
    }

    public function addFilterText($index, $label, $value = '')
    {
        $f = new MGridFilterText($this, $label, $value, $index, $this->getFilter());
        $this->filters[$index] = $f;
    }

    public function addFilterControl($index, $control, $type = 'text')
    {
        $this->filters[$index] = new MGridFilterControl($this, $control, $type, $index, $this->getFilter());
    }

    public function getFilterValue($index)
    {
        return $this->filters[$index]->value;
    }

    public function getFilterControl($index)
    {
        return $this->filters[$index]->control;
    }

    public function setFiltered($value = false)
    {
        $this->filtered = $value;
    }

    public function getFiltered()
    {
        if (($f = $this->page->request('__filter')) != '')
        {
            $this->filtered = ($f == '1');
        }
        return $this->filtered;
    }

    public function getFilter()
    {
        return $this->filter;
    }

    public function setFilter($status)
    {
        $this->filter = $status;

        if ($this->filters)
        {
            foreach ($this->filters as $k => $f)
            {
                $this->filters[$k]->enabled = $status;
            }
        }
    }

    public function applyFilter()
    {
        if ($this->filters)
        {
            foreach ($this->filters as $f)
            {
                $value[$f->index] = $f->value;
            }

            foreach ($this->data as $row)
            {
                $ok = true;

                foreach ($value as $k => $v)
                {
                    $n = strlen(trim($v));
                    $ok = $ok && (strncmp($row[$k], $v, $n) == 0);
                }

                if ($ok)
                    $data[] = $row;
            }
            $this->data = $data;
            $this->rowCount = count($this->data);
        }
    }

    public function applyOrder($column)
    {
        $p = $this->columns[$column]->index;
        $n = count($this->data[0]);

        foreach ($this->data as $key => $row)
        {
            for ($i = 0; $i < $n; $i++)
                $arr[$i][$key] = $row[$i];
        }

        $sortcols = "\$arr[$p]";

        for ($i = 0; $i < $n; $i++)
            if ($i != $p)
                $sortcols .= ",\$arr[$i]";

        eval("array_multisort({$sortcols}, SORT_ASC);");
        $this->data = array();

        for ($i = 0; $i < $n; $i++)
        {
            foreach ($arr[$i] as $key => $row)
                $this->data[$key][$i] = $row;
        }
    }

    public function addError($err)
    {
        if ($err)
        {
            if (is_array($err))
            {
                if ($this->errors)
                {
                    $this->errors = array_merge($this->errors, $err);
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

    public function showID($state)
    {
        $this->showid = $state;
    }

    public function setClose($action)
    {
        $this->box->setClose($action);
    }

    public function setSelecteds($s)
    {
        $selecteds = $this->page->getViewState("selecteds",$this->name);
        $selecteds[$this->pageNumber] = $s;
        $this->page->setViewState("useselecteds", true,$this->name);
        $this->page->setViewState("selecteds",$selecteds,$this->name);
    }

    public function setUseSelecteds($opt)
    {
        $this->page->setViewState("useselecteds", $opt,$this->name);
    }

    public function handlerSelecteds()
    {
        $selecteds = $this->page->getViewState("selecteds",$this->name);
        $useSelecteds = $this->page->getViewState("useselecteds",$this->name);
/*
        if (urldecode($this->page->request('gridName')) == $this->name)
        {
            $this->page->setViewState("pn_page", $this->page->request('pn_page'),$this->name);
        }
        $this->pageNumber = MUtil::NVL($this->page->getViewState("pn_page",$this->name),1);
        $this->prevPage   = MUtil::NVL($this->page->getViewState("grid_page",$this->name),1);
*/
        $this->selecteds = array();

        if ($useSelecteds)
        {
            $selecteds[$this->prevPage] = array();
            if ($select = $this->page->request('select'.$this->name))
            {
                foreach($select as $k=>$v)
                {
                    $selecteds[$this->prevPage][] = $k;
                }
            }
            if (is_array($selecteds[$this->pageNumber]))
            {
                $this->selecteds = $selecteds[$this->pageNumber];
            }
            $this->allSelecteds = $selecteds;
        }

        $this->page->setViewState("grid_page", $this->pageNumber,$this->name);

        $this->page->setViewState("useselecteds", $useSelecteds,$this->name);
        $this->page->setViewState("selecteds",$selecteds,$this->name);
    }

    public function clearSelecteds()
    {
        $this->page->setViewState("selecteds",NULL,$this->name);
    }

    public function generateTitle()
    {
        if ($this->caption != '')
        {
            $this->box->setCaption($this->caption);
            return $this->box->boxTitle->generate();
        }
    }

    private function generateNavigationDiv()
    {
        $array[0] = $this->pn->getPageFirst();
        $array[0]->_AddStyle('float', 'left');
        $array[1] = $this->pn->getPagePrev();
        $array[1]->_AddStyle('float', 'left');
        $array[2] = $this->pn->getPageRange();
        $array[2]->_AddStyle('float', 'left');
        $array[3] = $this->pn->getPageNext();
        $array[3]->_AddStyle('float', 'left');
        $array[4] = $this->pn->getPageLast();
        $array[4]->_AddStyle('float', 'left');
        $d = new MDiv('', $array, 'm-pagenavigator');
        $d->addStyle('float', 'right');
        return $d;
    }

    public function generateNavigationHeader()
    {
        if (!$this->pn)
        {
            return null;
        }

        $links = $this->pn->getPageLinks();

        foreach ($links as $link)
        {
            $link->float = 'left';
        }

        $d1 = new MDiv('', $links);
        $d1->addStyle('float', 'left');
        $d2 = $this->generateNavigationDiv();
        $d = new MDiv('', array($d1, $d2), 'm-grid-navigation');
        return $d;
    }

    public function generateNavigationFooter()
    {
        if (!$this->pn)
        {
            return null;
        }

        $links = $this->pn->getPageLinks();

        foreach ($links as $link)
        {
            $link->float = 'left';
        }

        $d1 = new MDiv('', $links);
        $d1->addStyle('float', 'left');
        $d2 = $this->generateNavigationDiv();
        $d = new MDiv('', array($d1, $d2), 'm-grid-navigation');
        return $d;
    }

    public function generateLinks()
    {
        if (!count($this->headerLinks))
        {
            return NULL;
        }

        foreach ($this->headerLinks as $link)
        {
            $link->float = 'left';
        }

        $div = new MDiv('', $this->headerLinks, 'm-grid-header-link');
        return $div;
    }

    public function generateControls()
    {
        if (!count($this->controls))
        {
            return NULL;
        }

        $i = 0;

        foreach ($this->controls as $c)
        {
            $array[$i++] = $c->generate();
            $array[$i++] = '&nbsp;&nbsp;';
        }

        return new MDiv('', $array, 'm-grid-controls');
    }

    public function generateFilter()
    {
        if (!$this->filter)
        {
            return null;
        }

        foreach ($this->filters as $k => $f)
        {
            $array[] = $f->generate();
        }

        $img = new MImageButton('', 'Filtrar', $this->getURL(true, $this->ordered), "/images/button_select.png");
        $array[] = $img->generate();
        $array[] = '&nbsp;&nbsp;';
        $img = new MImageButton('', 'Remover filtro', $this->getURL(false, $this->ordered), "/images/button_browse.png");
        $array[] = $img->generate();
        return new MDiv('', $array, 'm-grid-filter');
    }

    public function hasErrors()
    {
        return count($this->errors);
    }

    public function generateErrors()
    {
        global $MIOLO;

        $caption = ('Erros');

        $t = new MSimpleTable('');
        $t->setAttributes(
            "class=\"m-prompt-box-error\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\" width=\"100%\"  border=\"0\"");
        $t->attributes['cell'][0][0] = "colspan=\"2\" class=\"m-prompt-box-error-title\"";
        $t->cell[0][0] = $caption;
        $t->attributes['cell'][1][0] = "valign=\"top\" width=\"60\"";
        $t->cell[1][0] = new ImageForm('', '', '/images/error.gif');
        $t->attributes['cell'][1][1] = "class=\"m-prompt-box-error-text\"";
        $leftmargin = '&nbsp;&nbsp;&nbsp;&nbsp;';

        foreach ($this->errors as $e)
        {
            $msg .= $leftmargin . "-&nbsp;$e<br>";
        }

        $t->cell[1][1] = $msg;
        return $t;
    }

    public function generateHeader()
    {
        $header[] = $this->generateFilter();
        if ($this->data)
        {
            $header[] = $this->generateNavigationHeader();
        }
        $header[] = $this->generateLinks();

        return $header;
    }

    public function generateColumnsHeading(&$tbl)
    {
        $spanClass = ''; // adjusted via javascript
        $p = 0;
        $this->page->onLoad("miolo.grid.ajustSelect('linkbtn');");
        $this->page->onLoad("miolo.grid.ajustTHead();");
        $tbl->setColGroup($p);
        $span = new MSpan('','&nbsp;',$this->buttonSelectClass);
        $tbl->setHead($p, $span );
        $tbl->setHeadClass($p++, 'btn');
        if ($n = count($this->actions))
        {
            $tbl->setColGroup($p,"span={$n}");
            $tbl->setHead($p,new MSpan('',_M('Action'),$spanClass));
            $tbl->setHeadAttribute($p,'colspan',$n);
            $tbl->setHeadClass($p++,'action');
        }
        if ($this->select != NULL)
        {
            $rowCount = count($this->data);
            $this->page->onLoad("miolo.grid.checkEachRow($rowCount,'".$this->name."');");
            $tbl->setColGroup($p);
            $check = new MCheckBox("chkAll", 'chkAction', '');
            $check->addAttribute('onclick',"javascript:miolo.grid.checkAll(this,$rowCount,'".$this->name."');");
            $check->_addStyle('padding','0px');
            $tbl->setHead($p,new MSpan('',$check,'select'));
            $tbl->setHeadClass($p++,'select');
        }

        // generate column headings
        $tbl->setColGroup($p); $c = 0;
        $last = count($this->columns) - 1;
        foreach ($this->columns as $k => $col)
        {
            if ((!$col->visible) || (!$col->title))
            {
                continue;
            }

            if ($col->order)
            {
                $this->orderby = $k;
                $link = new MLinkButton('', $col->title, $this->getURL($this->filtered, true));
                $link->setClass('order');
                $colTitle = new MSpan('',$link,$spanClass);
                $tbl->setHeadClass($p+$c,'order');
            }
            else
            {
                $colTitle = new MSpan('',$col->title,$spanClass);
                $tbl->setHeadClass($p+$k,'data');
            }

            if (($col->width))
            {
                $attr =  ($k != $last) ? " width=\"$col->width\"" : " width=\"100%\"";
            }
            else
            {
                // scrollable tables need col width
                if( $this->scrollable )
                {
                    $this->manager->logMessage( _M("[WARNING] Using scrollable table, it's necessary to inform column width. ") );
                }
            }

            $tbl->setColGroupCol($p,$c,$attr);
            $tbl->setHead($p+$c++,$colTitle);
        }
    }

    // This method corrects a problem when using scrollable table having
    // only one or few records. Adds a colspaned row.
    public function correctActionColSpan($tbl)
    {
        if ($cntActions = count( $this->actions) )
        {
            $tbl->attributes['cell'][0][0] = "width=\"15\" align=\"left\" colspan=$cntActions";
            $tbl->cell[0][0] = '';
        }
    }

    public function generateActions(&$tbl)
    {
        $i = $this->currentRow;

        if ($this->hasDetail)
        {
           $i += $this->currentRow;
        }
        $c = 0; // colNumber

        $spanClass = ($this->select != NULL) ? ' tall' : '';
        $control = new MSpan('', '&nbsp;');
        if ($this->actionDefault->href)
        {
            $control->addAttribute('onclick',$this->actionDefault->generate());
        }
        $control->setClass($this->buttonSelectClass,false);
        $tbl->setCell($i, $c, $control);
        $tbl->setCellClass($i, $c, 'btn');

        if ($this->hasDetail)
        {
           $tbl->setCell($i+1,$c,new MDiv('ddetail' . $this->currentRow, NULL));
           $tbl->setCellClass($i+1,$c,'action-default');
        }
        $c++;
        if ($n = count($this->actions))
        {
            // generate action links
            while ($c < ($n + 1))
            {
				$action = $this->actions[$c-1];
                $tbl->setCell($i,$c,$action->generate(),$action->attributes());
                if ($this->hasDetail)
                {
                    $tbl->setCell($i+1,$c,new MDiv('adetail' . $this->currentRow, NULL));
                }
                $tbl->setCellClass($i,$c,$c == ($n) ? 'data action' : 'action');
                $c++;
            }
        }

        if ($this->select != NULL)
        {
            $tbl->setRowAttribute($i,'id',"row".$this->name."[{$this->currentRow}]");
            $tbl->setCellClass($i,$c,'data select');
            $select = $this->select->generate();
            $select->checked = (array_search($i, $this->selecteds) !== false);
            $tbl->cell[$i][$c] = $select;
            if ($this->hasDetail)
            {
                $tbl->setCell($i+1,$c,new MDiv('sdetail' . $this->currentRow, NULL));
            }
        }
    }

    public function generateColumnsControls()
    {
        foreach ($this->columns as $k => $col)
        {
            $col->generate();
        }
    }

    public function generateColumns(&$tbl)
    {
        $i = $this->currentRow;
        if ($this->hasDetail)
        {
           $i += $this->currentRow;
        }
        $p = count($this->actions) + 1;

        if ($this->select != NULL)
            $p++;

        $colspan = 0;
        $first = $p;

        foreach ($this->columns as $k => $col)
        {
            if ((!$col->title) || (!$col->visible))
            {
                continue;
            }

            ++$colspan;

            $control = $col->control[$this->currentRow];
            $attr = "";

            if ($col->nowrap)
            {
                $tbl->setCellAttribute($i,$p,"nowrap");
            }

            if ($col->width)
            {
                $tbl->setCellAttribute($i,$p,"width",$col->width);
            }

            if ($col->align)
            {
                $tbl->setCellAttribute($i,$p,"align",$col->align);
            }
            $class = $col->getClass();
            $tbl->setCellClass($i,$p,$class == '' ? 'data' : $class);
            $tbl->setCell($i,$p++,$control);
        }
        if ($this->hasDetail)
        {
            $tbl->setCell(++$i,$first,new MDiv('detail' . $this->currentRow, NULL));
            $tbl->setCellAttribute($i,$first,"colspan",$colspan);
            $tbl->setRowClass($i,'detail');
        }
    }

    public function generateEmptyMsg()
    {
        $div = new MDiv('', $this->emptyMsg, 'm-grid-attention');
        return $div;
    }

    public function generateData()
    {
        if (!$this->data)
        {
            return;
        }

        $this->orderby = $this->page->request('orderby');

        if ($this->ordered = isset($this->orderby))
        {
            $this->applyOrder($this->orderby);
            $this->page->setViewState('orderby', $this->orderby, $this->name);
        }

        if ($this->getFiltered())
        {
            $this->applyFilter();
        }
        if ($this->pageLength)
        {
            $this->pn = new MGridNavigator($this->pageLength, $this->rowCount,
                                          $this->getURL($this->filtered, $this->ordered), $this);
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
            call_user_func($this->rowmethod, $i, $row, $this->actions, $this->columns);
        }
    }

    public function generateBody()
    {
        global $MIOLO, $SCRIPT_NAME;

        if ($this->hasErrors())
        {
            $this->generateErrors();
        }

        $tblData = new MSimpleTable('', "cellspacing=\"0\" cellpadding=\"0\" border=\"0\" width=\"100%\" class=\"m-grid-body\"");
        $this->generateColumnsHeading($tblData);

        if ($this->data)
        {
            // generate data rows
            $i = 0;

            foreach ($this->data as $row) // foreach row
            {
                $this->currentRow = $i;
                $rowId = ($i % 2) + 1;
                $rowClass = $this->alternateColors ? "row$rowId" : "row0";
                $c = $this->hasDetail ? $i+$this->currentRow : $i;
                $i++;
                $tblData->setRowClass($c,$rowClass);
                $this->generateColumnsControls();
                $this->callRowMethod();
                $this->generateActions($tblData);
                $this->generateColumns($tblData);
            } // end foreach row
        }// end if

        $tblData->setRowAttribute(0, "id", 'tbody'.$this->id.'first');

        if( $this->scrollable )
        {
            $bodyHeader = new MDiv('head'.$this->id, $tblDataHeader, 'm-grid-head', 'style="'.
                                                       'width:'.$this->scrollWidth.';'.
                                                       'overflow-x:hidden;"');
            $body = new MDiv('body'.$this->id, $tblData,'m-grid-body','style="'.
                                                       'width:'.$this->scrollWidth.';'.
                                                       'height:'.$this->scrollHeight.';'.
                                                       'overflow:auto;" '
                                                    );
            $body = new MDiv('', array($bodyHeader, $body) );
        }
        else
        {
            $body = $tblData;
        }

        return $body;
    }

    public function generateFooter()
    {
        $footer = is_array($this->footer) ? $this->footer : array($this->footer);

        if ( ! $this->data )
        {
            $footer[] = $this->generateEmptyMsg();
        }

        if ( $this->data )
        {
            $footer[] = $this->generateNavigationFooter();
        }

        $footer[] = $this->generateControls();

        return $footer;
    }

    public function getImage($src)
    {
        $url = $this->icons[$src];
        if (!$url)
        {
            if (substr($src, 0, 1) == '/' || substr($src, 0, 5) == 'http:' || substr($src, 0, 6) == 'https:')
            {
                $url = $src;
            }
            else
            {
                $file = $this->manager->getConf('home.themes')  . '/' . $this->manager->getConf('theme.main')  . '/images/' . $src;
                if (file_exists($file))
                {
                    $url = $this->manager->getUI()->getImageTheme($this->manager->getConf('theme.main'), $src);
                }
                else
                {
                    $url = $this->manager->getUI()->getImage('', $src);
                }
            }

            $this->icons[$src] = $url;
        }
        return $url;
    }

    public function generate()
    {
        $this->generateData();
        $header = $this->painter->generateToString($this->generateHeader());
        $title  = $this->painter->generateToString($this->generateTitle());
        $body   = $this->painter->generateToString($this->generateBody());
        $footer = $this->painter->generateToString($this->generateFooter());
        $f = new MDiv('', array($title, $header, $body, $footer), 'm-grid-box');
        if ($this->width != '')
        {
            $f->addStyle('width', $this->width);
        }
        return $f->generate();
    }
}
?>
