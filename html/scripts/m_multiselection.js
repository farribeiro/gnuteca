dojo.declare("Miolo.MultiSelection",[Miolo.MultiTextField2],
{
    add: function (n) {
       var list = miolo.getElementById(this.mtfName + this.emptyField);
       var selection = miolo.getElementById(this.mtfName + '_options' + n);
       var n = list.length;
       var i = 0;
       var achou = false;
       var atext = selection.options[selection.selectedIndex].text;
       for (i = 0; i < n; i++) {
          if (list.options[i].text == atext)
             achou = true;
       }
       if (achou) {
          alert('Item já está na lista!');
       }
       else {
          list.options[n] = new Option(atext);
          list.selectedIndex = n;
       }
    }
});
