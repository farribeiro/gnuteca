
Miolo.prototype.comboBox = {
	onTextChange : function (label,textField,selectionList)
    {
    var tf = miolo.getElementById(textField);
	var sl = miolo.getElementById(selectionList);
    var text = tf.value;

    for ( var i=0; i < sl.options.length; i++ )
    {
        if ( sl.options[i].value == text )
        {
            sl.selectedIndex = i;
            return;
        }
    }

    //\u00e3 = ã
    //\u00e7 = ç

    label = label.length ? " '"+label+"'!" : '!';
    text = "!!! Aten\u00e7\u00e3o !!!\n\nN\u00e3o existe uma op\u00e7\u00e3o correspondente ao valor '" + text + "'\ndo campo" + label + "";
    alert(text);
    tf.value = '';
    tf.focus();
    },

onSelectionChange : function (label,selectionList,textField)
    {
     var tf = miolo.getElementById(textField);
     var sl = miolo.getElementById(selectionList);
     var index = sl.selectedIndex;
     if ( index != -1 )
     {
         tf.value = String(sl.options[index].value);
     }
     }
}
