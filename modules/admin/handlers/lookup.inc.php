<?php
$MIOLO->history->pop();
$lookup = new MLookup($module);
$file = $MIOLO->getModulePath($lookup->module,'db/lookup.class.php');
if ( file_exists( $file ) )
{
   $ok = $MIOLO->uses('/db/lookup.class.php',$lookup->module);
}
$MIOLO->assert($ok,_M('Arquivo modules/@1/db/lookup.class.php não encontrado.<br>'.
                      'Este arquivo deve implementar a classe Business@1Lookup '.
                      'contendo a função Lookup@2.', 
                      'miolo',$lookup->module, $lookup->item));
$page->addScript('m_lookup.js');
//$lookup->setTitle('Janela de Pesquisa -  Teste');
$businessClass = "Business{$lookup->module}Lookup";
$lookupMethod = $lookup->autocomplete ? "AutoComplete{$lookup->item}" : "Lookup{$lookup->item}";
$object = new $businessClass();
$object->$lookupMethod($lookup);
$lookup->setContent();
?>
