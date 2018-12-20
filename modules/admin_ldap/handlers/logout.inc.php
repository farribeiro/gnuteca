<?php

$MIOLO->getAuth()->logout();
$page->redirect($MIOLO->getConf('home.url'));

?>