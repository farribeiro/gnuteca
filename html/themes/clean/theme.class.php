<?php
class ThemeClean extends MTheme
{
    public function __construct()
    {
        parent::__construct('clean');
    }

    public function init()
    { 
    }

    public function generate()
    {   
        return $this->generateDefault();
    }

    public function generateDefault()
    {
       $this->setElementId('content','contentContainer');
       $html = $this->generateElement('content'); 
       return $this->painter->div(new MDiv('container',$html));
    }

}
?>