<?php
class MFormAJAX extends MForm
{
/*
    public $cp;  // the cpaint object

    public function __construct($title='',$action='',$close='',$icon='')
    {   global $MIOLO;
        $this->cp = $MIOLO->cpaint;
        $MIOLO->getPage()->addScript('m_cpaint.js');
        $MIOLO->getPage()->addScript('m_ajax.js');
        $MIOLO->getPage()->addScript('m_encoding.js');
        parent::__construct($title,$action,$close,$icon);
    }

    public function registerMethod($method)
    {
        $this->cp->register(array($this,$method));
    }

    public function start()
    {
        if (($ajax = $this->page->request('cpaint_function')) != "") 
        {
            $this->manager->getTheme()->clearContent();
            $this->page->generateMethod = 'generateAJAX';
            $this->page->cpaint = $this->cp;
            $this->cp->start('ISO-8859-1');
        }
        return $ajax;
    }


	function eventHandler()
	{
        if ($this->isAjaxcall())
		{
            $class_methods = get_class_methods($this);
            foreach ($class_methods as $method_name) 
            {
                if ( ! strncmp($method_name,'ajax',4) )
                {
                    $this->registerMethod($method_name);
                } 
            }
            $this->manager->getTheme()->clearContent();
            $this->page->generateMethod = 'generateAJAX';
            $this->page->cpaint = $this->cp;
            $this->cp->start('ISO-8859-1');
		}
		else
		{
            $this->page->addScript('x/x_core.js');
            $this->page->addScript('x/x_dom.js');
			parent::eventHandler();
		}

	}
*/
}
?>
