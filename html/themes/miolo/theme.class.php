<?php
    class Theme extends MTheme
    {
        public function __construct()
        {
            parent::__construct('miolo');
        }

        public function init()
        {
            $ui = $this->manager->getUI();
            $logo = $ui->getImageTheme($this->id, $this->manager->getConf('theme.logo'));
            // top
            $aTop1 = array(
                new MTextHeader('', '1', $this->manager->getConf('theme.company')),
                new MTextHeader('', '2', $this->manager->getConf('theme.system'))
            );
            $img = new MImageButton('', 'Home', $this->manager->getConf('home.url'), $logo);
            $img->image->addAttribute('width', '40px');
            $img->image->addAttribute('height', '40px');
            $top = array(
                new MDiv('', $img, 'logo'),
                new MDiv('', $aTop1, 'text')
            );

            $this->setElement('top', $top, 'm-container-top');
            // navigation
            $this->setElement('navigation', new MNavigationBar(), 'm-container-topmenu');
        }

        public function generate()
        {
            $method = "Generate" . $this->layout;
            return $this->$method();
        }

        public function generateDefault()
        {
            // bottom
            $this->setElement('bottom', new MStatusBar(), 'm-container-bottom');
            
            // menus
            if ( $this->manager->getConf('options.mainmenu') == 2 )
            {
                $idModule = 'm-container-module';
                $idMenu = 'm-container-dhtmlmenu';
            }
            else if ( $this->manager->getConf('options.mainmenu') == 3 )
            {
                $idModule = 'm-container-module2';
                $needTable = true;
            }
            else
            {
                $idMenu = 'm-container-menu';
            }

            // module
            $this->setElementId('module', $idModule);

            $this->setElementId('menus', $idMenu);

            // content
            $idContent = ( ($this->manager->getConf('options.mainmenu') == 2) || ($this->manager->getConf('options.mainmenu') == 3) )
                       ? 'm-container-content-full' : 'm-container-content';
            $this->setElementId('content', $idContent);

            $html = $this->generateElement('top');

            if ($this->hasMenuOptions())
            {
                $html .= ($needTable == true) ? '<div><table id="m-container-dhtmlmenu2" collspacing=0 cellpadding=0 cellspacing=1 border=0><tr>' : '';
                $html .= $this->generateElement('menus');
                $html .= ($needTable == true) ? '</tr></table></div>' : '';
            }

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
            return $this->painter->div(new Div('m-container', $html));
        }

        public function generateLookup()
        {
            $html = $this->generateElement('content');
            $div = new Div('', $html, 'm-container');
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
            $this->setElement('bottom', new StatusBar(), 'm-container-bottom');

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
            return $this->painter->div(new Div('m-container', $html));
        }

        public function generatePopup()
        {
            $html = $this->generateElement('content');
            $div = new Div('', $html, 'm-container');
            $div->addStyle('width', '100%');
            return $this->painter->generateToString($div);
        }

        public function generatePrint()
        {
            $this->generateDefault();
        }
    }
?>
