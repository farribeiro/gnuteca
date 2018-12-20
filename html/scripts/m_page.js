dojo.declare("Miolo.Page", null, {
    version: '0.1',
    scripts: new Hash(),
    jsloaded: new Hash(),
    controls: new Hash(),
    tokenId: '',
    constructor: function() {
        this.obj = this; 
    },
    handler: function(gotourl, element) {
        var ajaxHandler = new Miolo.Ajax({
            url: gotourl,
            response_type: 'JSON',
            parameters: {__FORMSUBMIT: element, __ISAJAXCALL: 'yes', __MIOLOTOKENID: miolo.page.tokenId},
            callback_function: function(result,ioArgs) {
                miolo.page.evalresult(result);
            }
        });
        ajaxHandler.call();
    },
    ajax: function() {
        this.setValidators(false);
        if (miolo.webForm.onSubmit())
        {
            this.setValidators(true);
            var ajaxSubmit = new Miolo.Ajax({
                form: miolo.webForm.id,
                content: {__FORMSUBMIT: miolo.webForm.id, __ISAJAXCALL: 'yes', __ISAJAXEVENT: 'yes', __MIOLOTOKENID: miolo.page.tokenId},
                response_type: 'JSON',
                callback_function: function(result,ioArgs) {
                    miolo.page.evalresult(result);
                }
            });
            ajaxSubmit.call();
        }
    },
    postback: function() {
        var ajaxPostBack = new Miolo.Ajax({
            form: miolo.webForm.id,
            content: {__FORMSUBMIT: miolo.webForm.id, __ISAJAXCALL: 'yes', __MIOLOTOKENID: miolo.page.tokenId},
            response_type: 'JSON',
            callback_function: function(result,ioArgs) {
                miolo.page.evalresult(result);
            }
        });
        ajaxPostBack.call();
    },
    getWindow: function(winid, domid, winurl) {
        var ajaxWindow = new Miolo.Ajax({
            url: winurl,
            response_type: 'JSON',
            parameters: {__WINID: winid,__DOMWINID: domid,__FORMSUBMIT: '__mainForm', __ISAJAXCALL: 'yes', __MIOLOTOKENID: miolo.page.tokenId},
            callback_function: function(result,ioArgs) {
                var domid = ioArgs.args.content.__DOMWINID;
                var response = result.data;
                if (response.scripts[0] != '')
                {
                    miolo.page.includejs(response.scripts[0]);
                }
                miolo.page.evaljs(response.scripts[1]);
                miolo.page.evalelement(response);
                dijit.byId(domid).show();
                miolo.page.evaljs(response.scripts[2]);
            }
        });
        ajaxWindow.call();
    },
    setValidators: function(status) {
        if (miolo.webForm.validators) {
            miolo.webForm.validators.on = status;
        }
    },
    clearelement: function(element) {
        if (element)
        {
            if ( element.hasChildNodes() )
            {
                while ( element.childNodes.length >= 1 )
                {
                    element.removeChild( element.firstChild );       
                } 
            }   
        }
    },
    includejs: function(tag) {
        var md5 = new Miolo.md5();
        var regexp = /src=\"(.*)\"/mg;
        while (f = regexp.exec(tag))
        {
            var name = md5.MD5(f[1]);
            if (!this.scripts.get(name)) // not loaded yet
            {
                dojo.xhrGet({
                    url: f[1],
                    handleAs: "javascript",
                    sync: true
                });
                this.scripts.set(name,f[1]);
            }
        }
    },
    evalresult: function(result) {
        if (result)
        {
            var response = result.data;
            miolo.page.evalresponse(response);
        }
        else
        {
            miolo.page.tokenId = '';
        }
    },
    evalelement: function(response) {
        if (response.html)
        {
            for(i = 0; i < response.html.length; i++)
            {
                var element = miolo.getElementById(response.element[i]);
                if (element)
                {
                    this.clearelement(element);
                    element.innerHTML = response.html[i];
                }
            }
        }
    },
    evalresponse: function(response) {
        var errorMsg = response.scripts[3];
        if (errorMsg != '')
        {
//            alert(errorMsg);
            miolo.page.tokenId = '';
        }
        else 
        {
            if (response.scripts[0] != '')
            {
//                console.log(response.scripts[0]);
                miolo.page.includejs(response.scripts[0]);
            }
            this.evaljs(response.scripts[1]);
            this.evalelement(response);
            this.evaljs(response.scripts[2]);
        }
    },
    evaljs: function(script) {
        if (script != '')
        {
//console.log(script);
            dojo.eval(script);
        }
    }
});


miolo.page = new Miolo.Page;
