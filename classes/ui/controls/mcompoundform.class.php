<?php
class MCompoundForm extends MForm
{
    public $_info = array();
    public $_panel = array();
    public $_form = array();

    public function __construct($title = '', $action = '', $close = 'backContext', $icon = '')
    {
        parent::__construct($title, $action, $close, $icon);
        $this->defaultButton = false;
        $this->compoundFields();
    }

    public function compoundFields()
    {
        $this->clearControls();
        $this->fields = array
            (
            );

        foreach ($this->_info as $f)
        {
            $this->addField($f);
        }

        $this->addField(new MSpacer());

        foreach ($this->_panel as $f)
        {
            $this->addField($f);
            $this->addField(new MSpacer());
        }

        foreach ($this->_form as $f)
        {
            $this->addField($f);
            $this->addField(new MSpacer());
        }
    }

    public function generate()
    {
        if (!isset($this->buttons))
        {
            if ($this->defaultButton)
            {
                $this->buttons[] = new MButton(FORM_SUBMIT_BTN_NAME, 'Enviar', 'SUBMIT');
            }
        }

        $body = $this->generateBody();
        $footer = $this->generateFooter();
        $this->box->setBoxClass('m-form-body');

        $this->box->setControls(array($body, $footer));
        return $this->box->generate();
    }
}
?>