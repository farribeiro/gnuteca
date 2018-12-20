<?
	$theme->ClearContent();
	$ui = $MIOLO->GetUI();
	$form = $ui->GetForm('administracao','frmProfessorFind',NULL,'professor');
	$theme->InsertContent($form);
?>
