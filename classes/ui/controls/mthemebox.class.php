<?php
class MThemeBox extends MControl
{
    public $title;
    public $content;

    public function __construct($title, $content = '')
    {
        parent::__construct();
//        $this->addStyleFile('m_themeelement.css');
        $this->title = $title;
        $this->content = $content;
    }

    public function setContent($content)
    {
        $this->content = $content;
    }

    public function generateInner()
    {
        $attrs = $this->getAttributes();
        $t[] = new MSpan('', $this->title, 'title');
        $t[] = new MDiv('', $this->content, 'content');
        $this->inner = $t;
    }

    public function generate()
    {
        $this->setBoxClass('m-theme-box');
        return parent::generate();
    }
}

?>