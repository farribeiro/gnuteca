<?
	$theme->ClearContent();
	$ui = $MIOLO->GetUI();
	$navbar->AddOption('Novo Turma','administracao','main');
	$form=$ui->GetForm('administracao','frmTurmaNew',NULL,'turma');
	$theme->InsertContent($form);
?>
