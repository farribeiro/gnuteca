dojo.declare("Miolo.Window",null,
{
    id: '',
    title: '',
    href: '',
    dialog: null,
    constructor: function(id) {
        this.obj = this;
        this.id = id;
	},
    setTitle: function(title) {
        this.title = title;
    },
    setHref: function(href) {
        this.href = href;
    },
    open: function() {
//        this.dialog = new miolo.Dialog({title: this.obj.title} );
        this.dialog = new miolo.Dialog();
//        this.dialog.domNode.id = this.id;
//        this.dialog.domNode.title = 'jhjkhkjhjkh';//this.title;
//        this.dialog.setHref(this.href);
//        alert('---' + this.dialog.domNode.id);
        dojo.body().appendChild(this.dialog.domNode);
        miolo.page.getWindow(this.obj.id,this.dialog.domNode.id,this.obj.href);
    },
    close: function() {
        this.dialog.hide();
		var outer = miolo.getElementById(this.dialog.domNode.id + '_underlay_wrapper');
		dojo.body().removeChild(this.dialog.domNode);        
		dojo.body().removeChild(outer);        
    }
});