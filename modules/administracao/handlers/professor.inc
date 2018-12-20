<?
	$action=$context->ShiftAction();
	$navbar->AddOption('Professor','administracao','main:professor:find');
	switch($action)
	{
		case 'find':
			$MIOLO->InvokeHandler($module,'professor/find');
			break;
		case 'new':
			$MIOLO->InvokeHandler($module,'professor/new');
			break;
		default:
			$MIOLO->InvokeHandler($module,'professor/main');
			break;
	}
?>
