<div id="<?php echo $form ?>_content">
<?php
    $classContent = ( ($miolo->getConf('options.mainmenu') == 2) || ($miolo->getConf('options.mainmenu') == 3) )
                       ? 'm-container-content-full' : 'm-container-content';
    $theme->setElementClass('content', $classContent);
    echo $theme->generateElement('content');
?>
</div>