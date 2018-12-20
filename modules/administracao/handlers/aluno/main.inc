<?
	$theme->ClearContent();
	$ui = $MIOLO->GetUI();
	$objAluno = $MIOLO->GetBusiness('administracao','aluno',$item);
	//$navbar->AddOption(ucwords(strtolower($objAluno->aluno)),'administracao','main:aluno:main',$item);	$navbar->AddOption($objAluno->idaluno,'administracao','main:aluno:main',$item);
	$form=$MIOLO->getUI()->GetForm($module,'frmAluno',$objAluno,'aluno');
	$theme->InsertContent($form);
	$a = $context ? $context->ShiftAction() : 'main';
	$handled = $MIOLO->InvokeHandler($module,$a);
?>
