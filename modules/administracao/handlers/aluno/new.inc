<?
	$theme->ClearContent();
	$ui = $MIOLO->GetUI();
	$navbar->AddOption('Novo Aluno','administracao','main');
	$form=$ui->GetForm('administracao','frmAlunoNew',NULL,'aluno');
	$theme->InsertContent($form);
?>
