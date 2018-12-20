dojo.declare("Miolo.Form", null, {
    id: null,
    onLoad: null,
    onSubmit: null,
    validators: null,
    constructor: function(id) {
		this.id = id; 
	},
    setFocus: function (fieldName) {
		if (fieldName == '') {
			var element = null;
			var f = miolo.getElementById(this.id);
    	    var children = f.getElementsByTagName('input');
			if (children.length == 0) {
        	    var children = f.getElementsByTagName('select');
    			if (children.length > 0) {
					element = children[0];
				}
			} else {
				element = children[0];
			}
		} else {
			var element = miolo.getElementById(fieldName);
		}
        if (element != null) {
           element.focus();
        }
    },
	getInputs: function() {
      var getstr = new Object();
	  var f = miolo.getElementById(this.id);
      var inputs = f.getElementsByTagName('input');
      for (var i = 0, length = inputs.length; i < length; i++) {
	      var input = inputs[i];
		  if ((input.type == "text") || (input.type == "hidden")) {
			  if (getstr[input.name])
			  {
	  			  getstr[input.name] += "&" + input.value;
			  } else {
    			  getstr[input.name] = input.value;
			  }
		  }
		  if (input.type ==	"checkbox") {
			  if (input.checked) {
				  getstr[input.name] = (input.value == '' ? 'on' : input.value);
			  }
		  } 
		  if (input.type ==	"radio") {
			  if (input.checked) {
				  getstr[input.name] = input.value;
			  }
		  } 
      }
      var inputs = f.getElementsByTagName('select');
      for (var i = 0, length = inputs.length; i < length; i++) {
	      var input = inputs[i];
		  getstr[input.name] = input.options[input.selectedIndex].value;
	  }
	  return getstr;
	},
    getForm: function() {
        return miolo.getElementById(this.id);               
    },
    setAction: function(url) {
        miolo.getElementById(this.id).action = url;               
    },
    getAction: function() {
        return miolo.getElementById(this.id).action;
    }

});

//miolo.addForm("__mainForm");
