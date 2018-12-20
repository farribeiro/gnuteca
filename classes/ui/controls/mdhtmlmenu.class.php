<?php
class MDHTMLMenu extends MControl
{
    private $js_array_options;
    static $order = 0;
    private $nOrder;
    private $template;
  	private $action;
  	private $target;
    private $items;
    private $jsItems;
    
    public function __construct($name='', $template=0, $action='', $target='_blank')
    {   
        parent::__construct($name);
        $page = $this->page;
//        $this->addStyleFile('m_dhtmlmenu.css');
        $page->addScript('tigra/menu.js');
        $this->items = NULL;
        $this->template = $template;
        $this->action = $action; 
    	$this->target = $target;
        $this->js_array_options = array();
        $this->nOrder = MDHTMLMenu::$order++;
    }

    private function getJsItems($items)
    {
        if ($items != NULL)
        {
           foreach($items as $it)
           {
               $i .= "['{$it[1]}'";
               $i .= ($it[0] !== NULL) ? (($it[0] != '0') ? ",'{$it[0]}'" : ',null')  : ',null';
               if ($this->action != '')
			   {
                   $it[2] = str_replace('#',$it[0], $this->action);
			   }
			   $i .= ($it[2] != NULL ? ",{$it[2]}" : ',null') . ',';
               $i .= $this->getJsItems($this->items[$it[0]]);
               $i .= "],";
           }
           return $i;
        }
    }

    public function setTitle($title) {
      if (sizeof($this->js_array_options)) {
        $this->js_array_options[0][1] = $title;
      }
      else {
        $this->js_array_options[] = array('0',$title,'','root');
      }
    }

    public function addOption($label,$module='main',$action='',$item=null,$args=null)
    {
        $control = new MLink(NULL,$label);
        $control->setAction($module,$action,$item,$args);
        $this->js_array_options[] = array($control->href,$label,sizeof($this->js_array_options)-1,0);
    }

    public function addUserOption($transaction, $access,$label,$module='main',$action='',$item='',$args=null)
    { 
        
        if ( $this->manager->perms->checkAccess($transaction, $access))
        {
            $this->addOption($label,$module,$action,$item,$args);
        }
    }

    public function addLink($label, $link = '#', $target = '_self')
    {
//        $this->js_array_options[] = array($link,$label,sizeof($this->js_array_options)-1,0);
        $this->js_array_options[] = array($link,$label,"{'tw':'$target'}",0);
    }

    public function addSeparator()
    {
    }

    public function hasOptions()
    {
        return (count($this->js_array_options) > 0);
    }
    
    public function setItemsFromArray($array, $key='3', $data='0,1,2')
    {
        $o = new MTreeArray($array,$key,$data);
        $this->items = $o->tree;
        $this->jsItems = $this->getJsItems($this->items['root']) ;
    }

    public function getParameters() {
      global $module, $theme;
      
      $conteudo = $this->manager->getTheme()->getCSSFileContent('miolo.css');
      
      preg_match_all("/&&&(.*?)&&&/s", $conteudo, $trecho, PREG_SET_ORDER);
      $trecho = trim($trecho[0][1]);
      
      $parametros = array();
      $niveis = explode("\n",$trecho);

      foreach($niveis as $nivel => $valor) {
        $partes = explode(";",$valor);
        for ($i = 1; $i < sizeof($partes); $i++) {
          $pares = explode(":",$partes[$i]);
          $parametros[$partes[0]][$pares[0]] = $pares[1];
        }
      }
      return $parametros;
    }

    public function calculatePosition($tree) {
      global $MIOLO;

      $parametros = $this->getParameters();

      $session = $MIOLO->session;
      $x = $session->getValue("num_mainmenu");

      $posicao = "var MENU_POS_{$tree} = [
        {
          // item sizes
          'height': ". $parametros[0]['height'] .",
          'width': ". $parametros[0]['width'] .",
          // menu block offset from the origin:
          //	for root level origin is upper left corner of the page
          //	for other levels origin is upper left corner of parent item
          'block_top': 0,
          'block_left': ". ($x * ($parametros[0]['width'] + 4)) .",
          // offsets between items of the same level
          'top': ". $parametros[0]['top'] .",
          'left': ". $parametros[0]['left'] .",
          // time in milliseconds before menu is hidden after cursor has gone out
          // of any items
          'hide_delay': ". $parametros[0]['hide_delay'] .",
          'expd_delay': ". $parametros[0]['expd_delay'] .",
          'css' : {
            'outer': ['m0l0oout', 'm0l0oover', 'm0l0odown'],
            'inner': ['m0l0iout', 'm0l0iover', 'm0l0idown']
          }
        },
        {
          'height': ". $parametros[1]['height'] .",
          'width': ". $parametros[1]['width'] .",
          'block_top': ". $parametros[1]['block_top'] .",
          'block_left': ". $parametros[1]['block_left'] .",
          'top': ". $parametros[1]['top'] .",
          'left': ". $parametros[1]['left'] .",
          'css': {
            'outer' : ['m0l1oout', 'm0l1oover'],
            'inner' : ['m0l1iout', 'm0l1iover']
          }
        },
        {
          'block_top': ". $parametros[2]['block_top'] .",
          'block_left': ". $parametros[2]['block_left'] .",
          'css': {
            'outer': ['m0l2oout', 'm0l2oover'],
            'inner': ['m0l1iout', 'm0l2iover']
          }
        }
        ];\n";

        $x++;
        $session->setValue("num_mainmenu",$x);

        return $posicao;
    }

    public function generateInner()
    {
        $this->setItemsFromArray($this->js_array_options);
        $tree = $this->nOrder;
        $page = $this->page;
        $form = ($this->form == NULL) ? $page->name : $this->form->name;
        $js   = "var MENU_ITEMS_{$tree} = [ " . $this->jsItems . "];\n " . $this->calculatePosition($tree);
        $this->page->addJsCode($js);       
        $html = "<script type=\"text/javascript\" language=\"JavaScript\">";
        $html .= "<!--\n";
//        $html .= "var MENU_ITEMS_{$tree} = [ " . $this->jsItems . "];\n";
//        $html .= $this->calculatePosition();
        $html .= "new menu (MENU_ITEMS_{$tree}, MENU_POS_{$tree});\n";
        $html .= "//-->";
        $html .= "</script>";
        $this->inner = $html;
    }
}
?>
