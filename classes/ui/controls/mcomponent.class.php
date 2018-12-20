<?php
abstract class MComponent
{
    public $manager; // a shortcut to miolo
    public $page;
    public $owner;
    public $components;
    public $componentCount;
    public $name;
    public $className; // name of control's class_

    public function __construct($name = NULL)
    {
        $this->manager = MIOLO::getInstance();
        $this->page = $this->manager->page;
        $this->className = strtolower(get_class($this));
        $this->name  = $name;
        $this->owner = $this;
        $this->components = array();
        $this->componentCount = 0;
    }

    public function setName($name)
    {
        $this->name = $name;
    }

    public function getName()
    {
        return $this->name;
    }

    private function add($component, $pos)
    {
        $this->components[$pos] = $component;
        $component->owner = $this;
        $this->componentCount++;
    }

    public function addComponent($component)
    {
        $this->add($component, $this->componentCount);
    }

    public function insertComponent($component, $pos = 0)
    {
        if ($pos < $this->componentCount)
        {
            for ($i = $this->componentCount; $i >= $pos; $i--)
                $this->components[$i + 1] = $this->components[$i];
        }
        else
        {
            $pos = $this->componentCount + 1;
        }

        $this->add($component, $pos);
    }

    public function setComponent($component, $pos)
    {
        if ($pos < $this->componentCount)
        {
            $this->component[$pos] = $component;
            $component->owner = self;
        }
    }

    public function setComponents($components)
    {
        $this->components = $components;
    }

    public function getComponents()
    {
        return $this->components;
    }

    public function getComponent($pos)
    {
        return $this->components[$pos];
    }

    public function clearComponents()
    {
        $this->components = array();
        $this->componentCount = 0;
    }

    /**
      * Returns a manager (MIOLO) instance.
      *
      * @return MIOLO instance
      */
    public function getManager()
    {
        return $this->manager;
    }
    
}
?>