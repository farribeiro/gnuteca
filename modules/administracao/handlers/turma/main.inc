<?
	$theme->ClearContent();
	$ui = $MIOLO->GetUI();
	$objAluno = $MIOLO->GetBusiness('administracao','turma',$item);
	//$navbar->AddOption(ucwords(strtolower($objTurma->turma)),'administracao','main:turma:main',$item);	$navbar->AddOption($objTurma->idturma,'administracao','main:turma:main',$item);
	$form=$MIOLO->getUI()->GetForm($module,'frmTurma',$objTurma,'turma');
	$theme->InsertContent($form);
	$a = $context ? $context->ShiftAction() : 'main';
	$handled = $MIOLO->InvokeHandler($module,$a);
?>
