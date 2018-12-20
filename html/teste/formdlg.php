<?php
print_r($_REQUEST);
?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD>
<TITLE> New Document </TITLE>
<META NAME="Generator" CONTENT="EditPlus">
<META NAME="Author" CONTENT="">
<META NAME="Keywords" CONTENT="">
<META NAME="Description" CONTENT="">
<script type="text/javascript"> djConfig={isDebug:true, usePlainJson:true,  parseOnLoad:true}</script>
<script type="text/javascript" src="http://127.0.0.1:8081/scripts/dojoroot/dojo/dojo.js"></script>
<script type="text/javascript" src="http://127.0.0.1:8081/scripts/prototype/prototype.js"></script>

<script type="text/javascript" src="http://127.0.0.1:8081/scripts/m_miolo.js"></script>
<script type="text/javascript" src="http://127.0.0.1:8081/scripts/m_page.js"></script>
<script type="text/javascript" src="http://127.0.0.1:8081/scripts/m_ajax.js"></script>
<script type="text/javascript" src="http://127.0.0.1:8081/scripts/m_encoding.js"></script>
<script type="text/javascript" src="http://127.0.0.1:8081/scripts/m_form.js"></script>
<script type="text/javascript" src="http://127.0.0.1:8081/scripts/m_compatibility.js"></script>
<script type="text/javascript" src="http://127.0.0.1:8081/scripts/m_md5.js"></script>
<script type="text/javascript"> dojo.require("dojo.parser")</script>
<script type="text/javascript"> dojo.require("miolo.Dialog")</script>
<script type="text/javascript">

window.onload = function () {
    miolo.setForm('form1');
}

function mypost(formid)
{
miolo.setForm(formid);
alert(formid);
//var form = new Miolo.form(formid);
//var inputs = form.getInputs();
//console.log(inputs);
            dojo.xhrPost({
                form: miolo.webForm.id,
//                content: inputs,
                handleAs: "text",
                preventCache:true,
                handle: function(response) { alert(response);}
            });
}
      function showDialog2() {
    	miolo.page.getWindow('dialog2','http://127.0.0.1:8081/index.php?module=teste&action=ajax2')
      }

</script>

</HEAD>

<BODY>
<FORM name="form1" id="form1" METHOD=POST ACTION="form.php">
    <INPUT name="i1" id="i1" TYPE="text"  value="a">
    <INPUT name="i2" id="i2" TYPE="text"  value="b">
    <button type="button" name="b1" value="b1" onclick="javascript:mypost('form1');">b1</button>
    <button type="button" name="b2" value="b2" onclick="javascript:showDialog2();">open dialog</button>

</FORM>
    <div dojoType="miolo.Dialog" id="dialog2" title="Title of Dialog2"></div>
</BODY>
</HTML>
