function addAjaxLoading()
{
	elementInner                    		= document.createElement('div');
	elementInner.id 					    = 'ajaxLoadingInner';
	elementInner.setAttribute('onclick',"deleteAjaxLoading();" );
	elementInner.innerHTML					= "Por favor aguarde...";

    element 								= document.createElement('div');
    element.id 								= 'ajaxLoading';

    object = document.getElementById('ajaxLoading');
    
   	//só faz no firefox estava dando erro no appendChild no IE
   	//FIXME: fazer isto funcionar no IE
    if ( !object )
    {
	    dojo.byId('__mainForm').appendChild(elementInner);
	    dojo.byId('__mainForm').appendChild(element);
    }
    

}

function deleteAjaxLoading()
{
	//console.log('deleteAjaxLoading ' + Math.random() );
    object = document.getElementById('ajaxLoading')
    inner  = document.getElementById('ajaxLoadingInner')

    while (object)
    {
        object.parentNode.removeChild(object);
        object = document.getElementById('ajaxLoading')
    }
    
    while (inner)
    {
    	inner.parentNode.removeChild(inner);
    	inner = document.getElementById('ajaxLoadingInner')
    }
}

dojo.declare("Miolo", null, {
    Version: 'Miolo2.5',
	webForm: null,
    fields: null,
    connections: [],
    constructor: function() {
	},
    isIE: document.all ? true : false,
    iFrame: {
		object: null,
		dialogs: new Array(),
		sufix: 0,
		dragElement: null,
		base: window,
		parent: null,
		getById: function(id) {
            return this.parent.miolo.iFrame.dialogs[id];
		}
	},
    windows: {
		handle: new Array(),
		sufix: 0,
		base: window
	},
    getWindow: function(windowId) {
        console.log("getWindow: " + windowId);
        return miolo.windows.handle[windowId];
	},
	addWindow: function(windowId) {
        miolo.windows.handle[windowId] = new Miolo.Window(windowId);
	},
	setWindow: function(oWindow) {
        miolo.windows.handle[oWindow.id] = oWindow;
	},
    forms: {
		handle: new Array()
	},
    getForm: function(formId) {
//        console.log("getForm: " + formId);
        return miolo.forms.handle[formId];
	},
	addForm: function(formId) {
//        console.log("addForm: " + formId);
        miolo.forms.handle[formId] = new Miolo.Form(formId);
	},
	setForm: function(formId) {
//        console.log("setForm: " + formId);
        miolo.webForm = miolo.getForm(formId);
	},
	getCurrentURL: function () {
		return this.webForm.getForm().action;
	},
    getElementById: function (e) {
        if(typeof(e)!='string') return e;
        if(document.getElementById) {e = $(e);}
        else if(document.all) {e=document.all[e];}
        else {e=null;}
        return e;
    },
    getElementsByTagName: function (tagName, p) {
        var list = null;
        tagName = tagName || '*';
        p = p || document;
        if (p.getElementsByTagName) list = p.getElementsByTagName(tagName);
        return list || new Array();
    },
	setElementValueById: function (e, value) {
        ele = this.getElementById(e);
        if (ele != null)
	    {
		    ele.value = value;
	    } 
    },
    gotoURL: function (url) {
        var prefix = 'javascript:';
        url = url.replace(/&amp;/g,"&");
        if ( url.indexOf(prefix) == 0 )
        {
            eval(url.substring(11) + ';');
        }
        else
        {
            window.location = url;
        }
    },
	window: function (url, target)
    {
        var mioloWindow = new xWindow(
            target,                // target name
            0, 0,                   // size: width, height
            0, 0,                   // position: left, top
            0,                      // location field
            1,                      // menubar
            1,                      // resizable
            1,                      // scrollbars
            0,                      // statusbar
            1);                     // toolbar
        return mioloWindow.load(url);
    },
    setTitle: function setTitle(title)
    {
        try
        {
    	    window.top.document.title = title;    	
        }
        catch (e)
        {
        }
    },
	associateObjWithEvent: function (obj, methodName){
    /* The returned inner function is intended to act as an event
       handler for a DOM element:-
    */
        return (function(e){return obj[methodName](e, this);});
    },
    isHandler: function(url) {
        return (url.indexOf('index.php') > -1);
    },
    submit: function() {
        var formSubmit =  miolo.webForm.id;
        var action = this.getElementById(this.getElementById(formSubmit+'__FORMSUBMIT').value + '_action');
        if (action)
        {
            this.webForm.setAction(action.value);
        }
        this.setElementValueById(formSubmit+'__ISPOSTBACK','yes');
	},
    afterSubmit: function() {
        this.webForm.validators = null;      
    },
    connect: function(elementId, event, handler) {
        var node = dojo.byId(elementId);
        this.connections.push(
           dojo.connect(node,event,handler)
        );
    },
    clearConnections: function() {
        dojo.forEach(this.connections, dojo.disconnect);
    },
    _doSubmit: function (eventTarget, eventArgument, formSubmit)
    {
        addAjaxLoading();
        this.setElementValueById(formSubmit+'__ISPOSTBACK', 'yes');
        this.setElementValueById(formSubmit+'__EVENTTARGETVALUE', eventTarget);
        this.setElementValueById(formSubmit+'__EVENTARGUMENT', eventArgument); 
        this.setElementValueById(formSubmit+'__FORMSUBMIT', formSubmit); 
        this.setForm(formSubmit);
        this.clearConnections();
    },
    doPostBack: function (eventTarget, eventArgument, formSubmit)
    {
        addAjaxLoading();
        this._doSubmit(eventTarget, eventArgument, formSubmit);
        if (this.webForm.onSubmit())
        {
            this.afterSubmit();
            this.page.postback();
        }
    },
    doLinkButton: function (url, eventTarget, eventArgument, formSubmit) {
        this._doSubmit(eventTarget, eventArgument, formSubmit);
        if (this.webForm.onSubmit())
        {
            this.afterSubmit();
            this.webForm.setAction(url);
            this.page.postback();
        }
    },
    doAjax: function (eventTarget, eventArgument, formSubmit)
    {
        this._doSubmit(eventTarget, eventArgument, formSubmit);
        addAjaxLoading();
        this.page.ajax();
        
    },
    doLink: function (url, formSubmit)
    {
        this.doHandler(url, formSubmit);
        this.setForm(formSubmit);
        this.webForm.setAction(url);
    },
    doHandler: function (url, element)
    {
        addAjaxLoading();
        this.page.handler(url, element);
    },
    doRedirect: function (url, element)
    {
        addAjaxLoading();
        if (this.isHandler(url)) {
            this.doHandler(url, element);
        }
        else {
            window.location = url;
        }        
    },
	doDisableButton: function (buttonId) {
        this.getElementById(buttonId).disabled = true;
    },
    doPrintForm: function (url) {
        var w = screen.width * 0.75;
        var h = screen.height * 0.60;
        var print = window.open(url,'print',
        'toolbar=no,width='+w+',height='+h+',scrollbars=yes,' +
        'top=0,left=0,statusbar=yes,resizeable=yes');
    },
	doPrintFile: function (eventTarget, eventArgument, formSubmit) {
        var ok = confirm("Aguarde a geraï¿½ï¿½o do relatï¿½rio.\nO resultado serï¿½ exibido em uma nova janela.");
        if (ok)
        {
            var tg = window.name;
            var form = document.forms[0];
            var w = screen.width * 0.95;
            var h = screen.height * 0.80;
            var print = window.open('','print', 
            'toolbar=no,width='+w+',height='+h+',scrollbars=yes,' +
            'top=0,left=0,statusbar=yes,resizeable=yes');
            form.target='print'; 
            this.doPostBack(eventTarget, eventArgument, formSubmit); 
            print.focus();
            form.target=tg;
        }
    },
    doShowPDF: function (eventTarget, eventArgument, formSubmit) {
        var ok = confirm("Aguarde a geraï¿½ï¿½o do arquivo PDF.\nO resultado serï¿½ exibido em uma nova janela.");
        if (ok)
        {
            this.doPostBack(eventTarget, eventArgument, formSubmit); 
        }
    },
    doWindow: function (url, element) {
            var tg = window.name;
            //var form = document.forms[0];
            var w = screen.width * 0.95;
            var h = screen.height * 0.80;
            var print = window.open(url,'print', 
            'toolbar=no,width='+w+',height='+h+',scrollbars=yes,' +
            'top=0,left=0,statusbar=yes,resizeable=yes');
            //form.target='print'; 
            //miolo.doPostBack(eventTarget, eventArgument, formSubmit);
            print.focus();
            //form.target=tg;
    },
    doPrintURL: function (url) {
        var ok = confirm('Clique Ok para imprimir.');
        if (ok)
        {
            var tg = window.name;
            var form = document.forms[0];
            var w = screen.width * 0.95;
            var h = screen.height * 0.80;
            var print = window.open(url,'print', 
            'toolbar=no,width='+w+',height='+h+',scrollbars=yes,' +
            'top=0,left=0,statusbar=yes,resizeable=yes');
            print.focus();
            window.print();
            form.target=tg;
        }
    },
	showLoading: function() {
        try
        {
            this.getElementById("m-loading-message-bg").style.display = "block";
            this.getElementById("m-loading-message").style.display    = "block";
        }
        catch(err)
        {}
		return true;
    },
    stopShowLoading: function()
    {
        try
        {
            this.getElementById("m-loading-message-bg").style.display = "none";
            this.getElementById("m-loading-message").style.display    = "none";
        }
        catch(err)
        {}
		return true;
    },
	getMousePosition: function( e ) {
        is_ie = ( /msie/i.test(navigator.userAgent) && !/opera/i.test(navigator.userAgent) );
        var posX;
        var posY;
        if ( is_ie )
        {
            posY = window.event.clientY + document.body.scrollTop;
            posX = window.event.clientX + document.body.scrollLeft;
        } else {
            posY = e.clientY + window.scrollY;
            posX = e.clientX + window.scrollX;
        }
        return new Array( posX, posY);
    },
    urlencode: function(s) {
        return encodeURIComponent(s).replace(/\%20/g, '+').replace(/!/g, '%21').replace(/'/g, '%27').replace(/\(/g, '%28').replace(/\)/g, '%29').replace(/\*/g, '%2A').replace(/\~/g, '%7E');
    },

    urldecode: function(s) {
        return decodeURIComponent(s.replace(/\+/g, '%20').replace(/\%21/g, '!').replace(/\%27/g, "'").replace(/\%28/g, '(').replace(/\%29/g, ')').replace(/\%2A/g, '*').replace(/\%7E/g, '~'));
    }
});

var miolo = new Miolo;

if (window.parent && window.parent.miolo)
{
    miolo.windows.base = window.parent.miolo.windows.base;
}
