<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>UFJF - SIGA</title>
<link rel="stylesheet" type="text/css" href="http://127.0.0.1:8081/scripts/dojoroot/dijit/themes/tundra/tundra.css">
<link rel="stylesheet" type="text/css" href="http://127.0.0.1:8081/themes/system/miolo.css">


<meta http-equiv="Content-Type" content="0">
<meta name="Generator" content="MIOLO Version Miolo 2.5; http://www.miolo.org.br">
<script type="text/javascript"> djConfig={/*isDebug:true,*/ usePlainJson:true,  parseOnLoad:true}</script>
<script type="text/javascript" src="http://127.0.0.1:8081/scripts/dojoroot/dojo/dojo.js"></script>
<script type="text/javascript" src="http://127.0.0.1:8081/scripts/prototype/prototype.js"></script>

<script type="text/javascript" src="http://127.0.0.1:8081/scripts/m_miolo.js"></script>
<script type="text/javascript" src="http://127.0.0.1:8081/scripts/m_page.js"></script>
<script type="text/javascript" src="http://127.0.0.1:8081/scripts/m_ajax.js"></script>
<script type="text/javascript" src="http://127.0.0.1:8081/scripts/m_encoding.js"></script>
<script type="text/javascript" src="http://127.0.0.1:8081/scripts/m_form.js"></script>
<script type="text/javascript" src="http://127.0.0.1:8081/scripts/m_compatibility.js"></script>
<script type="text/javascript" src="http://127.0.0.1:8081/scripts/m_md5.js"></script>

<script type="text/javascript" src="http://127.0.0.1:8081/scripts/m_multitext2.js"></script>
<script type="text/javascript" src="http://127.0.0.1:8081/scripts/m_multitext3.js"></script>
<script type="text/javascript" src="http://127.0.0.1:8081/scripts/m_multitext4.js"></script>

<script type="text/javascript">
dojo.require("dojo.parser");

var mtfName = new Miolo.MultiTextField4('mtf2');

//-->
</script>

