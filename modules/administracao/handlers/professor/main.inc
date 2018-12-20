<?
	$theme->ClearContent();
	$ui = $MIOLO->GetUI();
	$objAluno = $MIOLO->GetBusiness('administracao','professor',$item);
	//$navbar->AddOption(ucwords(strtolower($objProfessor->professor)),'administracao','main:professor:main',$item);	$navbar->AddOption($objProfessor->idprofessor,'administracao','main:professor:main',$item);
	$form=$MIOLO->getUI()->GetForm($module,'frmProfessor',$objProfessor,'professor');
	$theme->InsertContent($form);
	$a = $context ? $context->ShiftAction() : 'main';
	$handled = $MIOLO->InvokeHandler($module,$a);
?>
