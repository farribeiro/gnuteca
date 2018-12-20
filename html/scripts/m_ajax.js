
dojo.declare("Miolo.Ajax",null,
{
	loading: "<img src=\"images/loading.gif\" border=\"0\" alt=\"\">",
	url: null,
    form: null,
    response_type: 'JSON',
    updateElement: null,
    parameters: null,
    content: null,
    remote_method: '',
    constructor: function(obj) {
		if (obj.url) this.url = obj.url;
		if (obj.form) this.form = obj.form;
		if (obj.content) this.content = obj.content;
		if (obj.response_type) this.response_type = obj.response_type;
		if (obj.updateElement) this.updateElement = obj.updateElement;
        if (obj.parameters) this.parameters = obj.parameters;
        if (obj.remote_method) this.remote_method = obj.remote_method;
		if (obj.callback_function) this.callback_function = obj.callback_function;
	},
	update: function (result, ioArgs) {
        miolo.getElementById(this.updateElement).innerHTML = result;
	},
    error: function(error,ioArgs) {
        if (errDiv = miolo.getElementById('stdout'))
        {
            errDiv.innerHTML = ioArgs.xhr.responseText;
        }
    },
	call: function() {
        var response_type = this.response_type.toLowerCase();
        if (miolo.getElementById('__ISAJAXCALL'))
        {
            miolo.setElementValueById('__ISAJAXCALL', 'yes');
        }
        if (miolo.getElementById('cpaint_response_type'))
        {
            miolo.setElementValueById('cpaint_response_type', response_type);
        }
		if (this.updateElement) {
           this.update(this.loading);
		}
		var callback_function = this.callback_function ? this.callback_function : this.update;
        if (this.form != null) {
            this.content.cpaint_response_type = response_type;
                dojo.xhrPost({
                    form: this.form,
                    content: this.content,
                    error: this.error,
                    handleAs: "json",
                    handle: callback_function
                });
        }
        else {
            var goUrl = this.url ? this.url : miolo.getCurrentURL();
            var parameters = (this.parameters != null) ? this.parameters : {};
            parameters.__ISAJAXCALL = 'yes';
            parameters.__EVENTTARGETVALUE = this.remote_method;
            parameters.cpaint_response_type = response_type;
            dojo.xhrPost({
                updateElement: this.updateElement,
                url: goUrl,
                content: parameters,
                error: this.error,
                handleAs: response_type,
                handle: callback_function
            });
        }
	}
});