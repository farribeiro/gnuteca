<?php
class MNavigationBar extends MMenu
{
    public $separator = '&raquo;&raquo;';
    public $labelHome = 'Home';

    public function setLabelHome($label)
    {
        $this->labelHome = $label;
    }

    public function generateInner()
    {
        if ($this->base)
        {
            $base = $this->base;
        }
        else
        {
            $base = $this->manager->dispatch;
        }

        $this->setCssClassItem('link', 'm-topmenu-link');
        $this->setCssClassItem('option', 'm-topmenu-link');

        $ul = new MUnorderedList();
        $options = $this->getOptions();

        if ($count = count($options))
        {
            $url = $this->manager->getActionURL($this->home,'main','','',$base);
            $link = new MLink('', $this->labelHome, $url);
            $link->setClass('m-topmenu-link');
            $ul->addOption($link->generate());
            $ul->addOption($this->separator);

            foreach ($options as $o)
            {
                if (--$count)
                {
                    $ul->addOption($o->generate());
                    $ul->addOption($this->separator);
                }
                else
                {
                    $span = new MSpan('', $o->control->label, 'm-topmenu-current');
                    $ul->addOption($span->generate());
                }
            }
        }
        else // root item
        {
            $ul->addOption($this->caption);
        }

        $this->setBoxClass('m-topmenu-box');
        $this->inner = $ul;
    }
}
?>
