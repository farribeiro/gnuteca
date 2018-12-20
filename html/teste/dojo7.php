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
<script type="text/javascript" src="http://miolo.ufjf.br:8500/scripts/dojoroot/dojo/dojo.js"></script>
<script type="text/javascript" src="http://miolo.ufjf.br:8500/scripts/prototype/prototype.js"></script>

<script type="text/javascript" src="http://miolo.ufjf.br:8500/scripts/m_miolo.js"></script>
<script type="text/javascript" src="http://miolo.ufjf.br:8500/scripts/m_page.js"></script>
<script type="text/javascript" src="http://miolo.ufjf.br:8500/scripts/m_ajax.js"></script>
<script type="text/javascript" src="http://miolo.ufjf.br:8500/scripts/m_encoding.js"></script>
<script type="text/javascript" src="http://miolo.ufjf.br:8500/scripts/m_form.js"></script>
<script type="text/javascript" src="http://miolo.ufjf.br:8500/scripts/m_compatibility.js"></script>
<script type="text/javascript" src="http://miolo.ufjf.br:8500/scripts/m_md5.js"></script>
<script type="text/javascript"> dojo.require("dojo.parser")</script>
<script type="text/javascript">

function myexecute()
{
    alert('Execute!');
}

function mycancel()
{
    alert('Cencel!');
}

function open()
{
    dijit.popup.prepare('popupdiv');
    dijit.popup.open({onExecute: myexecute, onCancel: mycancel});
}

</script>

</HEAD>

<BODY>
<FORM name="form1" id="form1" METHOD=POST ACTION="form.php">
    <INPUT name="i1" id="i1" TYPE="text"  value="a">
    <INPUT name="i2" id="i2" TYPE="text"  value="b">
    <button type="button" name="b1" value="b1" onclick="javascript:open();">open</button>
    <button type="button" name="b2" value="b2" onclick="javascript:dijit.popup.close();">close</button>

</FORM>
    <div id="popupdiv">
<span>A simple text</span>
</div>
</BODY>
</HTML>
