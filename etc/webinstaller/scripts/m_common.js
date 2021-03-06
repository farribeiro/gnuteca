// +-----------------------------------------------------------------+
// | MIOLO - Miolo Development Team - UNIVATES Centro Universit�rio  |
// +-----------------------------------------------------------------+
// | CopyLeft (L) 2001,2002  UNIVATES, Lajeado/RS - Brasil           |
// +-----------------------------------------------------------------+
// | Licensed under GPL: see COPYING.TXT or FSF at www.fsf.org for   |
// |                     further details                             |
// |                                                                 |
// | Site: http://miolo.codigolivre.org.br                           |
// | E-mail: vgartner@univates.br                                    |
// |         ts@interact2000.com.br                                  |
// +-----------------------------------------------------------------+
// | Abstract: This file contains the javascript functions           |
// |                                                                 |
// | Created: 2001/08/14 Vilson Cristiano G�rtner [vg]               |
// |                     Thomas Spriestersbach    [ts]               |
// |                     Nasair J�nior da Silva   [nasair]           |
// |                                                                 |
// | History: Initial Revision                                       |
// |          2001/12/14 [ts] Added MultiTextField support functions |
// |          2006/04/03 [nasair] Added Print and FrameUtil functions|
// +-----------------------------------------------------------------+
var frameUtil;

var MIOLO_boxMoving = false;
//control move box (drag)
var MIOLO_boxToMove = null;
//control how box will be moving
var MIOLO_boxPositions = new Array(2);
//the box initial positions
var MIOLO_isIE = document.all ? true : false;
//if the browser is IE

function createRequestObject() 
{
    var ro;
    var browser = navigator.appName;

    if(browser == "Microsoft Internet Explorer")
    {
        ro = new ActiveXObject("Microsoft.XMLHTTP");
    }
    else
    {
        ro = new XMLHttpRequest();
    }
    return ro;
}

var http = createRequestObject();

if ( MIOLO_isIE )
{
    //document.insertBefore(document.lastChild,frameUtil);
    //for (var i in document) document.write('<br />'+i);

    document.write('<iframe style="visibility:hidden" id="frameUtil" name="frameUtil" src="" width=0 height=0>&nbsp;</iframe>');
    frameUtil = document.getElementById('frameUtil');
}
else
{
    frameUtil = document.createElement('iframe');
    frameUtil.id = 'frameUtil';
    frameUtil.name = 'frameUtil';
    frameUtil.style.width   = '0px';
    frameUtil.style.height  = '0px';
    frameUtil.style.border  = 'none';

    document.lastChild.appendChild(frameUtil);
}

function MIOLO_getWindow( opener )
{
    if ( opener && window.opener )
    {
        return window.opener;
    }
    if ( top.frames['content'] )
        return top.frames['content'];
    return top;
}

function MIOLO_getDocument( opener )
{
    return MIOLO_getWindow( opener ).document;
}

function setUtilLocation(url)
{
    if(frameUtil.tagName == 'IFRAME')
    {
        frameUtil.src = url;
    }
    else
    {
        frameUtil.location = url;
    }
}

function setUtilContent( content, print )
{
    var win = frameUtil.contentWindow ? frameUtil.contentWindow : frameUtil;

    var v = '<html><head>';
    for( i=0; i< document.styleSheets.length; i++ )
    {
        v += '\n<link rel="stylesheet" href="' + document.styleSheets[i].href + '" type="' + document.styleSheets[i].type + '" />';
    }
    v += '</head><body>';

    if( print )
    {
        content += '<script language="javascript"> window.print( )</script>';
    }

    win.document.open( );
    win.document.write( v + content + '</body></html>');
    win.document.close( );
}

function printUtilContent( )
{
    var win = frameUtil.contentWindow ? frameUtil.contentWindow : frameUtil;
    win.print( );
}

function TrimString(sInString) {
  sInString = sInString.replace( /^\s+/g, "" );// strip leading
  return sInString.replace( /\s+$/g, "" );// strip trailing
}

/**
 * COMBOBOX
 */
