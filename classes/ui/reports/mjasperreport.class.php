<?php

class MJasperReport extends MReport
{
    var $filetype; // pdf doc xls rtf htm rpt
    var $fileout;
    var $fileexp;
    var $objDb;
    var $db;
    var $connectionType;

    function __construct($db = 'admin', $connectionType = 'local')
    {
        $this->db = $db;
	    $this->connectionType=$connectionType;
    }

 	function Execute($module, $name, $parameters = null, $rangeparam = null, $filetype = 'PDF', $save = false)
    {
        global $MIOLO, $page;

	//Caso o parâmetro filetype seja null (diferente de ter sido omitido)        
	$this->filetype = isset($filetype) ? $filetype : 'PDF';

    $filein = addslashes($MIOLO->GetModulePath($module, 'reports/' . $name . '.jasper'));
    $param = "";

        
	if ($this->connectionType=='local') {
        	//Nova solução sem usar o TomCat

		if (is_array($parameters))
	    {
	        foreach ($parameters as $pn => $pv)
	        {
				    $param .= '&' . $pn . "<-" . $pv;
	        }
        }

        $this->fileout= uniqid(md5(uniqid(""))) . "." . strtolower($this->filetype);
        $pathout = $MIOLO->getConf("home.reports") .'/'.$this->fileout; // colocar a pasta classes no miolo.conf
		$pathMJasper = $MIOLO->getConf("home.extensions")."/jasper";
		
		$this->objDb = $MIOLO->GetDatabase($this->db);
		$dbUser = $this->objDb->user;
		$dbPass = $this->objDb->pass;
		$jdbcDriver = $this->objDb->jdbc_driver;
		$jdbcDb =  $this->objDb->jdbc_db;
		
				
		$param = "relatorio<-$filein".$param."&fileout<-".$pathout."&filetype<-".$this->filetype;
	
		$comando = 'echo $JAVA_HOME';
		$pathJava = trim(shell_exec($comando));
			
        $pathJava = $MIOLO->getConf("home.java");
		$classPath = "$pathMJasper/lib/jasperreports-3.0.0.jar;$pathMJasper/lib/commons-beanutils-1.7.jar;$pathMJasper/lib/commons-collections-2.1.jar;$pathMJasper/lib/commons-digester-1.7.jar;$pathMJasper/lib/commons-javaflow-20060411.jar;$pathMJasper/lib/commons-logging-api-1.0.2.jar;$pathMJasper/lib/itext-1.3.1.jar;$pathMJasper/lib/ojdbc14.jar;$pathMJasper/lib/iReport.jar;$pathMJasper/jxl-2.4.2.jar;$pathMJasper/lib/mysql-connector-java-5.0.6-bin.jar;$pathMJasper/lib/postgresql-8.3-603.jdbc4.jar;$pathMJasper/";
	
		$cmd = "{$pathJava}"  . "\bin\java -classpath \"$classPath\" MJasper \"{$pathMJasper}\" \"{$param}\" \"{$dbUser}\" \"{$dbPass}\" \"{$jdbcDriver}\" \"{$jdbcDb}\"";
		exec($cmd,$output);
		
mdump($cmd);

		//var_dump($cmd,$output);
		
		if ($output[0]=="end") {
			//Aplicação JAVA rodou sem erros!
            if ($save) {
                $MIOLO->response->sendDownload($pathout);
            } else {
                $this->fileout = $MIOLO->getActionURL('miolo','reports:'.$this->fileout);
			    $MIOLO->getPage()->window($this->fileout);
            }
            return 1;
		} else {
			throw new EControlException(implode("<br>",$output));
		}
	
    } else if ($this->connectionType=='remote') {
		//Mantendo a possibilidade de usar outra máquina para geração de relatórios com o TomCat
		$filein = addslashes($MIOLO->GetModulePath($module, 'reports/' . $name . '.jasper'));
		$param = "";
		if (is_array($parameters))
		{
		    foreach ($parameters as $pn => $pv)
		    {

		        $param .= '&' . $pn . "=" . urlencode($pv);
		    }
		}

		$this->fileout = $MIOLO->getConf("home.url_jasper"). "?bd={$this->db}&relatorio=$filein" . $param;
		$MIOLO->getPage()->Redirect($this->fileout);
	}
	
   }
}
?>
