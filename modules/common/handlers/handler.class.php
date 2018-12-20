<?php
class HandlerCommon extends MHandler
{
    function init()
    {
        parent::init();
        $this->manager->Trace(__METHOD__);
    }
}
?>
