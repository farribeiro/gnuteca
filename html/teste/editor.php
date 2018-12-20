<?php
?>
<html>
<head>
<title>Dojo example</title>
<style type="text/css">
  @import "http://127.0.0.1:8090/scripts/dojoroot/dijit/themes/nihilo/nihilo.css";
</style>

<script type="text/javascript" src="http://127.0.0.1:8090/scripts/dojoroot/dojo/dojo.js" djConfig="parseOnLoad:true, isDebug: true"></script>
<script type="text/javascript">
  dojo.require("dijit.Editor");
  dojo.require("dijit._editor.plugins.AlwaysShowToolbar");
</script>
<body class="nihilo">
<div dojoType="dijit.Editor" id="editor5" style="{width:500px}"
   extraPlugins="['dijit._editor.plugins.AlwaysShowToolbar']">
                <p>
                        This editor is created from a div with AlwaysShowToolbar plugin (do not forget to set height="").
                </p>
</div>
</body>
</html>