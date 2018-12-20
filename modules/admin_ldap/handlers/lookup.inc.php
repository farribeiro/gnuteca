<?php
$MIOLO->history->pop();
$lookup = new MLookup();
$file = $MIOLO->getModulePath($lookup->module,'db/lookup.class');
if ( file_exists( $file ) )
{
   $ok = $MIOLO->uses('/db/lookup.class',$lookup->module);
}
else
{
   $ok = $MIOLO->uses('/classes/lookup.class',$lookup->module);
}
$MIOLO->assert($ok,_M('Arquivo modules/@1/classes/lookup.class não encontrado.<br>'.
                      'Este arquivo deve implementar a classe Business@1Lookup '.
                      'contendo a função Lookup@2.', 
                      'miolo',$lookup->module, $lookup->item));
$page->addScript('m_lookup.js');
$page->setTitle('Janela de Pesquisa');
$businessClass = "Business{$lookup->module}Lookup";
$lookupMethod = "Lookup{$lookup->item}";
$object = new $businessClass();
$object->$lookupMethod($lookup);
$page->setAction($lookup->href);
$MIOLO->conf->loadConf($lookup->module);
$theme = $MIOLO->getTheme($MIOLO->getConf('theme.lookup'),'lookup');
$theme->setContent($lookup->grid);
?>