function ComboBox_onTextChange(label,textField,selectionList)
{
    var text = textField.value;
    
    for ( var i=0; i<selectionList.options.length; i++ )
    {
        if ( selectionList.options[i].value == text )
        {
            selectionList.selectedIndex = i;
            return;
        }
    }
    
    alert("!!! ATEN��O !!!\n\nN�o existe uma op��o correspondente ao valor '" + 
          text + "'\ndo campo '" + label + "'!");
    
    textField.focus();
}
 
function ComboBox_onSelectionChange(label,selectionList,textField)
{
     var index = selectionList.selectedIndex;
     if ( index != -1 )
     {
         textField.value = String(selectionList.options[index].value);
     }
} 

/**
 *  GOTOURL
 */
function GotoURL(url)
{
    var prefix = 'javascript:';
    
//    alert(escape(url));
    
    if ( url.indexOf(prefix) == 0 )
    {
        eval(url.substring(11) + ';');
    }
    
    else
    {
        window.location = url;
    }
}

function M_getFormValues(fobj)
{
    var str = "";
    var valueArr = null;
    var val = "";
    var cmd = "";

    for(var i = 0;i < fobj.elements.length;i++)
    {
        switch(fobj.elements[i].type)
        {
            case "text":
                str += fobj.elements[i].name +
                       "=" + escape(fobj.elements[i].value) + "&";
                    break;

            case "select-one":
                str += fobj.elements[i].name +
                       "=" + fobj.elements[i].options[fobj.elements[i].selectedIndex].value + "&";
                break;
        }
    }

    str = str.substr(0,(str.length - 1));
    return str;
}


function sendContentRequest(action, method, params)
{
    showLoading();
    http.open(method, action);
    http.onreadystatechange = handleContentResponse;
    http.onreadystatechange = checkResponse;
    http.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    http.send(params);

    return http.responseText;
}

function handleContentResponse()
{

    if( http.readyState == 4 )
    {
        stopShowLoading();

        var response = http.responseText;

        var element;

        //element = document.getElementById("m-container-content");

        element = document.getElementById("m-container-content-full");

        if ( element != null )
        {
            element.innerHTML = response;
        }
        else
        {
            alert("Element m-container-content-full not found!");
        }
    }
}

// wrapper functions for CPaint
var callBackFunction;

function  MIOLO_ajaxCall(url, request_method, target_function, target_parameter, response_callback, format)
{
    showLoading();
    callBackFunction = response_callback;

    //cpaint_call("{$url}", "POST", "ajax_btnSel", xGetElementById("sel").value, updateSel2, "TEXT");
    cpaint_call(url, request_method, target_function, target_parameter, MIOLO_ajaxCallResponse, format);
}

function MIOLO_ajaxCallResponse(response)
{
    callBackFunction(response);
    stopShowLoading();
}

/**
 * LINKBUTTON
 */
function _MIOLO_LinkButton(frmName, url, event, param, target)
{

    var form = document.forms[0];

    if ( enable_ajax == true )
    {
        // http://www.devarticles.com/c/a/XML/XML-in-the-Browser-Submitting-forms-using-AJAX/5/
        //alert(M_getFormValues(form));
        sendContentRequest(url+'&renderMethod=ajax', 'get', null);
        //sendContentRequest(url, 'get', null);

        //sendContentRequest('ajax.php', 'get', M_getFormValues(form));
    }
    else
    {
        if ( form != null )
        {
        if ( eval('miolo_onSubmit()') )
        {
            var old = form.action;
            form.action = url;
            window._doPostBack(event, param, target);
            form.submit();
            form.action = old;
            showLoading();
        }
        }
        else
        {
            alert('MIOLO INTERNAL ERROR: LinkButton\n\nForm ' + frmName + ' not found!');
        }
    }
}

/**
 * PRINT
 */

function MIOLO_Print()
{
	var w = screen.width * 0.75;
	var h = screen.height * 0.60;
    var print = window.open('print.php','print',
                'toolbar=no,width='+w+',height='+h+',scrollbars=yes,' +
                'top=0,left=0,statusbar=yes,resizeable=yes');
}

/**
 * POPUP
 */
