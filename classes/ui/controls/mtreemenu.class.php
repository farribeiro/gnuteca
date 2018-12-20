<?php
class MTreeMenu extends MControl
{
    static  $order = 0;
    private $nOrder;
    private $template;
    private $action;
    private $target;
    private $items;
    private $jsItems;
    private $arrayItems;
    private $selectEvent = "";

    public function __construct($name = '', $template = 0, $action = '', $target = '_blank')
    {
        parent::__construct($name);
        $page = $this->page;
//        $this->addStyleFile('m_treemenu.css'); 
//        $page->addScript('tigra/tree.js');
        //        $page->addScript('tigra/tree_items.js');
        $this->items = NULL;
        $this->template = $template;
//        $page->addScript("tigra/tree{$this->template}_tpl.js");
        $page->addDojoRequire("dojo.data.ItemFileReadStore");
        $page->addDojoRequire("dijit.Tree");

        $this->action = $action;
        $this->target = $target;
        $this->selectEvent = '';
        $this->nOrder = MTreeMenu::$order++;
    }

    private function getJsItems($items)
    {
        if ($items != NULL)
        {
            foreach ($items as $it)
            {
                $i .= ($i != '' ? ',' : '') . "{description:'{$it[1]}',";
                $i .= "id: " . ($it[0] !== NULL ? "'{$it[0]}'" : ',0');

//                if ($this->action != '')
//                {
//                    $it[2] = str_replace('#', $it[0], $this->action);
//                }

//                $i .= ($it[2] != NULL ? ",'{$it[2]}'" : ',null') . ',';
                if(count($this->items[(int)$it[0]])){
                   $i .= ", children: [". $this->getJsItems($this->items[(int)$it[0]]) ."]";
                }
                $i .= "}";
            }

            return $i;
        }
    }

    public function setItemsFromArray($array, $key = '3', $data = '0,1,2')
    {
        $this->arrayItems = array();
        foreach ($array as $a)
        {
            $this->arrayItems[$a[0]] = $a;
        }

        $o = new MTreeArray($array, $key, $data);
        $this->items = $o->tree;
        $this->jsItems = "identifier: 'id', label: 'description', items: [" . $this->getJsItems($this->items['root']) ."]";
    }

    public function setItemsFromResult($result, $basename, $key = '0', $data = '1')
    {
		// for while, only for bi-dimensional results
		// column 0 - key used to group data
		// column 1 - data
        $o = new MTreeArray($result, $key, $data);
        $this->items['root'][] = array(0,$basename,'');
		$i = 0;
        foreach ($o->tree as $key => $tree)
        {
            $this->items[0][] = array(++$i,$key,'');
			$j = $i;
			foreach($tree as $t)
			{
                $this->items[$j][] = array(++$i,$t[0],'');
			}
        }
        $this->jsItems = "identifier: 'id', label: 'description', items: [" . $this->getJsItems($this->items['root']) ."]";
    }

    public function getItems()
    {
        return $this->arrayItems;
    }

    public function setSelectEvent($jsCode)
    {
//        $tree = $this->nOrder;
//        $this->selectEvent .= "trees[$tree].selectevent = function (n_id, item_id) { $jsCode };\n";
        $this->selectEvent .= $jsCode;
    }

    public function setEventHandler($eventHandler = '')
    {
        $form = $this->page->getFormId();
        if ($eventHandler != '')
            $this->attachEventHandler('click', $eventHandler);

        $this->selectEvent .= "miolo.doAjax('{$this->name}:click', item.id,'{$form}');\n";
    }

    public function getIconClass()
    {
        $form = $this->page->getFormId();
        $code = "function {$form}_{$this->name}_getIconClass(item,opened) {\n" . 
                "    var cls = (!item || this.model.mayHaveChildren(item)) ? opened ? 'dijitFolderOpened':'dijitFolderClosed' : 'dijitLeaf';\n". 
                "    return cls + this.layout;\n}\n";
        return $code;
    }

    public function getOnClick()
    {
        $form = $this->page->getFormId();
        $code = "function {$form}_{$this->name}_onClick(item,node) {\n" . 
                $this->selectEvent .
                "\n}\n";
        return $code;
    }

    public function generateInner()
    {
        if ($this->manager->isAjaxEvent) { return;}
        $tree = $this->nOrder;
        $page = $this->page;
        $form = $this->page->getFormId();
        $code =  "{$form}_{$this->name}_Store = new dojo.data.ItemFileReadStore({data: { $this->jsItems }});\n";
        $code .= "{$form}_{$this->name}_Model = new dijit.tree.ForestStoreModel({rootLabel: 'BaseControl', store: {$form}_{$this->name}_Store});\n";
        $code .= $this->getIconClass();
        $code .= $this->getOnClick();
        $this->page->addJsCode($code);
        $this->page->onload("new dijit.Tree({'model': {$form}_{$this->name}_Model,'getIconClass':{$form}_{$this->name}_getIconClass, 'onClick':{$form}_{$this->name}_onClick, 'layout':'{$this->template}',showRoot:false},dojo.byId('{$form}_{$this->name}'));");
        $this->inner = new MDiv("{$form}_{$this->name}");
    }

}
?>