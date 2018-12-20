<?php
class MWindow extends MControl
{
    public $title;
    public $url;

    public function __construct($id, $options = array())
    {
        parent::__construct($id);
        $this->page->addScript('m_window.js');
        $this->page->addDojoRequire("miolo.Dialog");
        if (count($options)) 
        {
            foreach($options as $option=>$value)
            {
                $this->{$option} = $value;
            } 
        }
        $onload =     <<< HERE
var __winid = miolo.addWindow('$id');
miolo.getWindow('$id').setTitle('{$this->title}');
miolo.getWindow('$id').setHref('{$this->url}');

HERE;
        
        $this->page->onLoad($onload);
    }

    public function onLoad()
    {
//        $this->manager->page->addStyle('m_window.css'); 
        $this->page->onLoad("miolo.{$this->id} = new Miolo.window('{$this->id}', {".
              "title: \"{$this->title}\", ".
              "url: \"{$this->url}\", ". 
              "parent: {$this->parent}, ".
              "top: {$this->top}, ".
              ($this->left != '' ?  "left: \"{$this->left}\", " : "") . 
              "width: {$this->width}, ".
              ($this->height != '' ?  "height: \"{$this->height}\", " : "") . 
              "resizable: {$this->resizable}, ".
              "minimizable: {$this->minimizable}, ".
              "maximizable: {$this->maximizable}, ".
              "closable: {$this->closable}, ".
              "draggable: {$this->draggable}, ".
              "opacity: {$this->opacity}, ".
              "className: 'window', ".
//              "onload: {$this->onload}, ".
              "zIndex: {$this->zIndex} ".
//              "recenterModal: {$this->recenterModal}".
              "});");
    }

    public function setDefaults()
    {
        $this->title = '';
        $this->url = '';
        $this->parent = "document.getElementsByTagName(\"body\").item(0)";
        $this->top = 50;
        $this->bottom = 0;
        $this->left = NULL;
        $this->right = 0;
        $this->width = 400;
        $this->height = NULL;
        $this->maxWidth = $this->maxHeight = 0;
        $this->minWidth = 100;
        $this->minHeight = 20;
        $this->resizable = $this->minimizable = $this->maximizable = 'false';
        $this->closable = $this->draggable = 'true';
        $this->opacity = 1;
        $this->recenterModal = 'true';
        $this->onload = "miolo.{$this->id}.onload"; 
    }

    public function setStatusBar($control)
    {
        $str = $this->painter->generateToString($control);
        $html = addSlashes(str_replace("\n",'',$str));
        $this->page->onLoad("miolo.{$this->id}.setStatusBar(\"{$html}\");");
    }

    public function getLink($modal = false, $reload = false, $inset = false, $params = array())
    {
        $this->modal = $modal;
        $this->modalFlag = $modal ? 'true' : 'false';
        $this->reload = $reload ? 'true' : 'false';
        $base = $inset ? 'miolo' : 'miolo.windows.base.miolo';
        $urlParam = '';
        if (count($params))
        {
            $urlParam = implode(',',$params);
        }
//        $this->link = "javascript:miolo.{$this->id}.open({$this->modalFlag},{$this->reload});";
        $this->link = "javascript:{$base}.getWindow('{$this->id}').open({$this->modalFlag},{$this->reload});";
        return $this->link;
    }
}
?>