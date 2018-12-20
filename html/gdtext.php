<?php
include("../classes/utils/msimplexml.class.php");
include("../classes/utils/mconfigloader.class.php");

/*
$qs = base64_decode($_REQUEST['qs']);
parse_str($qs, $vars);

$auth = md5($vars['key'].$vars['text'].$vars['size']);
$text = $vars['text'];
$font_size = $vars['size'];
$ttfFont = $vars['font'];
$color = $vars['color'];
include("../classes/extensions/gdtext/gdtext1.php");
*/

        // get config setting
        $conf = new MConfigLoader();
        $dir = realpath(dirname(__FILE__));
        $conf->loadConf('',$dir . "/../classes/etc/gdtext.xml");

        $cache_dir = $dir . "/.." . $conf->getConf("gdtext.dir.cache");
        $ttf_dir = $dir . "/.." . $conf->getConf("gdtext.dir.ttf");

$qs = base64_decode($_REQUEST['qs']);
parse_str($qs, $vars);

$key = $vars['key'];
$text = $vars['text'];
$font_size = $vars['size'];
$ttfFont = $vars['font'];
$fcolor = explode(',',$vars['fcolor']);
$bcolor = explode(',',$vars['bcolor']);
//for($i=0;$i<3;$i++) {$fcolor[$i] = (int)$fcolor1[$i];$bcolor[$i] = ($bcolor1[$i]);}
//var_dump($fcolor);
//var_dump($bcolor);
//var_dump($key,$text,$font_size);
$auth = md5($key.$text.$font_size);


include("../classes/extensions/gdtext/gdtext2.php");

?>