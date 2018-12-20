<?php
class MModuleHeader extends MControl
{
    public $object;
    public $target;

    public function __construct($object, $target)
    {
        parent::__construct();
        $this->object = $object;
        $this->target = $target;
    }

    public function getText()
    {
        return $this->object . ($this->target != '' ? ': ' . $this->target : '');
    }

    public function generateInner()
    {
        $this->inner = $this->getText();
        $this->setBoxClass('m-module-header');
    }
}
?>