<?php
class MDragDropControl 
{
    protected $control;
    protected $options;
    public    $containerId;

    public function __construct($control)
    {
        $this->control = $control;
        $this->options = new MStringList();
    }

    public function addOption($option, $value)
    {
        $this->options->addValue($option, $value);
    }
}

class MDraggable extends MDragDropControl
{
    public function generate()
    {
        $js = "ddm_{$this->control->id} = new Draggable('{$this->control->id}'";
        $js .= $this->options->hasItems() ? ",{" . $this->options->getText(':', ',') . "}" : '';
        $js .= ");"; 
        return $js;
    }

    public function addRevertNotDropped()
    {
        $this->addOption("revert","function(element) {var dp =!Droppables.dropped; Droppables.dropped = false; return dp; }");       
    }

} 

class MDroppable extends MDragDropControl
{
    private $onDrop;

    public function generate()
    {
        $this->addOption("onDrop", "function(element, drop) {" . $this->onDrop . "ddm_{$this->containerId}.onDrop(element, drop); }");
        $js = "Droppables.add('{$this->control->id}'";
        $js .= $this->options->hasItems() ? ",{" . $this->options->getText(':', ',') . "}" : '';
        $js .= ");"; 
        return $js;
    }
 
    public function onDrop($jsCode)
    {
        $this->onDrop = $jsCode;
    }

} 

class MDragDrop extends MFormControl
{
    private $draggable = array();
    private $dropZone = array();

    public function addDraggable($control)
    {
        $control->containerId = $this->id;
        $this->draggable[] = $control;
    }

    public function addDropZone($control)
    {
        $control->containerId = $this->id;
        $this->dropZone[] = $control;
    }

    public function getValue()
    {
        parse_str($this->value, $v);
        return $v;
    }

    public function generate()
    {
        $this->page->addScript('scriptaculous/scriptaculous.js?load=effects,dragdrop');
        $this->page->addScript('m_dragdrop.js');
        $this->page->addJsCode("var ddm_{$this->id} = new Miolo.dragdrop('{$this->id}');");
        $this->page->onSubmit("ddm_{$this->id}.onSubmit()");
//        $this->manager->getTheme()->appendContent(new MHiddenField($this->id,''));
        foreach($this->draggable as $control)
        { 
           $this->page->onLoad($control->generate());
        }
        foreach($this->dropZone as $control)
        { 
           $this->page->onLoad($control->generate());
        }
        return $this->getRender('inputhidden');
    }
}
?>