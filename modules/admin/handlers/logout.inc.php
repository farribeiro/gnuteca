<?php

// logout
$MIOLO->getAuth()->logout();

// redirect to common environment
$newURL = $MIOLO->getActionURL( 'admin', 'main:login');
$page->redirect( $newURL );

?>
