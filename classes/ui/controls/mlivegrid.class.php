<?php
class MLiveGrid extends MSimpleTable
{
   private $columnsHeader;
   private $columnsWidth;
   private $maxRows;
   private $rowCount;
   private $row;
   private $header;
   public  $pageSize;
   public  $offset;

   public function __construct($name='', $row=1, $cell=1, $maxRows=0, $data=array(), $header=array(), $width=array())
   {
       $attrs = "cellspacing=0 cellpadding=0 border=0";
       parent::__construct($name,$attrs,$row,$cell);
   }

   public function initTable($row,$cell)
   {
       for($r=0; $r <= $row; $r++)
       {
           for($c = 0; $c < $cell; $c++)
           {
               $this->setCell($r,$c,'');
               $this->setCellClass($r,$c, 'm-livegrid-celldata'. ($c ? '' : ' '));
               $this->setCellAttribute($r, $c, 'style', "width:{$this->columnsWidth[$c]}px");
           }
       }
       $this->rowCount = $row;
   }

   public function setColumnsHeader($header)
   {
       $this->header = new MSimpleTable($this->id.'_header',"cellspacing=0 cellpadding=0 border=0");
       $this->header->setClass('m-livegrid-header');
       foreach($header as $i=>$h)
       {
           $this->header->setCell(0,$i,$h);
           $this->header->setCellClass(0,$i, 'm-livegrid-cellheader'. ($i ? '' : ' '));
           $this->header->setCellAttribute(0, $i, 'style', "width:{$this->columnsWidth[$i]}px");
       }
   }

   public function setColumnsWidth($width)
   {
       $this->columnsWidth = $width;
   }

   public function setMaxRows($value)
   {
       $this->maxRows = $value;
   }

   public function setParameters($args)
   {
        $par1 = explode(',',$args);
        foreach($par1 as $value) 
        {
           $par2 = explode('=',$value);
           $this->{$par2[0]} = $par2[1];
        }
   }

   public function setObject($cp, $table)
   {
        $result_node  = $cp->add_node('table');
        foreach($table as $row)
        {
            $row_node = $result_node->add_node('tr');
            foreach($row as $col)
            {
              $col_node = $row_node->add_node('td');
              $col_node->set_data($col);
            }
        }
   }

   public function generate()
   {
       $this->setClass('m-livegrid-data');
       $this->page->addStyle('m_livegrid.css');
       $this->page->addScript('m_ricolivegrid.js');
       $code =
<<< HERE
   public opts = { prefetchBuffer : true,
                onscroll       : updateHeader };
   tu = new MRico.LiveGrid('{$this->id}', $this->rowCount, $this->maxRows, miolo.getForm().action, opts );
HERE;
       $this->page->onLoad($code);
       $header = $this->header->generate();
       $data = parent::generate();
       $viewPort = new MDiv('viewPort',$data);
       $viewPort->float = 'left';
       $container = new MDiv($this->id.'_container', $viewPort);
       $div = new MDiv($this->id.'_containerFull',array($header,$container),'m-livegrid');
       return $div->generate();   
    }
   
}
?>