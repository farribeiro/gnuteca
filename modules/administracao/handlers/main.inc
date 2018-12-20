<?php
	$theme->ClearContent();
	$ui = $MIOLO->GetUI();
	$navbar->AddOption('ADMINISTRACAO', 'administracao', 'main');
	$a = $context ? $context->ShiftAction() : 'main';
	$handled = $MIOLO->InvokeHandler($module,$a);
	if (! $handled)
	{
	$close = $MIOLO->GetActionURL('administracao','main');
	$panel = new MActionPanel('pnlADMINISTRACAO','ADMINISTRACAO','',$close);
	$panel->SetIconType('small');
	$panel->AddUserAction('administracao_info',A_EXECUTE,'Turma',$ui->GetImage('administracao','quadro.png'), $module,'main:turma:find');
	$panel->AddUserAction('administracao_info',A_EXECUTE,'Aluno',$ui->GetImage('administracao','quadro.png'), $module,'main:aluno:find');
	$panel->AddUserAction('administracao_info',A_EXECUTE,'Professor',$ui->GetImage('administracao','quadro.png'), $module,'main:professor:find');
		$theme->AppendContent($panel);
	}
?>
