<?php
    class ThemeMystica extends MTheme
    {
        public function init()
        {
            // navigation
            $this->setElement('navigation', new MNavigationBar(), 'm-container-topmenu');
        }

        public function generate($element)
        {
            $method = "generate" . $this->layout;
            return $this->$method($element);
        }

        public function generateDefault()
        {
            $pathName = $this->manager->getConf('home.themes') . '/mystica/template/';
	        $template = new MBTemplate($pathName);
            $template->set('miolo', $this->manager);
            $template->set('theme', $this);
            $template->set('form', $this->manager->getPage()->getFormId());
		    $elements['__mainForm'] = $template->fetch('default.php'); 
            return $elements;
        }

        public function generateContent()
        {
            $pathName = $this->manager->getConf('home.themes') . '/mystica/template/';
	        $template = new MBTemplate($pathName);
            $template->set('miolo', $this->manager);
            $template->set('theme', $this);
            $template->set('form', $this->manager->getPage()->getFormId());
		    return $template->fetch('content.php'); 
        }

        public function generateNavBar()
        {
            $pathName = $this->manager->getConf('home.themes') . '/mystica/template/';
	        $template = new MBTemplate($pathName);
            $template->set('miolo', $this->manager);
            $template->set('theme', $this);
            $template->set('form', $this->manager->getPage()->getFormId());
		    return $template->fetch('navbar.php'); 
        }

        public function generateDynamic($element)
        {
            $elements[$element.'_navbar'] = $this->generateNavBar();
            $elements[$element.'_content'] = $this->generateContent();
            return $elements;
        }

        public function generateLookup()
        {
            // only 'content' element
            $html = $this->generateElement('content');
            $div = new MDiv('m-container', $html);
            $div->addStyle('width', '100%');
            return $this->painter->generateToString($div);
        }

        public function generateHtmlArea()
        {
            // module
            $this->setElementId('module', 'm-container-module');
            // content
            $this->setElementId('content', 'm-htmlarea');
            // bottom
            $this->setElement('bottom', new MStatusBar(), 'm-container-bottom');

            $html = $this->generateElement('top');

            if ($this->getElement('module') != NULL)
            {
                $html .= $this->generateElement('module');
            }

            if ($this->getElement('navigation')->hasOptions())
            {
                $html .= $this->generateElement('navigation');
            }

            $html .= $this->generateElement('content');
            $html .= $this->generateElement('bottom');
            return $this->painter->div(new MDiv('m-container', $html));
        }

        public function generatePopup()
        {
            $page = $this->manager->getPage();
//            $page->addScript('dif/dragiframe.js');
//            $page->onLoad("addHandle(document.getElementsByTagName('body').item(0), window);"); 
            // only 'content' element
            $this->setElementId('content', 'm-container-content-popup');
            $html = $this->generateElement('content');
            $divContainer = new MDiv('', $html,  'm-container');
            $divContainer->addStyle('width', '100%');
            return $this->painter->generateToString($divContainer);
        }

        public function generatePrint()
        {
            $this->generateDefault();
        }

        public function generateDOMPdf()
        {
            // only 'content' element
            $html = $this->generateElement('content');
            $div = new MDiv('m-container', $html);
            $div->addStyle('width', '100%');
            return $this->painter->generateToString($div);
        }
    }
?>
