<?
	$theme->ClearContent();
	$ui = $MIOLO->GetUI();
	$navbar->AddOption('Novo Professor','administracao','main');
	$form=$ui->GetForm('administracao','frmProfessorNew',NULL,'professor');
	$theme->InsertContent($form);
?>
