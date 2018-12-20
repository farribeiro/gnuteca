<?php
class MAccordion extends MDiv
{
    private $panels = array();
    protected $options;

    public function __construct( $name = NULL, $content = '&nbsp;', $class = NULL, $attributes = NULL )
    {
        parent::__construct( $name, $content, $ckass, $attributes );
        $this->addStyle('width','100%');
        $this->options = new MStringList();
    }

    public function addPanel($id, $title, $content)
    {
        $this->panels[] = new MDiv($id, array(
            new MDiv($id.'Header', $title, 'm-accordion-tabTitleBar'),
            new MDiv($id.'Content', $this->painter->generateToString($content), 'm-accordion-tabContentBox')
        ));
    }

    public function addOption($option, $value)
    {
        $this->options->addValue($option, $value);
    }

    public function generate()
    {
        $css = $this->manager->getTheme()->getCSSFileContent('miolo.css');
        preg_match_all("/&&& .m-accordion-options(.*?)&&&/s", $css, $trecho, PREG_SET_ORDER);
        $trecho = trim($trecho[0][1]);
        $niveis = explode(";",$trecho);
        foreach($niveis as $nivel => $valor) {
            if ($valor != '')
            {
                $pares = explode(":",$valor);
                $this->addOption(trim($pares[0]),$pares[1]);
            }
        }

        $this->page->addScript('rico/rico.js');
        $options =  $this->options->hasItems() ? ",{" . $this->options->getText(':', ',') . "}" : '';
        $this->page->onLoad("new Rico.Accordion( $('{$this->id}') {$options});");
        $this->setInner( $this->panels );
        return parent::generate();
    }

}
?>