function MIOLO_Popup(url,w,h)
{
    var popup = window.open(url,'popup',
                'toolbar=no,width='+w+',height='+h+',scrollbars=yes,' +
                'top=0,left=0,statusbar=no,resizeable=yes');
}

/**
 * Window
 */
function MIOLO_Window(url, target)
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
}

function MIOLO_GetElementById(e) 
{
  if(typeof(e)!='string') return e;
  if(document.getElementById) e=document.getElementById(e);
  else if(document.all) e=document.all[e];
  else e=null;
  return e;
}

function MIOLO_SetTitle(title)
{
	top.document.title = title;
}

/**
 * PAGE FUNCTIONS
 */

function showLoading()
{
    document.getElementById("m-loading-message-bg").style.display = "block";
    document.getElementById("m-loading-message").style.display    = "block";
}

function stopShowLoading()
{
    document.getElementById("m-loading-message-bg").style.display = "none";
    document.getElementById("m-loading-message").style.display    = "none";
}

/**
 * MIOLO Form Event Handler\n";
 */
function _doPostBack(EventTarget, EventArgument, formTarget)
{
    var form = document.forms[0];

    if ( enable_ajax == true )
    {
        var vars = M_getFormValues(form);
        
        vars = vars + '&renderMethod=ajax'+
                      '&__EVENTTARGETVALUE='+EventTarget+
                      '&__EVENTARGUMENT='+EventArgument

        sendContentRequest(form.action, 'post', vars);
        
        return false;
    }
    else
    {
        form['__ISPOSTBACK'].value = 'yes';
        form['__EVENTTARGETVALUE'].value = EventTarget;
        form['__EVENTARGUMENT'].value = EventArgument; 
    
        if ( typeof( formTarget ) == 'undefined' )
        {
            formTarget = '_self';
        }
        form.target = formTarget;
        
        return true;
    }
}

function _doPrintForm(url)
{
		var w = screen.width * 0.75;
		var h = screen.height * 0.60;
		var print = window.open(url,'print',
		                   'toolbar=no,width='+w+',height='+h+',scrollbars=yes,' +
		                   'top=0,left=0,statusbar=yes,resizeable=yes');
}

function _doPrintFile()
{
       var ok = confirm('Aguarde a gera��o do relat�rio.\\nO resultado ser� exibido em uma nova janela.');
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
		        form.submit(); 
		        print.focus();
 		        form.target=tg;
       }
}

function _doShowPDF()
{
       var ok = confirm("Aguarde a gera��o do arquivo PDF.\nO resultado ser� exibido em uma nova janela.");
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
		        form.submit(); 
		        print.focus();
 		        form.target=tg;
       }
}

function _doPrintURL(url)
{
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
}

function _doPrintObject( id )
{
    obj = MIOLO_GetElementById( id );

    if ( typeof(obj) != 'undefined' )
    {
        var v = '<' + obj.tagName + ' class="' + obj.className + '" id="' + obj.id + '">';
        v += obj.innerHTML;
        v += '</' + obj.tagName + '>';
        setUtilContent( v, true );
    }
}

function MIOLO_getMousePosition( e )
{
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
}

function MIOLO_showBox( box )
{
    if( MIOLO_isIE )
    {
        box = event.srcElement;
    }

    var id = box.id.substring( 4 );

    var aux = document.getElementById(id);
    aux.style.display = '';
    box.style.display = 'none';
    document.onmousemove = null;
}

function MIOLO_closeBox( e, box )
{
    document.onmousemove = null;
    var div  = document.getElementById('min_' + box.id);

    if ( div == null )
    {
        var cont = document.getElementById('m-container-bottom');
        if ( ! cont )
        {
            return false;
        }
        div  = document.createElement('span');

        div.id   = 'min_' + box.id;
        if ( MIOLO_isIE )
        {
            div.setAttribute("onclick", MIOLO_showBox);
        }
        else
        {
            div.setAttribute("onclick", "MIOLO_showBox(this)");
        }

        var text;
        var aux = MIOLO_isIE ? 1 : 0;
        if ( box.childNodes[1-aux].childNodes[3-aux].className == 'caption' )
        {
            text = box.childNodes[1-aux].childNodes[3-aux].childNodes[0].nodeValue;
        }
        else
        {
            text = box.childNodes[1-aux].childNodes[1-aux].innerHTML;
        }
        div.innerHTML = text;
        div.className = 'm-box-title';

        cont.appendChild(div);
        box.style.display = 'none';
        cont.style.textAlign = 'left';
    }
    else
    {
        div.style.display = div.style.display == 'none' ? '' : 'none';
        box.style.display = 'none';
    }
}

