<?php
//MIOLO::import('extensions::cpaint2.inc.php','cpaint'); 

class MGridAJAX extends MGrid
{
/*
    public $cp;  // the cpaint object

    public function __construct($data, $columns, $href, $pageLength = 15, $index = 0, $name = '', $useSelecteds = true, $useNavigator = true)
    {
        parent::__construct($data, $columns, $href, $pageLength, $index, $name, $useSelecteds, $useNavigator);
        $this->page->addScript('x/x_core.js');
        $this->page->addScript('cpaint/cpaint2.inc.js');
        $this->page->addScript('m_ajax.js');
        $class_methods = get_class_methods($this);
        foreach ($class_methods as $method_name) 
        {
            if ( ! strncmp($method_name,'ajax',4) )
            {
                $this->registerMethod($method_name);
            } 
        }
    }

    public function init()
    {
        $this->cp = new cpaint();
    }

    public function registerMethod($method)
    {
        MUtil::setIfNULL($this->cp, new cpaint());
        $this->cp->register(array($this,$method));
    }

    public function start()
    {
        global $MIOLO;

        $page = $MIOLO->getPage();
        
        if ($ajax = ($page->request('cpaint_function') != "")) 
        {
            $MIOLO->getTheme()->clearContent();
            $page->generateMethod = 'generateAJAX';
            $page->cpaint = $this->cp;
            $this->cp->start('ISO-8859-1');
        }
        return $ajax;
    }
*/
}
?>