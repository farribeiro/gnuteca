<?php
class MContent extends MControl
{
    public $path;
    public $home;

    public function __construct($module = false, $name = false, $home = false)
    {
        parent::__construct();
        $this->path = $this->manager->getModulePath($module, $name);
        $this->home = $home;
    }

    public function generateInner()
    {
        $content_array = file($this->path);
        $content = implode("", $content_array);
        $this->inner = new MDiv('', $content, 'm-theme-content');
    }
}

class MFileContent extends MContent
{
    public $isSource;

    public function __construct($filename = null, $isSource = false, $home = false)
    {
        parent::__construct();
        $this->path = $filename;
        $this->isSource = $isSource;
    }

    public function setFile($filename)
    {
        $this->path = $filename;
    }

    public function generateInner()
    {
        if ($this->isSource)
        {
            $content = highlight_file($this->path, true);
            $t[] = new MDiv('', $this->path, '');
            $t[] = new MDiv('', $content, 'm-filecontent');
            $this->inner = $t;
        }
        else
        {
            parent::generateInner();
        }
    }
}

?>