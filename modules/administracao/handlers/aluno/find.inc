<?
	$theme->ClearContent();
	$ui = $MIOLO->GetUI();
	$form = $ui->GetForm('administracao','frmAlunoFind',NULL,'aluno');
	$theme->InsertContent($form);
?>
