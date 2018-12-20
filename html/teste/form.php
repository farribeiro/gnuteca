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
<script type="text/javascript"> dojo.require("dojo.parser")</script>
<script type="text/javascript">
function mypost(formid)
{
alert(formid);
alert(dojo.byId(formid).name);
            dojo.xhrPost({
                form: formid,
                handleAs: "text",
                handle: function(response) { alert(response);}
            });
}
</script>

</HEAD>

<BODY>
<FORM name="form1" id="form1" METHOD=POST ACTION="form.php">
    <INPUT name="i1" id="i1" TYPE="text"  value="a">
    <button type="button" name="b1" value="b1" onclick="javascript:mypost('form1');">b1</button>
    <FORM name="form11" id="form11" METHOD=POST ACTION="form.php">
        <INPUT name="i11" id="i11" TYPE="text"  value="b">
        <button type="button" name="b11" value="b11"  onclick="javascript:mypost('form11');">b11</button>
        <FORM name="form111" id="form111" METHOD=POST ACTION="form.php">
            <INPUT name="i111" id="i111" TYPE="text"  value="c">
            <button type="button" name="b111" value="b111"  onclick="javascript:mypost('form111');">b11</button>
        </FORM>
    </FORM>
    <FORM name="form2" id="form2" METHOD=POST ACTION="form.php">
        <INPUT name="i2" id="i2" TYPE="text"  value="d">
        <button type="button" name="b2" value="b2"  onclick="javascript:mypost('form2');">b2</button>
    </FORM>

</FORM>
</BODY>
</HTML>
