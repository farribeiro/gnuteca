<div id="<?php echo $form ?>_container" class="m-container">
    <div id="<?php echo $form ?>_container_top" class="m-container-top">
        <div class="m-box-title">
            <span class="icon"><img src="<?php echo $miolo->getUI()->getImageTheme($theme->id, $miolo->getConf('theme.logo')) ?>" alt="" border="0"></span>
            <span class="caption"><?php echo $miolo->getConf('theme.system') ?></span>
        </div>
    </div>
    <div id="m-loading-message-bg"></div>
    <div id="m-loading-message">
        <div id="m-loading-message-image">
            <div id="m-loading-message-text">Loading...</div>
        </div>
    </div>
<?php
if ($theme->hasMenuOptions())
{
    if ($needTable == true)
    {
?>
    <div>
        <table id="m-container-dhtmlmenu2" collspacing=0 cellpadding=0 cellspacing=1 border=0>
            <tr>
<?php
    }
    echo $theme->generateElement('menus');
    if ($needTable == true)
    {
?>
            </tr>
        </table>
    </div>
<?php
    }
}
if ($theme->getElement('module') != NULL)
{
    echo $theme->generateElement('module');
}
if ($theme->getElement('navigation')->hasOptions())
{
?>
    <div id="<?php echo $form ?>_navbar">
<?php
    echo $theme->generateElement('navigation');
?>
    </div>
<?php
}
?>
    <div id="<?php echo $form ?>_content">
<?php
    $classContent = ( ($miolo->getConf('options.mainmenu') == 2) || ($miolo->getConf('options.mainmenu') == 3) )
                       ? 'm-container-content-full' : 'm-container-content';
    $theme->setElementClass('content', $classContent);

    echo $theme->generateElement('content');
?>
    </div>
    
    <div id="<?php echo $form ?>_bottom">
<?php
    $theme->setElement('bottom', new MStatusBar());
    $theme->setElementClass('bottom', 'm-container-bottom');
    echo '<div id="extBottom" style="visibility: visible; position: fixed; bottom:0; width: 100%">';
    echo $theme->generateElement('bottom');
    echo '</div>';
?>
    </div>
    <div id="<?php echo $form ?>_container_minbar" class="m-container-minbar">
        <div></div>
    </div>
</div>