function MIOLO_hideBoxContent( box )
{
    //hide all box contents
    for ( var i= MIOLO_isIE ? 1 : 2; i< box.childNodes.length; i++ )
    {
        style = box.childNodes[i].style
        
        if( typeof(style) != 'undefined') style.display = style.display == 'none' ? '' : 'none';
    }

}

function MIOLO_moveBox( e, box, move )
{
    if( box.style.display == 'none' )
        return false;
    var type = MIOLO_isIE ? event.button : e.which;

    if ( type != 1 ) //case the mouse button is not the left
    {
        return MIOLO_closeBox( e, box );
    }

    //control the box click and drag
    document.onmousemove = move ? MIOLO_boxPosition : null;
        
    MIOLO_boxToMove = box;
    MIOLO_boxToMove.style.position = 'relative';

    if( move )  //if click, control the initial positions
    {
        var diffLeft = MIOLO_boxToMove.style.left ? parseInt(MIOLO_boxToMove.style.left) : 0;
        var diffTop  = MIOLO_boxToMove.style.top  ? parseInt(MIOLO_boxToMove.style.top ) : 0;

        if ( MIOLO_isIE )
        {
            MIOLO_boxPositions[0] = event.clientX - diffLeft;
            MIOLO_boxPositions[1] = event.clientY - diffTop;
        }
        else
        {
            MIOLO_boxPositions[0] = e.pageX - diffLeft;
            MIOLO_boxPositions[1] = e.pageY - diffTop;
        }
    }
    MIOLO_boxMoving = move; //control if is to move the box

    if ( ! move )
    {
        MIOLO_boxToMove.style.position = 'absolute';
        document.cookie = MIOLO_boxToMove.id + '_position=' + MIOLO_boxToMove.style.left + ',' +
                          MIOLO_boxToMove.style.top         + ',' + MIOLO_boxToMove.tagName + ',' +
                          MIOLO_boxToMove.className;
        MIOLO_boxToMove.style.position = 'relative';
    }
    return ! move; //if move = false, disable text selection else enable
}

function MIOLO_boxPosition( event )
{
    var posX; //control the top left
    var posY; //control the top position
    
    if ( MIOLO_isIE ) 
    {
        posX = window.event.clientX;
        posY = window.event.clientY;
    } 
    else 
    {
        posX = typeof(event.pageX) == 'undefined' ? 0 : event.pageX;
        posY = typeof(event.pageY) == 'undefined' ? 0 : event.pageY;
    }
    
    var st = MIOLO_boxToMove.style; //the box style
    st.left = (posX - MIOLO_boxPositions[0] ) + "px"; //set the left position
    st.top  = (posY - MIOLO_boxPositions[1] ) + "px"; //set the top  position
}

function MIOLO_SetBoxPositions( )
{
    var cookies = document.cookie.split(';');

    for( var i in cookies )
    {
        var pos = cookies[i].indexOf('_position');
        if( pos > 0 )
        {
            var id  = cookies[i].substr( 1, pos-1);
            var box = MIOLO_GetElementById( id );
            var aux = cookies[i].split('=')[1].split(',');

            if( box != null && box.tagName == aux[2] && box.className == aux[3] )
            {
                box.style.position = 'absolute';
                box.style.left     = aux[0];
                box.style.top      = aux[1];
                box.style.position = 'relative';
            }
        }
    }
}

function MIOLO_Close( )
{
    if ( MIOLO_getDocument( ).getElementById('lookupIframe') )
    {
        MIOLO_getDocument( ).getElementById('lookupIframe').style.display = 'none';
    }
    else
    {
        window.close();
    }

}
