<?
	$action=$context->ShiftAction();
	$navbar->AddOption('Aluno','administracao','main:aluno:find');
	switch($action)
	{
		case 'find':
			$MIOLO->InvokeHandler($module,'aluno/find');
			break;
		case 'new':
			$MIOLO->InvokeHandler($module,'aluno/new');
			break;
		default:
			$MIOLO->InvokeHandler($module,'aluno/main');
			break;
	}
?>
