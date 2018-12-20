<?
	$action=$context->ShiftAction();
	$navbar->AddOption('Turma','administracao','main:turma:find');
	switch($action)
	{
		case 'find':
			$MIOLO->InvokeHandler($module,'turma/find');
			break;
		case 'new':
			$MIOLO->InvokeHandler($module,'turma/new');
			break;
		default:
			$MIOLO->InvokeHandler($module,'turma/main');
			break;
	}
?>
