<?php
// MIOLO Wrapper for 
// ================================================
// SPAW PHP WYSIWYG editor control
// ================================================

include ('/usr/local/miolo2/html/scripts/spaw/spaw_control.class.php');

class M_SPAW_Wysiwyg extends MControl
{
    // spaw_control
    public $spaw_control;

    // constructor
    public function M_SPAW_Wysiwyg($control_name = 'richeditor', $value = '',     $lang = '',        $mode = '',
                            $theme = '',                  $width = '100%', $height = '300px', $css_stylesheet = '',
                            $dropdown_data = '')
    {
        parent::__construct($name);
        $this->spaw_control = new SPAW_Wysiwyg($control_name,   $value, $lang, $mode, $theme, $width, $height,
                                               $css_stylesheet, $dropdown_data);
    }

    // outputs wysiwyg control
    public function generate()
    {
        echo $this->spaw_control->show();
    }
}
?>
