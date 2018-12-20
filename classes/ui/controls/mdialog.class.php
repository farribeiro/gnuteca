<?php
class MDialog extends MControl
{
    public $url;
    public $link;
    public $modal;
    public $modalFlag;
    public $top;
    public $left;
	public $reload;

    function __construct($id, $url, $modal = true, $top = 0, $left = 0, $reload = false )
    {
        parent::__construct($id);
        $this->manager->page->addScript('x/x_core.js');
        $this->manager->page->addScript('x/x_dom.js');
        $this->manager->page->addScript('x/x_event.js');
        $this->manager->page->addScript('x/x_drag.js');
        $this->manager->page->addScript('cpaint/cpaint2.inc.js');
        $this->manager->page->addScript('m_iframe.js');
        $this->manager->page->addScript('m_dialog.js');
        $this->manager->page->AddStyle('m_forms.css'); 
        $this->url = $url;
        $this->modal = $modal;
        $this->top = $top;
        $this->left = $left;  
        $this->modalFlag = $modal ? 'true' : 'false';
        $this->reload = $reload ? 'true' : 'false';
    }

    function getLink($params = array(), $reload = false)
    {
        $this->reload = $this->reload || $reload ? 'true' : 'false';
        $urlParam = '';
        if (count($params))
        {
            $urlParam = implode(',',$params);
        }
        $this->link = "javascript:miolo.Dialog('{$this->id}','{$this->url}',{$this->modalFlag}, {$this->top},{$this->left},'{$urlParam}',{$this->reload})";
        return $this->link;
    }
}
?>