</head>
<body class="m-theme-body">
<!-- begin of page48b1f7cfbebc3 -->
<div id="page48b1f7cfbebc3">
<!-- begin of form __mainForm -->
<div id="__mainForm">
 <form id="frm__mainForm" name="frm__mainForm" method="post" action="http://127.0.0.1:8081/index.php/teste/mtf"  onSubmit="return frm__mainForm_onSubmit();" ><div id="frm__mainForm_container" class="m-container">
     <div id="frm__mainForm_container_top" class="m-container-top">
         <div class="m-box-title">
             <span class="icon"><img src="http://127.0.0.1:8081/themes/system/images/logo_miolo.png" alt="" border="0"></span>
             <span class="caption">Tutorial - A Demo Module</span>
         </div>
     </div>
     <div id="m-loading-message-bg"></div>
     <div id="m-loading-message">
         <div id="m-loading-message-image">
             <div id="m-loading-message-text">Loading...</div>
         </div>
     </div>
 
 <div>
 <div id="m_m4" class="m-module-header"></div></div>    <div id="frm__mainForm_content">
 
 <div id="content" class="m-container-content-full">
 <div id="frm48b1f7d08bad1" class="m-form-box">
 <div id="m7" class="m-box-outer m-form-outer">
 <div class="m-box-box">
 <div class="m-box-title"><span class="caption">&nbsp;&nbsp;MultiText</span></div>
 <div class="m-form-body">
 <div>
 <div class="m-form-row">
 <!--  -->
 
 <div class="m-multitext-field">
 <div id="m_m63" style="width:98%">
 <fieldset ><legend>Exemplo - layout horizontal:</legend>
 <div class="fieldPosH" style="float:left;margin-right:5px">
 <div id="m_m53" style="width:200px">
 <div style="margin-bottom:3px"><span class="m-caption">Texto</span><br>
 <input  type="text" id="txfId" class="m-text-field" name="txfId" value="" size="20"></div>
 <div style="margin-bottom:3px">
 <div id="m_lkpTransacao" style="float:left"><span class="m-caption">Transação</span><br>
 <input  type="text" id="lkpTransacao" class="m-text-field" name="lkpTransacao" value="" size="20"></div><span class="m-caption">&nbsp;</span><br>
 <button  type="button" class="m-button m-button-find" name="" value="" onclick="javascript:lookup_frm__mainForm_lkpTransacao.start();">&nbsp;</button></div>
 <div style="margin-bottom:3px"><span class="m-caption">Sistema</span><br>
 <select  id="selIdSistema" class="m-combo" name="selIdSistema" style="width:200px">
 <option value="" selected >--Selecione--</option>
 <option value="op1">Opção1</option>
 <option value="op2">Opção2</option>
 <option value="op3">Opção3</option>
 <option value="op4">Opção4</option>
 <option value="op5">Opção5</option></select></div></div></div>
 <div class="buttonPosH" style="float:left;margin-right:5px">
 <div class="label">&nbsp;</div>
 <div id="m_m52">
 <div style="margin-bottom:3px">
 <button  id="mtf_frm__mainForm_mt2_add" type="button" class="m-button button" name="mtf_frm__mainForm_mt2_add" value="Adicionar" onclick="mtf_frm__mainForm_mt2.add('txfId,lkpTransacao,selIdSistema')">Adicionar</button></div>
 <div style="margin-bottom:3px">
 <button  id="mtf_frm__mainForm_mt2_modify" type="button" class="m-button button" name="mtf_frm__mainForm_mt2_modify" value="Modificar" onclick="mtf_frm__mainForm_mt2.modify('txfId,lkpTransacao,selIdSistema')">Modificar</button></div>
 <div style="margin-bottom:3px">
 <button  id="mtf_frm__mainForm_mt2_remove" type="button" class="m-button button" name="mtf_frm__mainForm_mt2_remove" value="Remover" onclick="mtf_frm__mainForm_mt2.remove('txfId,lkpTransacao,selIdSistema')">Remover</button></div></div></div>
 <div class="selectPosH" style="float:left;margin-right:5px">
 <div class="m-texttable" style="width:200px">
 <div class="scroll" style="height:75px;width:200px">
 <table  id="mt2_table" cellspacing="0" cellpadding="0" border="0" width="100%">
 <tbody>
 </tbody>
 </table></div></div></div>
 <div class="m-spacer">&nbsp;</div></fieldset></div></div>
 <!--  -->
 </div>
 <div class="m-form-row">
 <div class="m-form-button-box">
 <ul >
   <li>
 <div class="m-hr"></div></li>
   <li>
 <button  id="btnPost" type="button" class="m-button" name="btnPost" value="Ok" onclick="miolo.doPostBack('btnPost:click','','frm__mainForm');">Ok</button></li>
 </ul></div></div>
 <!-- START OF HIDDEN FIELDS -->
 <input type="hidden" id="frm48b1f7d08bad1_action" name="frm48b1f7d08bad1_action" value="http://127.0.0.1:8081/index.php/teste/mtf">
 <!-- END OF HIDDEN FIELDS --></div></div></div></div></div></div>    </div>
     
     <div id="frm__mainForm_bottom">
 
 <div class="m-container-bottom">
 <div class="m-statusbar">
 <ul >
   <li>Usuário: -</li>
   <li>Entrada às: --:--</li>
   <li>Data: --/--/----</li>
   <li>Miolo 2.5</li>
   <li>Miolo Team</li>
 </ul></div></div>    </div>
     <div id="frm__mainForm_container_minbar" class="m-container-minbar">
         <div></div>
     </div>
 </div>
 <input type="hidden" id="frm__mainForm__VIEWSTATE" name="frm__mainForm__VIEWSTATE" value="">
 <input type="hidden" id="cpaint_response_type" name="cpaint_response_type" value="">
 <input type="hidden" id="frm__mainForm__ISPOSTBACK" name="frm__mainForm__ISPOSTBACK" value="">
 <input type="hidden" id="frm__mainForm__EVENTTARGETVALUE" name="frm__mainForm__EVENTTARGETVALUE" value="">
 <input type="hidden" id="frm__mainForm__EVENTARGUMENT" name="frm__mainForm__EVENTARGUMENT" value="">
 <input type="hidden" id="frm__mainForm__FORMSUBMIT" name="frm__mainForm__FORMSUBMIT" value="frm__mainForm">
 </form>
</div>
<!-- end of form __mainForm -->
</div>
<!-- end of page48b1f7cfbebc3 -->
</body>
</html>
